CREATE TABLE core.users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    gender NVARCHAR(20) NULL,
    age INT NULL,
    height_cm DECIMAL(5,2) NULL,
    weight_kg DECIMAL(5,2) NULL,
    activity_level NVARCHAR(50) NULL,
    goal NVARCHAR(50) NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT chk_users_age CHECK (age IS NULL OR age BETWEEN 10 AND 100),
    CONSTRAINT chk_users_height CHECK (height_cm IS NULL OR height_cm > 0),
    CONSTRAINT chk_users_weight CHECK (weight_kg IS NULL OR weight_kg > 0)
);
GO