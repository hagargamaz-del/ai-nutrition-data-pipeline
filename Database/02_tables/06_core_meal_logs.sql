CREATE TABLE core.meal_logs (
    meal_log_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    prediction_id INT NULL,
    meal_time DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    meal_type NVARCHAR(30) NULL,
    image_path NVARCHAR(500) NULL,
    source NVARCHAR(50) NOT NULL DEFAULT 'llm_image',
    total_calories DECIMAL(8,2) NOT NULL,
    total_protein_g DECIMAL(8,2) NOT NULL,
    total_carbs_g DECIMAL(8,2) NOT NULL,
    total_fat_g DECIMAL(8,2) NOT NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT fk_meal_logs_users
        FOREIGN KEY (user_id) REFERENCES core.users(user_id),

    CONSTRAINT fk_meal_logs_predictions
        FOREIGN KEY (prediction_id) REFERENCES stg.meal_image_predictions(prediction_id),

    CONSTRAINT chk_meal_logs_calories CHECK (total_calories >= 0),
    CONSTRAINT chk_meal_logs_protein CHECK (total_protein_g >= 0),
    CONSTRAINT chk_meal_logs_carbs CHECK (total_carbs_g >= 0),
    CONSTRAINT chk_meal_logs_fat CHECK (total_fat_g >= 0)
);
GO