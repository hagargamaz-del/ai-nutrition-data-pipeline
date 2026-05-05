import json
import os
from pathlib import Path
from typing import Dict, Any
from api.services.gemini_llm_service import analyze_meal_image_with_gemini
from api.database import get_connection
from api.services.mock_llm_service import analyze_meal_image_mock
def save_uploaded_image(file_bytes: bytes, filename: str) -> str:
    images_dir = Path("data/images")
    images_dir.mkdir(parents=True, exist_ok=True)

    safe_filename = filename.replace(" ", "_")
    image_path = images_dir / safe_filename

    with open(image_path, "wb") as f:
        f.write(file_bytes)

    return str(image_path)

def insert_llm_prediction_to_staging(
    user_id: int,
    image_path: str,
    llm_result: Dict[str, Any],
    status: str = "new"
) -> int:
    conn = get_connection()

    try:
        cursor = conn.cursor()

        raw_json = json.dumps(llm_result)
        confidence_score = llm_result.get("confidence_score")

        cursor.execute(
            """
            INSERT INTO stg.meal_image_predictions (
                user_id,
                image_path,
                raw_llm_response,
                confidence_score,
                status
            )
            OUTPUT INSERTED.prediction_id
            VALUES (?, ?, ?, ?, ?);
            """,
            user_id,
            image_path,
            raw_json,
            confidence_score,
            status
        )

        prediction_id = cursor.fetchone()[0]

        meal_items = llm_result.get("meal_items", [])

        for item in meal_items:
            cursor.execute(
                """
                INSERT INTO stg.detected_food_items (
                    prediction_id,
                    food_name_raw,
                    estimated_quantity,
                    unit,
                    estimated_calories,
                    estimated_protein_g,
                    estimated_carbs_g,
                    estimated_fat_g,
                    confidence_score
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
                """,
                prediction_id,
                item.get("food_name"),
                item.get("estimated_quantity"),
                item.get("unit"),
                item.get("calories"),
                item.get("protein_g"),
                item.get("carbs_g"),
                item.get("fat_g"),
                item.get("confidence_score")
            )

        conn.commit()
        return prediction_id

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()



        
def run_etl_procedure() -> None:
    conn = get_connection()

    try:
        cursor = conn.cursor()
        cursor.execute("EXEC etl.usp_process_new_meal_predictions;")
        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


