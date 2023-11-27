-- Create the stored procedure in the specified schema
CREATE OR ALTER PROCEDURE dbo.searchDijkstras
    @source_device NVARCHAR(MAX), 
    @destination_device NVARCHAR(MAX) 

AS 
BEGIN
    --if temporary tables already exist, remove them
    IF OBJECT_ID('tempDB..#active_outputs', 'U') IS NOT NULL
    DROP TABLE #active_outputs

    IF OBJECT_ID('tempDB..#active_paths', 'U') IS NOT NULL
    DROP TABLE #active_paths

    IF OBJECT_ID('tempDB..#active', 'U') IS NOT NULL
    DROP TABLE #active

    --creating temporary table active_outputs
    --This table takes entries from the path table where the output device status is set to 1 (operational)
    SELECT path.*
    INTO #active_outputs
    FROM path
    INNER JOIN device ON path.output_device = device.device_id
    WHERE device.status = 1;

    --creating temporary table active_paths
    --This table contains entries from ##active_outputs table where the input device status is set to 1 (operational)
    --All the entries in this table are paths where the input and output device status is set to 1
    SELECT #active_outputs.*, dbo.device.cost as output_cost
    INTO #active_paths
    FROM #active_outputs
    INNER JOIN device ON #active_outputs.output_device = device.device_id
    WHERE device.status = 1;

    --creating temporary table active
    --same as table ##active_paths, with an extra column for device names
    SELECT #active_paths.*, dbo.device.type as output_device_name
    INTO #active
    FROM #active_paths
    INNER JOIN device ON #active_paths.output_device = device.device_id;

    -- Create a Heap, will contain Possible Paths on Search Queue
    IF OBJECT_ID('tempdb..#possible_path_queue') IS NOT NULL
        DROP TABLE #possible_path_queue;
    ELSE
        CREATE TABLE #possible_path_queue(path_description NVARCHAR(MAX), cost INT, device_ID INT);

    -- Initialize a count variable to = 0 for each Device
    IF OBJECT_ID('tempdb..#device_visited') IS NOT NULL
        DROP TABLE #device_visited;
    ELSE
        CREATE TABLE #device_visited(device_id INT, count INT);

    -- Initialixe empty set of Paths to store the 5 shortest paths.
    IF OBJECT_ID('tempdb..#completed_path_list') IS NOT NULL
        DROP TABLE #completed_path_list;
    ELSE
        CREATE TABLE #completed_path_list(path_description NVARCHAR(MAX), cost INT);


    -- Temporary Table for number of times a device has been visited. Initializing count to 0
    INSERT INTO #device_visited (device_id, count)
    SELECT device_id, 0
    FROM device
    WHERE status = 1;

    -- Initialize multiple variables to allow for deletion of paths when theyre being explored, as well as Device IDs
    DECLARE @destination_count INT , @possible_path_rows INT , @current_path NVARCHAR(MAX) , @current_cost INT, @current_device_count INT
    DECLARE @current_device_id INT, @destination_device_id INT

    SET @possible_path_rows = 1;
    SET @destination_count = 0;

    SELECT @current_device_id = device_id 
    FROM device
    WHERE type = @source_device;

    SELECT @destination_device_id = device_id 
    FROM device
    WHERE type = @destination_device;



    -- Insert Source onto Search Queue
    INSERT INTO #possible_path_queue (path_description, cost, device_ID)
        VALUES (@source_device, 0, @current_device_id);

    -- Begin recursion, condtions: Heap cant be empty and destination_count is less then 5
    WHILE ((@possible_path_rows != 0) AND (@destination_count < 5))
    BEGIN
        -- Selects current shortest Path in Search Queue
        SELECT TOP 1 @current_path = path_description, @current_cost = cost, @current_device_id = device_ID
        FROM #possible_path_queue 
        ORDER BY cost ASC;

        -- 
        DELETE FROM #possible_path_queue
        WHERE path_description = @current_path

        UPDATE #device_visited
        SET count = count + 1
        WHERE device_id = @current_device_id

        SELECT @current_device_count = count
        FROM #device_visited
        WHERE device_id = @current_device_id

        -- Check if current device is Destination Device
        -- If True add Path onto completed Paths
        IF @current_device_id = @destination_device_id
        BEGIN
            INSERT INTO #completed_path_list (path_description, cost)
            SELECT @current_path, @current_cost
        END
        -- Check if Device has already been explored more then 5 times
        -- If not, explore and add possible paths to queue
        ELSE IF @current_device_count < 5
        BEGIN
            WITH neighbour_devices_list AS (
                SELECT
                output_device AS neighbour_device,
                @current_cost + p.cost + p.output_cost AS pathcost,
                CAST(CONVERT(NVARCHAR(MAX),@current_path) + '->' + CONVERT(NVARCHAR(MAX),output_device_name) AS NVARCHAR(MAX)) AS Neighbour_Path  

                -- Uses Temp Table of only Paths With Operational Devices
                FROM #active p

                -- Will only explore the Current Device Neighbours
                WHERE input_device = @current_device_id
            )
            -- Inserts all Neighbour Paths back onto Search Queue (If they arent already there)
            INSERT INTO #possible_path_queue (path_description, cost, device_ID)
            SELECT Neighbour_Path, pathcost, neighbour_device
            FROM neighbour_devices_list
            WHERE NOT EXISTS (
                SELECT 1
                FROM #possible_path_queue AS p
                WHERE p.path_description = Neighbour_Path
            );
        END

        -- Update destination_count for while loop condition
        SELECT @destination_count = count
        FROM #device_visited
        WHERE device_id = @destination_device_id

        -- Update possible_path_rows for while loop condition
        SELECT @possible_path_rows = COUNT(*)
        FROM #possible_path_queue

    END
    
    -- Display Table of Results
    SELECT * FROM #completed_path_list
END
GO
