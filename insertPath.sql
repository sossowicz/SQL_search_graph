-- insert Path Stored Procedure
-- Path/Edges are inserted to the Path Table
CREATE OR ALTER PROCEDURE insertPath
    @cost INT,
    @input_device INT,
    @output_device INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dbo.path WHERE (input_device = @input_device AND output_device = @output_device) OR (input_device = @output_device AND output_device = @input_device))

	BEGIN
		INSERT INTO dbo.path (cost, input_device, output_device)
		VALUES (@cost, @input_device, @output_device);
	    
		PRINT 'New row inserted into PATH.';
	END
	ELSE
    BEGIN
        PRINT 'Duplicate row ignored.';
    END
END
