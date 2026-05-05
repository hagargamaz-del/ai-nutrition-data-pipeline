CREATE OR ALTER PROCEDURE etl.usp_process_new_meal_predictions
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @run_id INT;

    INSERT INTO audit.pipeline_runs (
        pipeline_name,
        status
    )
    VALUES (
        'process_new_meal_predictions',
        'running'
    );

    SET @run_id = SCOPE_IDENTITY();

    BEGIN TRY

        DECLARE @prediction_id INT;
        DECLARE @user_id INT;
        DECLARE @image_path NVARCHAR(500);
        DECLARE @confidence_score DECIMAL(5,2);
        DECLARE @meal_log_id INT;

        DECLARE prediction_cursor CURSOR FOR
        SELECT
            prediction_id,
            user_id,
            image_path,
            confidence_score
        FROM stg.meal_image_predictions
        WHERE status = 'confirmed';

        OPEN prediction_cursor;

        FETCH NEXT FROM prediction_cursor
        INTO @prediction_id, @user_id, @image_path, @confidence_score;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE stg.meal_image_predictions
            SET status = 'processing'
            WHERE prediction_id = @prediction_id;

            IF @confidence_score IS NULL OR @confidence_score < 0.60
            BEGIN
                UPDATE stg.meal_image_predictions
                SET
                    status = 'needs_review',
                    processed_at = SYSDATETIME(),
                    error_message = 'Confidence score is below threshold.'
                WHERE prediction_id = @prediction_id;

                INSERT INTO audit.rejected_records (
                    source_table,
                    source_id,
                    record_data,
                    rejection_reason
                )
                SELECT
                    'stg.meal_image_predictions',
                    prediction_id,
                    raw_llm_response,
                    'Low confidence score. Requires user review.'
                FROM stg.meal_image_predictions
                WHERE prediction_id = @prediction_id;
            END
            ELSE IF NOT EXISTS (
                SELECT 1
                FROM stg.detected_food_items
                WHERE prediction_id = @prediction_id
            )
            BEGIN
                UPDATE stg.meal_image_predictions
                SET
                    status = 'rejected',
                    processed_at = SYSDATETIME(),
                    error_message = 'No detected food items found.'
                WHERE prediction_id = @prediction_id;

                INSERT INTO audit.rejected_records (
                    source_table,
                    source_id,
                    rejection_reason
                )
                VALUES (
                    'stg.meal_image_predictions',
                    @prediction_id,
                    'No detected food items found.'
                );
            END
            ELSE
            BEGIN
                INSERT INTO core.meal_logs (
                    user_id,
                    prediction_id,
                    meal_time,
                    meal_type,
                    image_path,
                    source,
                    total_calories,
                    total_protein_g,
                    total_carbs_g,
                    total_fat_g
                )
                SELECT
                    p.user_id,
                    p.prediction_id,
                    SYSDATETIME(),
                    'unknown',
                    p.image_path,
                    'llm_image',
                    SUM(ISNULL(i.estimated_calories, 0)),
                    SUM(ISNULL(i.estimated_protein_g, 0)),
                    SUM(ISNULL(i.estimated_carbs_g, 0)),
                    SUM(ISNULL(i.estimated_fat_g, 0))
                FROM stg.meal_image_predictions p
                INNER JOIN stg.detected_food_items i
                    ON p.prediction_id = i.prediction_id
                WHERE p.prediction_id = @prediction_id
                GROUP BY
                    p.user_id,
                    p.prediction_id,
                    p.image_path;

                SET @meal_log_id = SCOPE_IDENTITY();

                INSERT INTO core.meal_log_items (
                    meal_log_id,
                    food_name,
                    quantity_g,
                    calories,
                    protein_g,
                    carbs_g,
                    fat_g,
                    confidence_score
                )
                SELECT
                    @meal_log_id,
                    LOWER(LTRIM(RTRIM(food_name_raw))) AS food_name,
                    CASE
                        WHEN unit = 'g' THEN estimated_quantity
                        ELSE NULL
                    END AS quantity_g,
                    ISNULL(estimated_calories, 0),
                    ISNULL(estimated_protein_g, 0),
                    ISNULL(estimated_carbs_g, 0),
                    ISNULL(estimated_fat_g, 0),
                    confidence_score
                FROM stg.detected_food_items
                WHERE prediction_id = @prediction_id;

                UPDATE stg.meal_image_predictions
                SET
                    status = 'loaded',
                    processed_at = SYSDATETIME()
                WHERE prediction_id = @prediction_id;
            END

            FETCH NEXT FROM prediction_cursor
            INTO @prediction_id, @user_id, @image_path, @confidence_score;
        END

        CLOSE prediction_cursor;
        DEALLOCATE prediction_cursor;

        UPDATE audit.pipeline_runs
        SET
            end_time = SYSDATETIME(),
            status = 'success',
            records_processed = (
                SELECT COUNT(*)
                FROM stg.meal_image_predictions
                WHERE CAST(created_at AS DATE) = CAST(SYSDATETIME() AS DATE)
            ),
            records_loaded = (
                SELECT COUNT(*)
                FROM stg.meal_image_predictions
                WHERE status = 'loaded'
            ),
            records_rejected = (
                SELECT COUNT(*)
                FROM stg.meal_image_predictions
                WHERE status IN ('rejected', 'needs_review', 'failed')
            )
        WHERE run_id = @run_id;

    END TRY
    BEGIN CATCH

        UPDATE audit.pipeline_runs
        SET
            end_time = SYSDATETIME(),
            status = 'failed',
            error_message = ERROR_MESSAGE()
        WHERE run_id = @run_id;

        THROW;

    END CATCH
END;
GO