def get_prediction_status(prediction_id: int) -> dict:
    conn = get_connection()

    try:
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT
                prediction_id,
                status,
                confidence_score,
                error_message,
                processed_at
            FROM stg.meal_image_predictions
            WHERE prediction_id = ?;
            """,
            prediction_id
        )

        row = cursor.fetchone()

        if not row:
            return {"error": "Prediction not found."}

        return {
            "prediction_id": row.prediction_id,
            "status": row.status,
            "confidence_score": float(row.confidence_score) if row.confidence_score is not None else None,
            "error_message": row.error_message,
            "processed_at": str(row.processed_at) if row.processed_at else None
        }

    finally:
        conn.close()


def process_meal_image(user_id: int, file_bytes: bytes, filename: str) -> dict:
    image_path = save_uploaded_image(file_bytes, filename)

    llm_provider = os.getenv("USE_LLM", "mock").lower()

    if llm_provider == "gemini":
        llm_result = analyze_meal_image_with_gemini(image_path)
        llm_mode = "gemini"
    else:
        llm_result = analyze_meal_image_mock(image_path)
        llm_mode = "mock"

    prediction_id = insert_llm_prediction_to_staging(
        user_id=user_id,
        image_path=image_path,
        llm_result=llm_result,
        status="confirmed"
    )

    run_etl_procedure()

    prediction_status = get_prediction_status(prediction_id)

    return {
        "message": "Meal image processed successfully.",
        "llm_mode": llm_mode,
        "prediction_id": prediction_id,
        "image_path": image_path,
        "llm_result": llm_result,
        "database_status": prediction_status
    }








def create_pending_confirmation(
    whatsapp_number: str,
    prediction_id: int
) -> None:
    conn = get_connection()

    try:
        cursor = conn.cursor()

        cursor.execute(
            """
            UPDATE stg.whatsapp_pending_confirmations
            SET
                status = 'expired',
                responded_at = SYSDATETIME()
            WHERE whatsapp_number = ?
              AND status = 'pending';
            """,
            whatsapp_number
        )

        cursor.execute(
            """
            INSERT INTO stg.whatsapp_pending_confirmations (
                whatsapp_number,
                prediction_id,
                status
            )
            VALUES (?, ?, 'pending');
            """,
            whatsapp_number,
            prediction_id
        )

        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


def stage_meal_image_for_confirmation(
    user_id: int,
    file_bytes: bytes,
    filename: str,
    whatsapp_number: str
) -> dict:
    image_path = save_uploaded_image(file_bytes, filename)

    llm_provider = os.getenv("USE_LLM", "mock").lower()

    if llm_provider == "gemini":
        from api.services.gemini_llm_service import analyze_meal_image_with_gemini
        llm_result = analyze_meal_image_with_gemini(image_path)
        llm_mode = "gemini"
    else:
        llm_result = analyze_meal_image_mock(image_path)
        llm_mode = "mock"

    prediction_id = insert_llm_prediction_to_staging(
        user_id=user_id,
        image_path=image_path,
        llm_result=llm_result,
        status="needs_confirmation"
    )

    create_pending_confirmation(
        whatsapp_number=whatsapp_number,
        prediction_id=prediction_id
    )

    return {
        "message": "Meal image analyzed and waiting for confirmation.",
        "llm_mode": llm_mode,
        "prediction_id": prediction_id,
        "image_path": image_path,
        "llm_result": llm_result,
        "database_status": {
            "status": "needs_confirmation"
        }
    }


def get_latest_pending_prediction(whatsapp_number: str) -> dict:
    conn = get_connection()

    try:
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT TOP 1
                p.pending_id,
                p.prediction_id,
                m.raw_llm_response,
                m.confidence_score
            FROM stg.whatsapp_pending_confirmations p
            INNER JOIN stg.meal_image_predictions m
                ON p.prediction_id = m.prediction_id
            WHERE p.whatsapp_number = ?
              AND p.status = 'pending'
              AND m.status = 'needs_confirmation'
            ORDER BY p.created_at DESC;
            """,
            whatsapp_number
        )

        row = cursor.fetchone()

        if not row:
            return {}

        return {
            "pending_id": row.pending_id,
            "prediction_id": row.prediction_id,
            "raw_llm_response": row.raw_llm_response,
            "confidence_score": float(row.confidence_score) if row.confidence_score is not None else None
        }

    finally:
        conn.close()


def confirm_latest_pending_meal(whatsapp_number: str) -> dict:
    pending = get_latest_pending_prediction(whatsapp_number)

    if not pending:
        return {
            "success": False,
            "message": "No pending meal found to confirm."
        }

    prediction_id = pending["prediction_id"]
    llm_result = json.loads(pending["raw_llm_response"])

    conn = get_connection()

    try:
        cursor = conn.cursor()

        cursor.execute(
            """
            UPDATE stg.meal_image_predictions
            SET status = 'confirmed'
            WHERE prediction_id = ?
              AND status = 'needs_confirmation';
            """,
            prediction_id
        )

        cursor.execute(
            """
            UPDATE stg.whatsapp_pending_confirmations
            SET
                status = 'confirmed',
                responded_at = SYSDATETIME()
            WHERE pending_id = ?;
            """,
            pending["pending_id"]
        )

        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()

    run_etl_procedure()

    prediction_status = get_prediction_status(prediction_id)

    return {
        "success": True,
        "message": "Meal confirmed and logged successfully.",
        "prediction_id": prediction_id,
        "llm_result": llm_result,
        "database_status": prediction_status
    }


def cancel_latest_pending_meal(whatsapp_number: str) -> dict:
    pending = get_latest_pending_prediction(whatsapp_number)

    if not pending:
        return {
            "success": False,
            "message": "No pending meal found to cancel."
        }

    prediction_id = pending["prediction_id"]

    conn = get_connection()

    try:
        cursor = conn.cursor()

        cursor.execute(
            """
            UPDATE stg.meal_image_predictions
            SET
                status = 'cancelled',
                processed_at = SYSDATETIME()
            WHERE prediction_id = ?
              AND status = 'needs_confirmation';
            """,
            prediction_id
        )

        cursor.execute(
            """
            UPDATE stg.whatsapp_pending_confirmations
            SET
                status = 'cancelled',
                responded_at = SYSDATETIME()
            WHERE pending_id = ?;
            """,
            pending["pending_id"]
        )

        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()

    return {
        "success": True,
        "message": f"Meal prediction {prediction_id} was cancelled.",
        "prediction_id": prediction_id
    }