CREATE OR ALTER VIEW mart.vw_target_vs_actual AS
WITH latest_targets AS (
    SELECT
        target_id,
        user_id,
        daily_calories,
        protein_target_g,
        carbs_target_g,
        fat_target_g,
        calculated_at,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY calculated_at DESC
        ) AS rn
    FROM core.nutrition_targets
)
SELECT
    d.user_id,
    d.full_name,
    d.log_date,

    d.total_calories,
    t.daily_calories AS calorie_target,
    d.total_calories - t.daily_calories AS calorie_gap,
    CASE 
        WHEN t.daily_calories = 0 THEN NULL
        ELSE ROUND((d.total_calories / t.daily_calories) * 100, 2)
    END AS calorie_target_achievement_pct,

    d.total_protein_g,
    t.protein_target_g,
    d.total_protein_g - t.protein_target_g AS protein_gap,
    CASE 
        WHEN t.protein_target_g = 0 THEN NULL
        ELSE ROUND((d.total_protein_g / t.protein_target_g) * 100, 2)
    END AS protein_target_achievement_pct,

    d.total_carbs_g,
    t.carbs_target_g,
    d.total_carbs_g - t.carbs_target_g AS carbs_gap,

    d.total_fat_g,
    t.fat_target_g,
    d.total_fat_g - t.fat_target_g AS fat_gap,

    d.meals_logged
FROM mart.vw_daily_nutrition_summary d
INNER JOIN latest_targets t
    ON d.user_id = t.user_id
WHERE t.rn = 1;
GO


SELECT * 
FROM mart.vw_target_vs_actual
ORDER BY log_date DESC;