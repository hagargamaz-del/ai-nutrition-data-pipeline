USE AI_Nutrition_Pipeline;
GO

CREATE TABLE stg.whatsapp_pending_confirmations (
    pending_id INT IDENTITY(1,1) PRIMARY KEY,
    whatsapp_number NVARCHAR(50) NOT NULL,
    prediction_id INT NOT NULL,
    status NVARCHAR(30) NOT NULL DEFAULT 'pending',
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    responded_at DATETIME2 NULL,

    CONSTRAINT fk_pending_prediction
        FOREIGN KEY (prediction_id)
        REFERENCES stg.meal_image_predictions(prediction_id),

    CONSTRAINT chk_pending_status
        CHECK (status IN ('pending', 'confirmed', 'cancelled', 'expired'))
);
GO