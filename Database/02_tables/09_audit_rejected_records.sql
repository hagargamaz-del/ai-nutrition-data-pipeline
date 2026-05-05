CREATE TABLE audit.rejected_records (
    rejected_id INT IDENTITY(1,1) PRIMARY KEY,
    source_table NVARCHAR(100) NOT NULL,
    source_id INT NULL,
    record_data NVARCHAR(MAX) NULL,
    rejection_reason NVARCHAR(MAX) NOT NULL,
    rejected_at DATETIME2 DEFAULT SYSDATETIME()
);
GO