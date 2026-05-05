USE AI_Nutrition_Pipeline;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'ix_stg_predictions_status_created_at'
)
CREATE INDEX ix_stg_predictions_status_created_at
ON stg.meal_image_predictions(status, created_at);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'ix_stg_items_prediction_id'
)
CREATE INDEX ix_stg_items_prediction_id
ON stg.detected_food_items(prediction_id);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'ix_meal_logs_user_time'
)
CREATE INDEX ix_meal_logs_user_time
ON core.meal_logs(user_id, meal_time);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'ix_meal_items_meal_log_id'
)
CREATE INDEX ix_meal_items_meal_log_id
ON core.meal_log_items(meal_log_id);
GO