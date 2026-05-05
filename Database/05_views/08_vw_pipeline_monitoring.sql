CREATE OR ALTER VIEW mart.vw_pipeline_monitoring AS
SELECT
    run_id,
    pipeline_name,
    start_time,
    end_time,
    DATEDIFF(SECOND, start_time, end_time) AS duration_seconds,
    status,
    records_processed,
    records_loaded,
    records_rejected,
    error_message
FROM audit.pipeline_runs;
GO


SELECT * 
FROM mart.vw_pipeline_monitoring
ORDER BY run_id DESC;