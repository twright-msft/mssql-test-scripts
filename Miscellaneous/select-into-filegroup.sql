--
-- SELECT INTO now supports loading a table into a filegroup other than a default filegroup of the user using the ON keyword
--

CREATE DATABASE FilegroupTest
go

USE FilegroupTest
go

CREATE TABLE t (id INT)
go

INSERT INTO t VALUES (1), (2), (3)
go

ALTER DATABASE FilegroupTest ADD FILEGROUP FG2;
ALTER DATABASE FilegroupTest
ADD FILE
(
	NAME='FG2_Data',
	--FILENAME = '/var/opt/mssql/data/FilegroupTest_Data1.mdf' -- Linux
	FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\FilegroupTest_Data1.mdf' -- Windows	
)
TO FILEGROUP FG2;
GO

SELECT *  INTO [dbo].[FactResellerSalesXL] ON FG2 from [dbo].t
go

SELECT * FROM [FactResellerSalesXL] -- expect 1,2,3
go

-- Expect FG2 as the filegroup
SELECT d.name AS FileGroup
 FROM sys.filegroups d
 JOIN sys.indexes i
   ON i.data_space_id = d.data_space_id
 JOIN sys.tables t
   ON t.object_id = i.object_id
WHERE i.index_id<2                     -- could be heap or a clustered table
 AND t.name= 'FactResellerSalesXL'
go


-- Cleanup
USE master
go

DROP DATABASE FilegroupTest
go
