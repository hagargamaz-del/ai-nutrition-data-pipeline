CREATE OR ALTER VIEW mart.vw_llm_prediction_quality AS
SELECT
    CAST(created_at AS DATE) AS prediction_date,
    COUNT(*) AS total_predictions,
    SUM(CASE WHEN status = 'loaded' THEN 1 ELSE 0 END) AS loaded_predictions,
    SUM(CASE WHEN status = 'needs_review' THEN 1 ELSE 0 END) AS needs_review_predictions,
    SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) AS rejected_predictions,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_predictions,
    AVG(confidence_score) AS avg_confidence_score,
    MIN(confidence_score) AS min_confidence_score,
    MAX(confidence_score) AS max_confidence_score
FROM stg.meal_image_predictions
GROUP BY
    CAST(created_at AS DATE);
GO







SELECT * 
FROM mart.vw_llm_prediction_quality
ORDER BY prediction_date DESC;