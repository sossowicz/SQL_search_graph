SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- UpdateCost Procedure for device and path tables
-- Example use:
-- for Device table: exec UpdateCost "device_type", 0, 0, 123
-- for Path table: exec UpdateCost "doesn't matter", 1, 1, 123
CREATE OR ALTER PROCEDURE [UpdateCost]
  @type NVARCHAR(50),
  @path_id INT,
  @path BIT,
  @cost INT
AS
BEGIN
  IF (@path = 0)
  BEGIN
    UPDATE device
    SET cost = @cost
    WHERE type = @type
  END
  ELSE
  BEGIN
    UPDATE path
    SET cost = @cost
    WHERE path_id = @path_id
END
END
