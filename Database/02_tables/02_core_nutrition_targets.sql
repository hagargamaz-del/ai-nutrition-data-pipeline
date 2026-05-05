CREATE TABLE core.nutrition_targets (
    target_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    daily_calories DECIMAL(8,2) NOT NULL,
    protein_target_g DECIMAL(8,2) NOT NULL,
    carbs_target_g DECIMAL(8,2) NOT NULL,
    fat_target_g DECIMAL(8,2) NOT NULL,
    calculated_at DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT fk_targets_users
        FOREIGN KEY (user_id) REFERENCES core.users(user_id),

    CONSTRAINT chk_targets_calories CHECK (daily_calories > 0),
    CONSTRAINT chk_targets_protein CHECK (protein_target_g >= 0),
    CONSTRAINT chk_targets_carbs CHECK (carbs_target_g >= 0),
    CONSTRAINT chk_targets_fat CHECK (fat_target_g >= 0)
);
GO