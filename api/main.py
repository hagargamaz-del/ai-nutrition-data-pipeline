import os
import requests

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Request, BackgroundTasks
from fastapi.responses import Response
from dotenv import load_dotenv
from twilio.twiml.messaging_response import MessagingResponse
from twilio.rest import Client

from api.services.meal_logging_service import (
    process_meal_image,
    stage_meal_image_for_confirmation,
    confirm_latest_pending_meal,
    cancel_latest_pending_meal
)

load_dotenv()

app = FastAPI(
    title="AI Nutrition Data Pipeline",
    description="AI-powered meal image logging pipeline using FastAPI, Gemini, WhatsApp, and SQL Server.",
    version="1.0.0"
)


@app.get("/")
def home():
    return {
        "message": "AI Nutrition Data Pipeline API is running."
    }


@app.post("/log-meal-image")
async def log_meal_image(
    user_id: int = Form(...),
    image: UploadFile = File(...)
):
    try:
        file_bytes = await image.read()

        result = process_meal_image(
            user_id=user_id,
            file_bytes=file_bytes,
            filename=image.filename
        )

        return result

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


def format_meal_items(llm_result: dict) -> str:
    meal_items = llm_result.get("meal_items", [])

    lines = []

    for item in meal_items:
        food_name = item.get("food_name", "unknown food")
        quantity = item.get("estimated_quantity", 0)
        unit = item.get("unit", "")
        calories = item.get("calories", 0)
        protein = item.get("protein_g", 0)
        carbs = item.get("carbs_g", 0)
        fat = item.get("fat_g", 0)
        confidence = item.get("confidence_score", 0)

        lines.append(
            f"- {food_name}: {quantity} {unit}, "
            f"{calories} kcal, "
            f"P {protein}g, C {carbs}g, F {fat}g "
            f"(conf. {confidence})"
        )

    return "\n".join(lines)


def format_confirmation_preview(result: dict) -> str:
    llm_result = result.get("llm_result", {})

    lines = []

    lines.append("🧾 Meal analysis result:")
    lines.append("")
    lines.append(f"Prediction ID: {result.get('prediction_id')}")
    lines.append("Status: waiting for confirmation")
    lines.append("")
    lines.append("🍽️ Detected items:")
    lines.append(format_meal_items(llm_result))
    lines.append("")
    lines.append("📊 Total estimate:")
    lines.append(f"Calories: {llm_result.get('total_calories', 0)} kcal")
    lines.append(f"Protein: {llm_result.get('total_protein_g', 0)} g")
    lines.append(f"Carbs: {llm_result.get('total_carbs_g', 0)} g")
    lines.append(f"Fat: {llm_result.get('total_fat_g', 0)} g")
    lines.append(f"Overall confidence: {llm_result.get('confidence_score', 0)}")
    lines.append("")
    lines.append("Reply CONFIRM to log this meal.")
    lines.append("Reply CANCEL to discard it.")

    return "\n".join(lines)


def format_confirmed_response(result: dict) -> str:
    llm_result = result.get("llm_result", {})
    database_status = result.get("database_status", {})

    lines = []

    lines.append("✅ Meal confirmed and logged successfully.")
    lines.append("")
    lines.append(f"Prediction ID: {result.get('prediction_id')}")
    lines.append(f"Database status: {database_status.get('status')}")
    lines.append("")
    lines.append("🍽️ Logged items:")
    lines.append(format_meal_items(llm_result))
    lines.append("")
    lines.append("📊 Total logged estimate:")
    lines.append(f"Calories: {llm_result.get('total_calories', 0)} kcal")
    lines.append(f"Protein: {llm_result.get('total_protein_g', 0)} g")
    lines.append(f"Carbs: {llm_result.get('total_carbs_g', 0)} g")
    lines.append(f"Fat: {llm_result.get('total_fat_g', 0)} g")

    return "\n".join(lines)


