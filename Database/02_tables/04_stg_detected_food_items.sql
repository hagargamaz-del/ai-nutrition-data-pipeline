CREATE TABLE stg.detected_food_items (
    stg_item_id INT IDENTITY(1,1) PRIMARY KEY,
    prediction_id INT NOT NULL,
    food_name_raw NVARCHAR(150) NOT NULL,
    estimated_quantity DECIMAL(8,2) NULL,
    unit NVARCHAR(20) NULL,
    estimated_calories DECIMAL(8,2) NULL,
    estimated_protein_g DECIMAL(8,2) NULL,
    estimated_carbs_g DECIMAL(8,2) NULL,
    estimated_fat_g DECIMAL(8,2) NULL,
    confidence_score DECIMAL(5,2) NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT fk_stg_items_predictions
        FOREIGN KEY (prediction_id) REFERENCES stg.meal_image_predictions(prediction_id),

    CONSTRAINT chk_stg_items_quantity
        CHECK (estimated_quantity IS NULL OR estimated_quantity >= 0),

    CONSTRAINT chk_stg_items_calories
        CHECK (estimated_calories IS NULL OR estimated_calories >= 0),

    CONSTRAINT chk_stg_items_protein
        CHECK (estimated_protein_g IS NULL OR estimated_protein_g >= 0),

    CONSTRAINT chk_stg_items_carbs
        CHECK (estimated_carbs_g IS NULL OR estimated_carbs_g >= 0),

    CONSTRAINT chk_stg_items_fat
        CHECK (estimated_fat_g IS NULL OR estimated_fat_g >= 0),

    CONSTRAINT chk_stg_items_confidence
        CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1)
);
GO