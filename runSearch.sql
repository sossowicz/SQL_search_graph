-- runSearch checks if the source_device and destination_device id given are a valid source and destination device
-- if the id's are valid, runSearch will run a recursive search using the source and destination device 

-- Create a new stored procedure called 'runSearch' in schema 'dbo'
-- Create the stored procedure in the specified schema, takes in device names
CREATE OR ALTER PROCEDURE dbo.runSearch
    @src_device_name NVARCHAR(50),  
    @dest_device_name NVARCHAR(50)

AS
BEGIN

	DECLARE @src_device_id int
    DECLARE @dest_device_id int

    -- Fetch the IDs for the provided names/types
    SELECT @src_device_id = device_id FROM device WHERE type = @src_device_name
    SELECT @dest_device_id = device_id FROM device WHERE type = @dest_device_name

    DECLARE @is_src bit = 0
    DECLARE @is_dest bit = 0

    --get is_source and is_destination bit values for @src_device and @dest_device from device table
    SELECT @is_src = device.is_source
    FROM device 
    WHERE device.device_id = @src_device_id

    SELECT @is_dest = device.is_destination
    FROM device 
    WHERE device.device_id = @dest_device_id

    --check that @src_device and @dest_device are valid source and destination devices, if so run recursive search 
    IF @is_src = 1 AND @is_dest = 1
        BEGIN
            EXEC searchDijkstras @src_device_name, @dest_device_name
        END
    ELSE 
        BEGIN
            PRINT 'Invalid source and/or destination device name provided'
        END
END
GO


-- runMultipleSearch checks if the source_device and destination_devices given are a valid source and destination devices
-- if the names are valid, runMultipleSearch will run a Dijkstras search using the source and destination devices

-- Create a new stored procedure called 'runSearch' in schema 'dbo'
-- Create the stored procedure in the specified schema, takes in device names
CREATE OR ALTER PROCEDURE dbo.runMultipleSearch
    @src_device_name NVARCHAR(50),  
    @dest_device_name_1 NVARCHAR(50),
    @dest_device_name_2 NVARCHAR(50)

AS
BEGIN

	DECLARE @src_device_id int
    DECLARE @dest_device_id_1 int
    DECLARE @dest_device_id_2 int

    -- Fetch the IDs for the provided names/types
    SELECT @src_device_id = device_id FROM device WHERE type = @src_device_name
    SELECT @dest_device_id_1 = device_id FROM device WHERE type = @dest_device_name_1
    SELECT @dest_device_id_2 = device_id FROM device WHERE type = @dest_device_name_2

    DECLARE @is_src bit = 0
    DECLARE @is_dest_1 bit = 0
    DECLARE @is_dest_2 bit = 0

    --get is_source and is_destination bit values for @src_device and @dest_device from device table
    SELECT @is_src = device.is_source
    FROM device 
    WHERE device.device_id = @src_device_id

    SELECT @is_dest_1 = device.is_destination
    FROM device 
    WHERE device.device_id = @dest_device_id_1

    SELECT @is_dest_2 = device.is_destination
    FROM device 
    WHERE device.device_id = @dest_device_id_2

    --check that @src_device and @dest_device are valid source and destination devices, if so run recursive search 
    IF @is_src = 1 AND @is_dest_1 = 1 AND @is_dest_2 = 1
        BEGIN
            EXEC searchMultiple @src_device_name, @dest_device_name_1, @dest_device_name_2
        END
    ELSE 
        BEGIN
            PRINT 'Invalid source and/or destination device name provided'
        END
    

END
GO
