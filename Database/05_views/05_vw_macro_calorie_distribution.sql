CREATE OR ALTER VIEW mart.vw_macro_calorie_distribution AS
SELECT
    user_id,
    full_name,
    log_date,

    total_protein_g,
    total_carbs_g,
    total_fat_g,

    total_protein_g * 4 AS protein_calories,
    total_carbs_g * 4 AS carbs_calories,
    total_fat_g * 9 AS fat_calories,

    (total_protein_g * 4) + (total_carbs_g * 4) + (total_fat_g * 9) AS macro_based_calories,

    CASE 
        WHEN ((total_protein_g * 4) + (total_carbs_g * 4) + (total_fat_g * 9)) = 0 THEN NULL
        ELSE ROUND(
            ((total_protein_g * 4) / 
            ((total_protein_g * 4) + (total_carbs_g * 4) + (total_fat_g * 9))) * 100,
            2
        )
    END AS protein_calorie_pct,

    CASE 
        WHEN ((total_protein_g * 4) + (total_carbs_g * 4) + (total_fat_g * 9)) = 0 THEN NULL
        ELSE ROUND(
            ((total_carbs_g * 4) / 
            ((total_protein_g * 4) + (total_carbs_g * 4) + (total_fat_g * 9))) * 100,
            2
        )
    END AS carbs_calorie_pct,

    CASE 
        WHEN ((total_protein_g * 4) + (total_carbs_g * 4) + (total_fat_g * 9)) = 0 THEN NULL
        ELSE ROUND(
            ((total_fat_g * 9) / 
            ((total_protein_g * 4) + (total_carbs_g * 4) + (total_fat_g * 9))) * 100,
            2
        )
    END AS fat_calorie_pct

FROM mart.vw_daily_nutrition_summary;
GO




SELECT * 
FROM mart.vw_macro_calorie_distribution
ORDER BY log_date DESC;