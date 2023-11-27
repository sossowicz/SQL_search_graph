-- This creates a procedure to update the status of device using device name/type
-- For example: EXEC UpdateStatus [device_type], [status]


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
WHERE SPECIFIC_SCHEMA = N'dbo'
    AND SPECIFIC_NAME = N'UpdateStatus'
    AND ROUTINE_TYPE = N'PROCEDURE'
)
DROP PROCEDURE dbo.UpdateStatus
GO

-- Update Procedure for 'device' table
CREATE PROCEDURE [dbo].[UpdateStatus]
    @device_name NVARCHAR(50),
    @status BIT
AS
BEGIN
    
	DECLARE @device_id INT
	
	SELECT @device_id = device_id FROM device WHERE type = @device_name

	IF @device_id IS NULL
    BEGIN
            PRINT 'Device name not found.'
    END
	UPDATE device
    SET  status = @status
    WHERE device_id = @device_id
END
GO