SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Used to add Device in a similar format to the device list
-- Add Device Procedure (device & path)
CREATE OR ALTER PROCEDURE [AddDevice]
    @name NVARCHAR(50),
    @is_source BIT,
    @is_destination BIT,
    @connect_from NVARCHAR(50),
    @connect_to NVARCHAR(50)
AS
BEGIN
    DECLARE @id_from INT, @id_to INT

    
    IF (@is_source = 1) -- If Device is a Source, only add a device for current and to
    BEGIN
        EXEC insertDeviceForced @name, 1, 0, 1, 0
        EXEC insertDevice @connect_to, 1, 1, 0, 0


        -- Creates A Edge between devices
        SET @id_from = (SELECT device_id FROM device WHERE type = @name) --
        SET @id_to = (SELECT device_id FROM device WHERE type = @connect_to)
        EXEC insertPath 1, @id_from, @id_to
    END
    ELSE IF (@is_destination = 1) -- If Device is a Destination, only add a device for current and from
    BEGIN
        EXEC insertDeviceForced @name, 1, 0, 0, 1
        EXEC insertDevice @connect_from, 1, 1, 0, 0

        -- Creates A Edge between devices
        SET @id_from = (SELECT device_id FROM device WHERE type = @connect_from) --connect from
        SET @id_to = (SELECT device_id FROM device WHERE type = @name)  --dest
        EXEC insertPath 1, @id_from, @id_to
    END
    ELSE
    BEGIN
        EXEC insertDevice @name, 1, 1, 0, 0
        EXEC insertDevice @connect_to, 1, 1, 0, 0
        EXEC insertDevice @connect_from, 1, 1, 0, 0

        -- Creates A Edge between devices
        SET @id_from = (SELECT device_id FROM device WHERE type = @connect_from)
        SET @id_to = (SELECT device_id FROM device WHERE type = @name)
        EXEC insertPath 1, @id_from, @id_to

        -- Creates A Edge between devices
        SET @id_from = (SELECT device_id FROM device WHERE type = @name)
        SET @id_to = (SELECT device_id FROM device WHERE type = @connect_to)
        EXEC insertPath 1, @id_from, @id_to
    END
END
GO


--limitations: If SOURCE is directly connected to the DEST the procedure will give a false positive to either @is_source or @is_dest depending on which was inserted first.
