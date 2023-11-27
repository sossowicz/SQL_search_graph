-- This creates a procedure to delete a device using device name/type which will also delete the correspoonding path that connects to the device
-- For example: EXEC DeleteDevice [device_type]


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
WHERE SPECIFIC_SCHEMA = N'dbo'
    AND SPECIFIC_NAME = N'DeleteDevice'
    AND ROUTINE_TYPE = N'PROCEDURE'
)
DROP PROCEDURE dbo.DeleteDevice
GO

-- Delete Procedure for 'device' table
CREATE PROCEDURE [dbo].[DeleteDevice]
    @device_name NVARCHAR(50)
AS

BEGIN
	DECLARE @device_id INT
	
	SELECT @device_id = device_id FROM device WHERE type = @device_name

	 IF @device_id IS NULL
     BEGIN
            PRINT 'Device name not found.'
     END

    DELETE FROM path WHERE input_device = @device_id OR output_device = @device_id
    DELETE FROM device WHERE device_id = @device_id
END
GO