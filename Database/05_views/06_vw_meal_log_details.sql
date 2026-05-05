CREATE OR ALTER VIEW mart.vw_meal_log_details AS
SELECT
    ml.meal_log_id,
    ml.user_id,
    u.full_name,
    CAST(ml.meal_time AS DATE) AS log_date,
    ml.meal_time,
    ml.meal_type,
    ml.source,
    ml.image_path,
    ml.prediction_id,

    mi.meal_item_id,
    mi.food_name,
    mi.quantity_g,
    mi.calories,
    mi.protein_g,
    mi.carbs_g,
    mi.fat_g,
    mi.confidence_score,

    ml.total_calories AS meal_total_calories,
    ml.total_protein_g AS meal_total_protein_g,
    ml.total_carbs_g AS meal_total_carbs_g,
    ml.total_fat_g AS meal_total_fat_g,

    ml.created_at
FROM core.meal_logs ml
INNER JOIN core.users u
    ON ml.user_id = u.user_id
INNER JOIN core.meal_log_items mi
    ON ml.meal_log_id = mi.meal_log_id;
GO