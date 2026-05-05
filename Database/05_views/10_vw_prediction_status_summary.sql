USE AI_Nutrition_Pipeline;
GO

CREATE OR ALTER VIEW mart.vw_prediction_status_summary AS
SELECT
    CAST(created_at AS DATE) AS prediction_date,
    status,
    COUNT(*) AS prediction_count,
    AVG(confidence_score) AS avg_confidence_score,
    MIN(confidence_score) AS min_confidence_score,
    MAX(confidence_score) AS max_confidence_score
FROM stg.meal_image_predictions
GROUP BY
    CAST(created_at AS DATE),
    status;
GO