-- insertDevice Procedure
-- Used to insert a device onto the device table
CREATE OR ALTER PROCEDURE insertDevice
    @type NVARCHAR(50),
    @status BIT,
    @cost INT,
    @is_source BIT,
    @is_destination BIT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.device WHERE type = @type)
    BEGIN
        INSERT INTO dbo.device (type, status, cost, is_source, is_destination )
        VALUES (@type, @status, @cost, @is_source, @is_destination);

        PRINT 'New row inserted into DEVICE.';
    END
    ELSE
    BEGIN
        PRINT 'Duplicate row ignored.';
    END
END
GO

-- insertDeviceForced Procedure
-- Used to update a device already on the device table
CREATE OR ALTER PROCEDURE insertDeviceForced
    @type NVARCHAR(50),
    @status BIT,
    @cost INT,
    @is_source BIT,
    @is_destination BIT
AS
BEGIN
    -- Check if the row already exists.
  IF EXISTS (SELECT 1 FROM dbo.device WHERE type = @type)
  BEGIN
    -- Update the existing row with the new parameters.
    UPDATE dbo.device
      SET status = @status,
          cost = @cost,
          is_source = @is_source,
          is_destination = @is_destination
    WHERE type = @type;
    PRINT 'Existing row updated Forcefully in DEVICE.';
  END
  ELSE
  BEGIN
    -- Insert the new row.
    INSERT INTO dbo.device (type, status, cost, is_source, is_destination )
      VALUES (@type, @status, @cost, @is_source, @is_destination);
    PRINT 'New row inserted into DEVICE.';
  END
END
GO