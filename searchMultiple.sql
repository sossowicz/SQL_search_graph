-- Create the stored procedure in the specified schema
CREATE OR ALTER PROCEDURE dbo.searchMultiple
    @source_device NVARCHAR(MAX), 
    @destination_device_1 NVARCHAR(MAX),
    @destination_device_2 NVARCHAR(MAX) 

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

    -- Initialize empty set of Paths to store the 5 shortest paths.
    IF OBJECT_ID('tempdb..#completed_path_list') IS NOT NULL
        DROP TABLE #completed_path_list;
    ELSE
        CREATE TABLE #completed_path_list(path_description NVARCHAR(MAX), cost INT, destination_device NVARCHAR(50));


    -- Temporary Table for number of times a device has been visited. Initializing count to 0
    INSERT INTO #device_visited (device_id, count)
    SELECT device_id, 0
    FROM device
    WHERE status = 1;

    -- Initialize multiple variables to allow for deletion of paths when theyre being explored, as well as Device IDs
    DECLARE @destination_1_count INT , @destination_2_count INT , @possible_path_rows INT , @current_path NVARCHAR(MAX) , @current_cost INT, @current_device_count INT
    DECLARE @current_device_id INT, @destination_device_1_id INT, @destination_device_2_id INT

    SET @possible_path_rows = 1;
    SET @destination_1_count = 0;
    SET @destination_2_count = 0;

    SELECT @current_device_id = device_id 
    FROM device
    WHERE type = @source_device;

    SELECT @destination_device_1_id = device_id 
    FROM device
    WHERE type = @destination_device_1;

    SELECT @destination_device_2_id = device_id 
    FROM device
    WHERE type = @destination_device_2;



    -- Insert Source onto Search Queue
    INSERT INTO #possible_path_queue (path_description, cost, device_ID)
        VALUES (@source_device, 0, @current_device_id);

    -- Begin recursion, condtions: Heap cant be empty and destination_1_count is less then 5
    WHILE ((@possible_path_rows != 0) AND ((@destination_1_count < 5) OR (@destination_2_count < 5)))
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

        -- Check if current device is Destination Device 1
        -- If True add Path onto completed Paths
        IF (@current_device_id = @destination_device_1_id AND @current_device_count != 6)
        BEGIN
            INSERT INTO #completed_path_list (path_description, cost, destination_device)
            SELECT @current_path, @current_cost, @destination_device_1
        END
        -- Check if current device is Destination Device 2
        -- If True add Path onto completed Paths
        ELSE IF (@current_device_id = @destination_device_2_id AND @current_device_count != 6)
        BEGIN
            INSERT INTO #completed_path_list (path_description, cost, destination_device)
            SELECT @current_path, @current_cost, @destination_device_2
        END
        -- Check if Device has already been explored more then 5 times
        -- If not, explore and add possible paths to queue
        ELSE IF @current_device_count < 5
        BEGIN
            WITH neighbour_devices_list AS (
                SELECT
                output_device AS neighbour_device,
                @current_cost + p.cost + p.output_cost AS pathcost,
                CAST(CONVERT(NVARCHAR(MAX),@current_path) + '-' + CONVERT(NVARCHAR(MAX),output_device_name) AS NVARCHAR(MAX)) AS Neighbour_Path  

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

        -- Update destination_1_count for while loop condition
        SELECT @destination_1_count = count
        FROM #device_visited
        WHERE device_id = @destination_device_1_id

        -- Update destination_1_count for while loop condition
        SELECT @destination_2_count = count
        FROM #device_visited
        WHERE device_id = @destination_device_2_id

        -- Update possible_path_rows for while loop condition
        SELECT @possible_path_rows = COUNT(*)
        FROM #possible_path_queue

    END
    
    -- Display Table of Results
    -- SELECT * FROM #completed_path_list


    /*
        MULTIPLE DESTINATIONS RECURSION
    */


    -- Initialize empty set of Paths to compare the shortest paths.
    IF OBJECT_ID('tempdb..#completed_paths_stored') IS NOT NULL
        DROP TABLE #completed_paths_stored;
    ELSE
        CREATE TABLE #completed_paths_stored(path_description NVARCHAR(MAX), cost INT, destination_device NVARCHAR(50));

    -- Initialize empty set of Paths to store the multiple shortest paths.
    IF OBJECT_ID('tempdb..#completed_multiple_path_list') IS NOT NULL
        DROP TABLE #completed_multiple_path_list;
    ELSE
        CREATE TABLE #completed_multiple_path_list(multiple_path_description NVARCHAR(MAX), cost INT);

    -- Initialize empty set of Paths to compare the shortest paths.
    IF OBJECT_ID('tempdb..#temporary_path_list') IS NOT NULL
        DROP TABLE #temporary_path_list;
    ELSE
        CREATE TABLE #temporary_path_list(path_description NVARCHAR(MAX), cost INT, destination_device NVARCHAR(50));

    -- Initialize empty set of Paths to compare the shortest paths.
    IF OBJECT_ID('tempdb..#path_comparison_1') IS NOT NULL
        DROP TABLE #path_comparison_1;
    ELSE
        CREATE TABLE #path_comparison_1(path_1_devices NVARCHAR(50));

    -- Initialize empty set of Paths to compare the shortest paths.
    IF OBJECT_ID('tempdb..#path_comparison_2') IS NOT NULL
        DROP TABLE #path_comparison_2;
    ELSE
        CREATE TABLE #path_comparison_2(path_2_devices NVARCHAR(50));

    INSERT INTO #completed_paths_stored (path_description, cost, destination_device)
    SELECT #completed_path_list.*
    FROM #completed_path_list

    DECLARE @completed_rows INT, @temporary_rows INT, @current_device NVARCHAR(20), @comparison_path_var NVARCHAR(MAX), @path_cost INT, @comparison_rows_1 INT, @comparison_rows_2 INT, @device_cost INT
    DECLARE @path_input_id INT, @path_output_id INT
    -- Variables for comparison of two paths
    DECLARE @device_path_1 NVARCHAR(20), @device_path_2 NVARCHAR(20), @device_path_1_prev NVARCHAR(20), @device_path_2_prev NVARCHAR(20)

    SELECT @completed_rows = COUNT(*)
    FROM #completed_path_list




    -- BEGIN RECURSION

    WHILE (@completed_rows != 0)
    BEGIN
        -- Selects current shortest Path in Completed Paths
        SELECT TOP 1 @current_path = path_description, @current_device = destination_device
        FROM #completed_path_list 
        ORDER BY cost ASC;

        -- Removes the current working path from the list
        DELETE FROM #completed_path_list
        WHERE path_description = @current_path

        -- Fill temporary table with values of paths to the other destination device
        INSERT INTO #temporary_path_list (path_description, cost, destination_device)
        SELECT #completed_path_list.*
        FROM #completed_path_list
        WHERE destination_device != @current_device

        -- Update temporary_rows for while loop condition
        SELECT @temporary_rows = COUNT(*)
        FROM #temporary_path_list

        WHILE (@temporary_rows != 0)
        BEGIN
            -- Retrieve the current comparison path - then remove from queue
            SELECT TOP 1 @comparison_path_var = path_description
            FROM #temporary_path_list 
            ORDER BY cost ASC;

            DELETE FROM #temporary_path_list
            WHERE path_description = @comparison_path_var

            -- inserts broken string into table (not row sorted though)
            INSERT INTO #path_comparison_1(path_1_devices)
            SELECT value AS SplitValue
            FROM STRING_SPLIT(@current_path, '-');

            INSERT INTO #path_comparison_2(path_2_devices)
            SELECT value AS SplitValue
            FROM STRING_SPLIT(@comparison_path_var, '-');

            SET @current_cost = 0;
            SET @path_cost = 0;

            -- Update comparison_rows for while loop condition
            SELECT @comparison_rows_1 = COUNT(*)
            FROM #path_comparison_1
            -- Update comparison_rows for while loop condition
            SELECT @comparison_rows_2 = COUNT(*)
            FROM #path_comparison_2

            WHILE ((@comparison_rows_1 != 0) AND (@comparison_rows_2 != 0))
            BEGIN
                SELECT TOP 1 @device_path_1 = path_1_devices
                FROM #path_comparison_1

                SELECT TOP 1 @device_path_2 = path_2_devices
                FROM #path_comparison_2

                IF ((@device_path_1 = @source_device) AND (@device_path_2 = @source_device))
                BEGIN
                    SELECT @device_cost = cost
                    FROM device
                    WHERE type = @source_device                    
                    
                    SET @current_cost = @current_cost + @device_cost
                END
                -- If device are the same
                ELSE IF (@device_path_1 = @device_path_2)
                BEGIN
                    -- If previous device are the same, only add path and device costs
                    IF (@device_path_1_prev = @device_path_2_prev)
                    BEGIN
                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_1_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_1)
                        
                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                        SELECT @device_cost = cost
                        FROM device
                        WHERE type = @device_path_1

                        SET @current_cost = @current_cost + @device_cost + @path_cost
                    END
                    -- If previous device are different, add two different paths and device costs
                    ELSE
                    BEGIN
                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_1_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_1)
                        
                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @device_path_1_prev) AND (output_device = @device_path_1)

                        SELECT @device_cost = cost
                        FROM device
                        WHERE type = @device_path_1

                        SET @current_cost = @current_cost + @device_cost + @path_cost

                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_2_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_2)

                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                        SET @current_cost = @current_cost + @path_cost
                    END
                END
                -- When the devices are different
                ELSE
                BEGIN
                    -- Does the other path rejoin with my current device?
                    IF EXISTS (SELECT 1 FROM #path_comparison_2 WHERE path_2_devices = @device_path_1)
                    BEGIN
                        WHILE (@device_path_1 != @device_path_2)
                        BEGIN
                            SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_2_prev)
                            SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_2)
                            
                            SELECT @path_cost = cost
                            FROM path
                            WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                            SELECT @device_cost = cost
                            FROM device
                            WHERE type = @device_path_2
                            
                            SET @current_cost = @current_cost + @device_cost + @path_cost

                            SET @device_path_2_prev = @device_path_2

                            DELETE FROM #path_comparison_2
                            WHERE path_2_devices = @device_path_2

                            SELECT TOP 1 @device_path_2 = path_2_devices
                            FROM #path_comparison_2
                        END
                        
                        -- Add same Device, different paths to cost
                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_1_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_1)

                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                        SELECT @device_cost = cost
                        FROM device
                        WHERE type = @device_path_1

                        SET @current_cost = @current_cost + @device_cost + @path_cost

                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_2_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_2)

                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                        SET @current_cost = @current_cost + @path_cost
                    END
                    -- Does the same as previous loop but for other path
                    ELSE IF EXISTS (SELECT 1 FROM #path_comparison_1 WHERE path_1_devices = @device_path_2)
                    BEGIN
                        WHILE (@device_path_1 != @device_path_2)
                        BEGIN
                            SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_1_prev)
                            SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_1)
                            
                            SELECT @path_cost = cost
                            FROM path
                            WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                            SELECT @device_cost = cost
                            FROM device
                            WHERE type = @device_path_1
                            
                            SET @current_cost = @current_cost + @device_cost + @path_cost

                            SET @device_path_1_prev = @device_path_1

                            DELETE FROM #path_comparison_1
                            WHERE path_1_devices = @device_path_1

                            SELECT TOP 1 @device_path_1 = path_1_devices
                            FROM #path_comparison_1
                        END
                        
                        -- Add same Device, different paths to cost
                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_1_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_1)

                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                        SELECT @device_cost = cost
                        FROM device
                        WHERE type = @device_path_1

                        SET @current_cost = @current_cost + @device_cost + @path_cost

                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_2_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_2)

                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                        SET @current_cost = @current_cost + @path_cost
                    END

                    -- If previous device are different, add two different paths and two device costs
                    ELSE
                    BEGIN
                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_1_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_1)
                        
                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                        SELECT @device_cost = cost
                        FROM device
                        WHERE type = @device_path_1

                        SET @current_cost = @current_cost + @device_cost + @path_cost

                        SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_2_prev)
                        SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_2)

                        SELECT @path_cost = cost
                        FROM path
                        WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                        SELECT @device_cost = cost
                        FROM device
                        WHERE type = @device_path_2

                        SET @current_cost = @current_cost + @device_cost + @path_cost
                    END

                END

                -- Remove top row of Comparison Tables
                DELETE FROM #path_comparison_1
                WHERE path_1_devices = @device_path_1

                DELETE FROM #path_comparison_2
                WHERE path_2_devices = @device_path_2

                -- Update device_path_prev
                SET @device_path_1_prev = @device_path_1
                SET @device_path_2_prev = @device_path_2

                -- Update comparison_rows for while loop condition
                SELECT @comparison_rows_1 = COUNT(*)
                FROM #path_comparison_1
                -- Update comparison_rows for while loop condition
                SELECT @comparison_rows_2 = COUNT(*)
                FROM #path_comparison_2
            END

            -- If one comparison table is empty, finish calculating cost of other table
            WHILE (@comparison_rows_1 != 0)
            BEGIN
                
                SELECT TOP 1 @device_path_1 = path_1_devices
                FROM #path_comparison_1
                
                SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_1_prev)
                SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_1)

                SELECT @path_cost = cost
                FROM path
                WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                SELECT @device_cost = cost
                FROM device
                WHERE type = @device_path_1

                SET @current_cost = @current_cost + @device_cost + @path_cost

                -- Remove top row of Comparison Tables
                DELETE FROM #path_comparison_1
                WHERE path_1_devices = @device_path_1

                -- Update device_path_prev
                SET @device_path_1_prev = @device_path_1

                -- Update comparison_rows for while loop condition
                SELECT @comparison_rows_1 = COUNT(*)
                FROM #path_comparison_1
            END
            WHILE (@comparison_rows_2 != 0)
            BEGIN

                SELECT TOP 1 @device_path_2 = path_2_devices
                FROM #path_comparison_2
                
                SELECT @path_input_id = device_id FROM device WHERE (type = @device_path_2_prev)
                SELECT @path_output_id = device_id FROM device WHERE (type = @device_path_2)

                SELECT @path_cost = cost
                FROM path
                WHERE (input_device = @path_input_id) AND (output_device = @path_output_id)

                SELECT @device_cost = cost
                FROM device
                WHERE type = @device_path_2

                SET @current_cost = @current_cost + @device_cost + @path_cost

                -- Remove top row of Comparison Tables
                DELETE FROM #path_comparison_2
                WHERE path_2_devices = @device_path_2

                -- Update device_path_prev
                SET @device_path_2_prev = @device_path_2

                -- Update comparison_rows for while loop condition
                SELECT @comparison_rows_2 = COUNT(*)
                FROM #path_comparison_2
            END


            SET @comparison_path_var =  CAST(CONVERT(NVARCHAR(MAX), @current_path) + CHAR(13) + CHAR(10) + CONVERT(NVARCHAR(MAX), @comparison_path_var) AS NVARCHAR(MAX))
            SET @comparison_path_var = REPLACE(@comparison_path_var , '-', '->')
            -- Add Solution to completed
            INSERT INTO #completed_multiple_path_list(multiple_path_description , cost)
            SELECT @comparison_path_var, @current_cost


            -- Update temporary_rows for while loop condition
            SELECT @temporary_rows = COUNT(*)
            FROM #temporary_path_list
        END

        -- Update completed_rows for while loop condition
        SELECT @completed_rows = COUNT(*)
        FROM #completed_path_list

    
    END

    SELECT TOP 5 multiple_path_description, cost
    FROM #completed_multiple_path_list
    ORDER BY cost ASC

END
GO


/*
--DEBUG Message
PRINT 'The previous devices: ' + CAST(@device_path_1_prev AS NVARCHAR(10)) + ' , ' + CAST(@device_path_2_prev AS NVARCHAR(10));
PRINT 'The current devices: ' + CAST(@device_path_1 AS NVARCHAR(10)) + ' , ' + CAST(@device_path_2 AS NVARCHAR(10));
PRINT 'The current cost: ' + CAST(@current_cost AS NVARCHAR(5));
*/