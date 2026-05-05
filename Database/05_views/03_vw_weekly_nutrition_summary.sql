CREATE OR ALTER VIEW mart.vw_weekly_nutrition_summary AS
WITH daily AS (
    SELECT
        user_id,
        full_name,
        log_date,
        total_calories,
        total_protein_g,
        total_carbs_g,
        total_fat_g,
        meals_logged,
        DATEADD(
            DAY,
            -DATEDIFF(DAY, 0, log_date) % 7,
            log_date
        ) AS week_start_date
    FROM mart.vw_daily_nutrition_summary
)
SELECT
    user_id,
    full_name,
    week_start_date,
    COUNT(DISTINCT log_date) AS days_logged,
    SUM(meals_logged) AS total_meals_logged,
    SUM(total_calories) AS weekly_calories,
    AVG(total_calories) AS avg_daily_calories,
    SUM(total_protein_g) AS weekly_protein_g,
    AVG(total_protein_g) AS avg_daily_protein_g,
    SUM(total_carbs_g) AS weekly_carbs_g,
    AVG(total_carbs_g) AS avg_daily_carbs_g,
    SUM(total_fat_g) AS weekly_fat_g,
    AVG(total_fat_g) AS avg_daily_fat_g
FROM daily
GROUP BY
    user_id,
    full_name,
    week_start_date;
GO




SELECT * 
FROM mart.vw_weekly_nutrition_summary
ORDER BY week_start_date DESC;