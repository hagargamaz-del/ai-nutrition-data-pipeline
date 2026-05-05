CREATE OR ALTER VIEW mart.vw_daily_nutrition_summary AS
SELECT
    ml.user_id,
    u.full_name,
    CAST(ml.meal_time AS DATE) AS log_date,
    COUNT(DISTINCT ml.meal_log_id) AS meals_logged,
    SUM(ml.total_calories) AS total_calories,
    SUM(ml.total_protein_g) AS total_protein_g,
    SUM(ml.total_carbs_g) AS total_carbs_g,
    SUM(ml.total_fat_g) AS total_fat_g,
    AVG(ml.total_calories) AS avg_calories_per_meal
FROM core.meal_logs ml
INNER JOIN core.users u
    ON ml.user_id = u.user_id
GROUP BY
    ml.user_id,
    u.full_name,
    CAST(ml.meal_time AS DATE);
GO





SELECT * 
FROM mart.vw_daily_nutrition_summary
ORDER BY log_date DESC;