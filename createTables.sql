DROP TABLE IF EXISTS path;
DROP TABLE IF EXISTS device;

CREATE TABLE [dbo].[device]
(
    [device_id] INT IDENTITY (1, 1) NOT NULL, -- int value auto increments by 1 whenever a new device is added
    [type]      NVARCHAR (50) NOT NULL,
    [status]    BIT           NOT NULL, -- MSSQL doesn't have boolean, used bit instead (values are either 1 or 0)
    [cost] INT NOT NULL DEFAULT 1, -- default cost value of device is 1
    [is_source] BIT NOT NULL DEFAULT 0, -- 0 means FALSE, 1 means TRUE
    [is_destination] BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_device_device_id PRIMARY KEY CLUSTERED (device_id)
);
GO

-- Create a new table in factory called 'path' in schema 'dbo'
CREATE TABLE [dbo].[path]
(
    [path_id] INT IDENTITY(1,1) NOT NULL, -- int value auto increments by 1 whenever a new path is added 
    [cost] INT NOT NULL,
    [input_device] INT NOT NULL,
    [output_device] INT NOT NULL,
    CONSTRAINT PK_path_path_id PRIMARY KEY CLUSTERED (path_id),
    --adding foreign key references for input and output device
    CONSTRAINT FK_path_input_device FOREIGN KEY (input_device) REFERENCES device(device_id), 
    CONSTRAINT FK_path_output_device FOREIGN KEY (output_device) REFERENCES device(device_id)
);
GO




