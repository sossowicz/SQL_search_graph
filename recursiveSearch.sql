--this procedure runs a recursive search from a specified source device to every other device and returns a table displaying
--up to the top 5 lowest cost paths from specified source device to destination device 

--NOTE when calculating the total cost of the paths, the cost of the source and destination device is not included 

-- Create a new stored procedure called 'RecursiveSearch' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE SPECIFIC_SCHEMA = N'dbo'
    AND SPECIFIC_NAME = N'RecursiveSearch'
    AND ROUTINE_TYPE = N'PROCEDURE'
)
DROP PROCEDURE dbo.RecursiveSearch
GO

-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.RecursiveSearch
    @source_device int = 0, /*default value*/
    @destination_device int = 0 /*default_value*/

AS 
BEGIN

--using temporary tables to filter out inactive devices (devices whose status is set to 0)

    --if temporary tables already exist, remove them
    IF OBJECT_ID('tempDB..##active_outputs', 'U') IS NOT NULL
        DROP TABLE ##active_outputs

    IF OBJECT_ID('tempDB..##active_paths', 'U') IS NOT NULL
        DROP TABLE ##active_paths

    IF OBJECT_ID('tempDB..##active', 'U') IS NOT NULL
    DROP TABLE ##active

    --creating temporary table active_outputs
    --This table takes entries from the path table where the output device status is set to 1 (operational)
    SELECT path.*
    INTO ##active_outputs
    FROM path
    INNER JOIN device ON path.output_device = device.device_id
    WHERE device.status = 1;

    --creating temporary table active_paths
    --This table contains entries from ##active_outputs table where the input device status is set to 1 (operational)
    --All the entries in this table are paths where the input and output device status is set to 1
    SELECT ##active_outputs.*, dbo.device.cost as input_cost
    INTO ##active_paths
    FROM ##active_outputs
    INNER JOIN device ON ##active_outputs.input_device = device.device_id
    WHERE device.status = 1;

    --creating temporary table active
    --same as table ##active_paths, with an extra column for device names
    SELECT ##active_paths.*, dbo.device.type as output_device_name
    INTO ##active
    FROM ##active_paths
    INNER JOIN device ON ##active_paths.output_device = device.device_id;

    DECLARE @src_name VARCHAR(50)

    --get the name/type of the source device, used for building the device_name_path 
    SELECT @src_name = device.type
    FROM device 
    WHERE device.device_id = @source_device;

    --path_list is the temporary table used to display results
    WITH path_list AS
    (
        --path list headers 
        SELECT 
            output_device, 
            CAST(CONVERT(VARCHAR(MAX),input_device) + '->' + CONVERT(VARCHAR(MAX),output_device) AS VARCHAR(MAX)) device_id_path, 
            CAST(CONVERT(VARCHAR(MAX),@src_name) + '->' + CONVERT(varchar,output_device_name) AS VARCHAR(MAX)) device_name_path,  
            cost AS path_cost,
            CAST(CONVERT(VARCHAR(MAX), input_device) + ',' + CONVERT(VARCHAR(MAX), output_device) AS VARCHAR(MAX)) AS visited_nodes -- ADDED: Tracking visited nodes

        FROM ##active

        --base query, specifies which device to start search from 
        WHERE input_device = @source_device

        --recursive step
        UNION ALL

        SELECT 
            p.output_device, --current device travelled to
            CAST(CONVERT(VARCHAR(MAX),t.device_id_path) + '->' + CONVERT(VARCHAR(MAX),p.output_device) as VARCHAR(MAX)) AS device_id_path, --keep record of devices traversed
            CAST(CONVERT(VARCHAR(MAX),t.device_name_path) + '->' + CONVERT(VARCHAR(MAX),output_device_name) AS VARCHAR(MAX)) AS device_name_path,  
            path_cost + p.cost + p.input_cost AS path_cost, --accumulate path cost
            CAST(t.visited_nodes + ',' + CONVERT(VARCHAR(MAX),p.output_device) as VARCHAR(MAX)) AS visited_nodes -- ADDED: Append current node to visited nodes
        FROM ##active p
        INNER JOIN path_list t ON p.input_device = t.output_device 
        WHERE CHARINDEX(CONVERT(VARCHAR(MAX), p.output_device), t.visited_nodes) = 0  -- ADDED: Exclude paths that revisit nodes
    )

    --display top 5 shortest paths to destination device and their respective costs 
    SELECT DISTINCT TOP 5 device_id_path, device_name_path, path_cost
    FROM path_list 
    WHERE output_device = @destination_device
    ORDER BY path_cost
    OPTION (MAXRECURSION 32000)


    SELECT * FROM ##active;
    SELECT * FROM ##active_paths;


    /*
    --remove temporary tables
    DROP TABLE ##active_outputs
    DROP TABLE ##active_paths
    DROP TABLE ##active
    */

END
GO