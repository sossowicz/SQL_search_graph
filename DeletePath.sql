-- This creates a procedure to delete a path using path id
-- For example: EXEC DeletePath [path_id]


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
WHERE SPECIFIC_SCHEMA = N'dbo'
    AND SPECIFIC_NAME = N'DeletePath'
    AND ROUTINE_TYPE = N'PROCEDURE'
)
DROP PROCEDURE dbo.DeletePath
GO

-- Delete Procedure for 'path' table
CREATE PROCEDURE [dbo].[DeletePath]
    @path_id INT
AS
BEGIN
	     DELETE FROM path WHERE path_id = @path_id
END
GO