-- This creates a procedure to update device using device id, needs to input all parameters at once
-- For example: EXEC UpdateDevice id, cost, type, status


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
WHERE SPECIFIC_SCHEMA = N'dbo'
    AND SPECIFIC_NAME = N'UpdateDevice'
    AND ROUTINE_TYPE = N'PROCEDURE'
)
DROP PROCEDURE dbo.UpdateDevice
GO

-- Update Procedure for 'device' table
CREATE PROCEDURE [dbo].[UpdateDevice]
    @device_id INT,
	@cost INT,
    @type NVARCHAR(50),
    @status BIT
AS
BEGIN
    UPDATE device
    SET cost = @cost, type = @type, status = @status
    WHERE device_id = @device_id
END
GO