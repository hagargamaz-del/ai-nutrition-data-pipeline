CREATE TABLE core.meal_log_items (
    meal_item_id INT IDENTITY(1,1) PRIMARY KEY,
    meal_log_id INT NOT NULL,
    food_name NVARCHAR(150) NOT NULL,
    quantity_g DECIMAL(8,2) NULL,
    calories DECIMAL(8,2) NOT NULL,
    protein_g DECIMAL(8,2) NOT NULL,
    carbs_g DECIMAL(8,2) NOT NULL,
    fat_g DECIMAL(8,2) NOT NULL,
    confidence_score DECIMAL(5,2) NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT fk_meal_items_logs
        FOREIGN KEY (meal_log_id) REFERENCES core.meal_logs(meal_log_id),

    CONSTRAINT chk_meal_items_quantity CHECK (quantity_g IS NULL OR quantity_g >= 0),
    CONSTRAINT chk_meal_items_calories CHECK (calories >= 0),
    CONSTRAINT chk_meal_items_protein CHECK (protein_g >= 0),
    CONSTRAINT chk_meal_items_carbs CHECK (carbs_g >= 0),
    CONSTRAINT chk_meal_items_fat CHECK (fat_g >= 0),
    CONSTRAINT chk_meal_items_confidence CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1)
);
GO