def send_whatsapp_message(to_number: str, message: str) -> None:
    account_sid = os.getenv("TWILIO_ACCOUNT_SID")
    auth_token = os.getenv("TWILIO_AUTH_TOKEN")
    from_number = os.getenv("TWILIO_WHATSAPP_FROM")

    if not account_sid or not auth_token:
        raise RuntimeError("Twilio credentials are missing from .env file.")

    if not from_number:
        raise RuntimeError("TWILIO_WHATSAPP_FROM is missing from .env file.")

    client = Client(account_sid, auth_token)

    sent_message = client.messages.create(
        body=message,
        from_=from_number,
        to=to_number
    )

    print("WhatsApp reply sent successfully.")
    print("Twilio Message SID:", sent_message.sid)


def process_whatsapp_image_background(
    media_url: str,
    media_content_type: str,
    sender: str
) -> None:
    try:
        account_sid = os.getenv("TWILIO_ACCOUNT_SID")
        auth_token = os.getenv("TWILIO_AUTH_TOKEN")

        if not account_sid or not auth_token:
            raise RuntimeError("Twilio credentials are missing from .env file.")

        media_response = requests.get(
            media_url,
            auth=(account_sid, auth_token),
            timeout=30
        )

        if media_response.status_code == 401:
            raise RuntimeError(
                "Twilio media download failed with 401 Unauthorized. "
                "Check TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN in .env."
            )

        media_response.raise_for_status()

        file_bytes = media_response.content

        extension = ".jpg"
        if "png" in media_content_type:
            extension = ".png"
        elif "jpeg" in media_content_type or "jpg" in media_content_type:
            extension = ".jpg"

        safe_sender = sender.replace("whatsapp:", "").replace("+", "").replace(":", "_")
        filename = f"whatsapp_pending_meal_{safe_sender}{extension}"

        default_user_id = int(os.getenv("DEFAULT_USER_ID", "1"))

        result = stage_meal_image_for_confirmation(
            user_id=default_user_id,
            file_bytes=file_bytes,
            filename=filename,
            whatsapp_number=sender
        )

        preview_message = format_confirmation_preview(result)

        send_whatsapp_message(
            to_number=sender,
            message=preview_message
        )

    except Exception as e:
        print("Error in background processing:", str(e))

        try:
            send_whatsapp_message(
                to_number=sender,
                message=f"❌ Error while processing the meal image:\n{str(e)}"
            )
        except Exception as send_error:
            print("Failed to send WhatsApp error message:", str(send_error))


@app.post("/whatsapp/webhook")
async def whatsapp_webhook(request: Request, background_tasks: BackgroundTasks):
    form = await request.form()

    num_media = int(form.get("NumMedia", "0"))
    message_body = form.get("Body", "").strip().upper()
    sender = form.get("From", "")

    twiml_response = MessagingResponse()

    if num_media > 0:
        media_url = form.get("MediaUrl0")
        media_content_type = form.get("MediaContentType0", "")

        if not media_url:
            twiml_response.message("No image URL was received from WhatsApp.")
            return Response(
                content=str(twiml_response),
                media_type="application/xml"
            )

        if "image" not in media_content_type:
            twiml_response.message("Please send an image file.")
            return Response(
                content=str(twiml_response),
                media_type="application/xml"
            )

        background_tasks.add_task(
            process_whatsapp_image_background,
            media_url,
            media_content_type,
            sender
        )

        twiml_response.message(
            "✅ Image received. I am analyzing it now. I will ask you to confirm before logging it."
        )

        return Response(
            content=str(twiml_response),
            media_type="application/xml"
        )

    if message_body == "CONFIRM":
        result = confirm_latest_pending_meal(sender)

        if not result.get("success"):
            twiml_response.message(result.get("message"))
        else:
            twiml_response.message(format_confirmed_response(result))

        return Response(
            content=str(twiml_response),
            media_type="application/xml"
        )

    if message_body == "CANCEL":
        result = cancel_latest_pending_meal(sender)
        twiml_response.message(result.get("message"))

        return Response(
            content=str(twiml_response),
            media_type="application/xml"
        )

    twiml_response.message(
        "Please send a meal image, or reply CONFIRM/CANCEL if you have a pending meal."
    )

    return Response(
        content=str(twiml_response),
        media_type="application/xml"
    )