CREATE OR ALTER VIEW mart.vw_rejected_records_summary AS
SELECT
    CAST(rejected_at AS DATE) AS rejection_date,
    source_table,
    rejection_reason,
    COUNT(*) AS rejected_count
FROM audit.rejected_records
GROUP BY
    CAST(rejected_at AS DATE),
    source_table,
    rejection_reason;
GO



SELECT * 
FROM mart.vw_rejected_records_summary
ORDER BY rejection_date DESC;