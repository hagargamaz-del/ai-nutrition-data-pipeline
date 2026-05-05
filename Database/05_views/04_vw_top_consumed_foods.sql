CREATE OR ALTER VIEW mart.vw_top_consumed_foods AS
SELECT
    mi.food_name,
    COUNT(*) AS times_logged,
    SUM(ISNULL(mi.quantity_g, 0)) AS total_quantity_g,
    SUM(mi.calories) AS total_calories,
    AVG(mi.calories) AS avg_calories,
    AVG(mi.protein_g) AS avg_protein_g,
    AVG(mi.carbs_g) AS avg_carbs_g,
    AVG(mi.fat_g) AS avg_fat_g,
    AVG(mi.confidence_score) AS avg_confidence_score
FROM core.meal_log_items mi
GROUP BY
    mi.food_name;
GO



SELECT * 
FROM mart.vw_top_consumed_foods
ORDER BY times_logged DESC;