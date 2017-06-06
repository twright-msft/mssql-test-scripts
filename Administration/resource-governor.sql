--
-- Resource Governor
-- https://blog.sqlauthority.com/2012/06/04/sql-server-simple-example-to-configure-resource-governor-introduction-to-resource-governor/
-- http://www.databasejournal.com/features/mssql/restricting-io-using-sql-server-2014-resource-governor.html
--

-----------------------------------------------
-- Step 1: Create Resource Pool
-----------------------------------------------
-- Creating Resource Pool for Report Server (deliberately restricted/slow)
CREATE RESOURCE POOL ReportServerPool WITH (MAX_IOPS_PER_VOLUME=50)
GO

-----------------------------------------------
-- Step 2: Create Workload Group
-----------------------------------------------
-- Creating Workload Group for Report Server
CREATE WORKLOAD GROUP ReportServerGroup
USING ReportServerPool ;
GO

-----------------------------------------------
-- Step 3: Create UDF to Route Workload Group
-----------------------------------------------
CREATE FUNCTION dbo.UDFClassifier()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
RETURN 'ReportServerGroup'
END
GO

-----------------------------------------------
-- Step 4: Enable Resource Governer
-- with UDFClassifier
-----------------------------------------------
ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION=dbo.UDFClassifier);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO


-----------------------------------------------------------------------------
-- Tests

USE master  
SELECT * FROM sys.resource_governor_resource_pools  -- expect ReportServerPool
SELECT * FROM sys.resource_governor_workload_groups -- expect ReportServerGroup 
GO  

CREATE DATABASE RGTest
go
USE RGTest
go

DBCC DROPCLEANBUFFERS 
GO
DBCC CHECKDB (master) WITH NO_INFOMSGS; -- this takes a few seconds
GO

-- Confirm that max_iops_per_volume is 50, and that read_io_throttled_total is non-null
SELECT pool_id, name, min_iops_per_volume, max_iops_per_volume, read_io_queued_total,
read_io_issued_total, read_io_completed_total,read_io_throttled_total, read_bytes_total,
read_io_stall_total_ms, read_io_stall_queued_ms, io_issue_violations_total,io_issue_delay_total_ms
FROM   sys.dm_resource_governor_resource_pools
WHERE  name <> 'internal'; 

-- Note: This is a Windows-ism visible on Linux
SELECT * FROM sys.dm_resource_governor_resource_pool_volumes -- expect volume_name = C:\
go



-----------------------------------------------
-- Step 5: Clean Up
-- Run only if you want to clean up everything
-----------------------------------------------
USE master
GO
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL)
GO
ALTER RESOURCE GOVERNOR DISABLE
GO
DROP FUNCTION dbo.UDFClassifier
GO
DROP WORKLOAD GROUP ReportServerGroup
GO
DROP WORKLOAD GROUP PrimaryServerGroup
GO
DROP RESOURCE POOL ReportServerPool
GO
DROP RESOURCE POOL PrimaryServerPool
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO
DROP DATABASE RGTest
go

