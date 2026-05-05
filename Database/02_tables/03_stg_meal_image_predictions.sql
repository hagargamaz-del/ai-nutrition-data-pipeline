CREATE TABLE stg.meal_image_predictions (
    prediction_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    image_path NVARCHAR(500) NOT NULL,
    raw_llm_response NVARCHAR(MAX) NOT NULL,
    confidence_score DECIMAL(5,2) NULL,
    status NVARCHAR(30) NOT NULL DEFAULT 'new',
    error_message NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    processed_at DATETIME2 NULL,

    CONSTRAINT fk_stg_predictions_users
        FOREIGN KEY (user_id) REFERENCES core.users(user_id),

    CONSTRAINT chk_stg_predictions_json
        CHECK (ISJSON(raw_llm_response) = 1),

    CONSTRAINT chk_stg_predictions_status
        CHECK (status IN ('new', 'processing', 'validated', 'loaded', 'needs_review', 'rejected', 'failed')),

    CONSTRAINT chk_stg_predictions_confidence
        CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1)
);
GO

