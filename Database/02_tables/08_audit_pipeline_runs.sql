CREATE TABLE audit.pipeline_runs (
    run_id INT IDENTITY(1,1) PRIMARY KEY,
    pipeline_name NVARCHAR(100) NOT NULL,
    start_time DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    end_time DATETIME2 NULL,
    status NVARCHAR(30) NOT NULL DEFAULT 'running',
    records_processed INT DEFAULT 0,
    records_loaded INT DEFAULT 0,
    records_rejected INT DEFAULT 0,
    error_message NVARCHAR(MAX) NULL,

    CONSTRAINT chk_pipeline_status
        CHECK (status IN ('running', 'success', 'failed'))
);
GO