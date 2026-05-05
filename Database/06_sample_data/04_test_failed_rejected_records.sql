USE AI_Nutrition_Pipeline;
GO

/* 
    This script creates simulated failed and rejected prediction records.
    It is optional and used only for testing the Power BI monitoring dashboard.
*/

-- Simulated failed prediction
INSERT INTO stg.meal_image_predictions (
    user_id,
    image_path,
    raw_llm_response,
    confidence_score,
    status,
    error_message,
    processed_at
)
VALUES (
    1,
    'test/failed_gemini_api_record.jpg',
    '{
        "meal_items": [],
        "total_calories": 0,
        "total_protein_g": 0,
        "total_carbs_g": 0,
        "total_fat_g": 0,
        "confidence_score": 0
    }',
    0.00,
    'failed',
    'Simulated Gemini/API processing failure for dashboard testing.',
    SYSDATETIME()
);
GO


-- Simulated rejected prediction
DECLARE @rejected_prediction_id INT;
DECLARE @record_data NVARCHAR(MAX);

SET @record_data = '{
    "meal_items": [],
    "total_calories": -100,
    "total_protein_g": 0,
    "total_carbs_g": 0,
    "total_fat_g": 0,
    "confidence_score": 0.20
}';

INSERT INTO stg.meal_image_predictions (
    user_id,
    image_path,
    raw_llm_response,
    confidence_score,
    status,
    error_message,
    processed_at
)
VALUES (
    1,
    'test/rejected_invalid_nutrition_record.jpg',
    @record_data,
    0.20,
    'rejected',
    'Simulated rejected record: invalid or low-quality nutrition extraction.',
    SYSDATETIME()
);

SET @rejected_prediction_id = SCOPE_IDENTITY();

INSERT INTO audit.rejected_records (
    source_table,
    source_id,
    record_data,
    rejection_reason,
    rejected_at
)
VALUES (
    'stg.meal_image_predictions',
    @rejected_prediction_id,
    @record_data,
    'Simulated rejected record for dashboard testing.',
    SYSDATETIME()
);
GO