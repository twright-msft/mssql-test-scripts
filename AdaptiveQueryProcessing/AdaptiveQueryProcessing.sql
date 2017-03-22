
----------------------------------------
-- *** Tested on 14.0.304.138     *** --
----------------------------------------
--Restore the database
RESTORE DATABASE WideWorldImportersDW
FROM DISK = '/tmp/WideWorldImportersDW-AQP.bak' -- Change this as needed
   WITH MOVE 'WWI_Primary' TO '/var/opt/mssql/data/WideWorldImportersDW.mdf',  
   MOVE 'WWI_UserData' TO '/var/opt/mssql/data/WideWorldImportersDW_UserData.mdf',  
   MOVE 'WWI_Log' TO '/var/opt/mssql/data/WideWorldImportersDW.ldf',  
   MOVE 'WWIDW_InMemory_Data_1' TO '/var/opt/mssql/data/WideWorldImportersDW_InMemory_Data_1';


USE [WideWorldImportersDW];
GO

SELECT @@VERSION;

------------------------------------------
-- *** Confirm compat level 140     *** --
------------------------------------------
SELECT compatibility_level
FROM sys.databases
WHERE name = 'WideWorldImportersDW';


----------------------------------------
----------------------------------------
-- *** Interleaved Execution Demo *** --
----------------------------------------
----------------------------------------
-- Interleaved execution means that we run a part of the query plan, look at the results and make decisions before completing execution.
-- In the past we have made guesses and assumptions, created a plan and executed it completely.
-- Now we  are being "smart" and making decisions on the fly during execution of the query plan.
-- THIS TRACE FLAG WILL BE REMOVED BY  CTP 2.0.
DBCC TRACESTATUS;
DBCC TRACEOFF(11005, -1) -- Makes sure that interleaved execution is turned off before starting them demo.  Run the query once and then we'll turn on interleaved exectuion.
DBCC TRACESTATUS;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

-- Our "before" state 
-- NOTE: Make sure to enable Include Actual Execution Plan on the query toolbar in SSMS so you can show the query execution plan after executing this query
SELECT  [fo].[Order Key], [fo].[Description], [fo].[Package],
        [fo].[Quantity], [foo].[OutlierEventQuantity]
FROM    [Fact].[Order] AS [fo]
        INNER JOIN [Fact].[WhatIfOutlierEventQuantity]('Mild Recession',
                                            '1-01-2013',
                                            '10-15-2014') AS [foo] ON [fo].[Order Key] = [foo].[Order Key]
                                            AND [fo].[City Key] = [foo].[City Key]
                                            AND [fo].[Customer Key] = [foo].[Customer Key]
                                            AND [fo].[Stock Item Key] = [foo].[Stock Item Key]
                                            AND [fo].[Order Date Key] = [foo].[Order Date Key]
                                            AND [fo].[Picked Date Key] = [foo].[Picked Date Key]
                                            AND [fo].[Salesperson Key] = [foo].[Salesperson Key]
                                            AND [fo].[Picker Key] = [foo].[Picker Key]
        INNER JOIN [Dimension].[Stock Item] AS [si] ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE   [si].[Lead Time Days] > 0;

-- Plan observations:
--		Hover over Table Value Function and notice estimated number of rows - it will be sometehing like 100 estimate and 425,000 actual.
--		Notice the spills - they will show up as warning icons on the Hash Matches and in the Hash Match tooltips.  Spills are cases where we didnt request enough memory and the data was written to disk in TempDB at execution time instead.  
--		This is caused by the bad row count estimation.
--		Hover over the SELECT operation.  Note the amount of memory grant requested.  Should be about 4-6 MB.

DBCC TRACESTATUS;
DBCC TRACEON(11005, -1) -- Turn on interleaved execution!
DBCC TRACESTATUS;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE; -- Make sure to always clear the procedure cache between each run for demo purposes.
GO

-- Our "after" state (with Interleaved execution) 
-- Include Actual Execution Plan
SELECT  [fo].[Order Key], [fo].[Description], [fo].[Package],
        [fo].[Quantity], [foo].[OutlierEventQuantity]
FROM    [Fact].[Order] AS [fo]
        INNER JOIN [Fact].[WhatIfOutlierEventQuantity]('Mild Recession',
                                            '1-01-2013',
                                            '10-15-2014') AS [foo] ON [fo].[Order Key] = [foo].[Order Key]
                                            AND [fo].[City Key] = [foo].[City Key]
                                            AND [fo].[Customer Key] = [foo].[Customer Key]
                                            AND [fo].[Stock Item Key] = [foo].[Stock Item Key]
                                            AND [fo].[Order Date Key] = [foo].[Order Date Key]
                                            AND [fo].[Picked Date Key] = [foo].[Picked Date Key]
                                            AND [fo].[Salesperson Key] = [foo].[Salesperson Key]
                                            AND [fo].[Picker Key] = [foo].[Picker Key]
        INNER JOIN [Dimension].[Stock Item] AS [si] ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE   [si].[Lead Time Days] > 0;

-- Plan observations:
--		Query execution should be noticeably faster - ~ 20%
--		Notice the TVF estimated number of rows - it should change to have the estimated number of rows match the actual number of rows
--		Any spills? - shouldnt be any spills because we more accurately predict the number of actual rows and request the right amount of memory up front
--		Note the memory grant on the SELECT operation.  Should be ~59 MB instead of 4-6 MB.  We are requesting a more appropriate size of memory up front so we don't spill to disk.

---------------------------------------------------
---------------------------------------------------
-- *** Batch-Mode Memory Grant Feedback Demo *** --
---------------------------------------------------
---------------------------------------------------

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

-- Execute this query three times - Similar to the previous demo, each time you run the query look at 
-- the plan to see impact on spills, memory grant size, and run time
--  Each time the performance should improve - the first time because we request a more appropriate memory grant
--	The second time it will improve because we eliminate all spills.
--	First execution time should be about 15 seconds.  2nd time: 5 seconds.  3rd time: 2-3 seconds.
--  Note: there are no trace flags required on this demo.  It is enabled by default.
-- NOTE: Don't take your selection off the query text from one execution to the next.

SELECT [Order Key], [Description], [Package], [Quantity]
FROM    [Fact].[Order] AS [fo]
WHERE [Quantity] >
(SELECT  AVG([foo].[OutlierEventQuantity])
FROM    [Fact].[Order] AS [fo]
    INNER JOIN [Fact].[WhatIfOutlierEventQuantity]('Mild Recession',
                                                    '1-01-2013',
                                                    '10-15-2014') AS [foo] ON [fo].[Order Key] = [foo].[Order Key]
                                                            AND [fo].[City Key] = [foo].[City Key]
                                                            AND [fo].[Customer Key] = [foo].[Customer Key]
                                                            AND [fo].[Stock Item Key] = [foo].[Stock Item Key]
                                                            AND [fo].[Order Date Key] = [foo].[Order Date Key]
                                                            AND [fo].[Picked Date Key] = [foo].[Picked Date Key]
                                                            AND [fo].[Salesperson Key] = [foo].[Salesperson Key]
                                                            AND [fo].[Picker Key] = [foo].[Picker Key]
    INNER JOIN [Dimension].[Stock Item] AS [si] ON [fo].[Stock Item Key] = [si].[Stock Item Key]
WHERE   [si].[Lead Time Days] > 0);


-------------------------------------------
-- *** Batch-Mode Adaptive Join Demo *** --
-------------------------------------------

DROP TABLE IF EXISTS dbo.[t];
CREATE TABLE dbo.[t] ( [a] INT );
CREATE CLUSTERED COLUMNSTORE INDEX [cci] ON [t];
GO

DROP TABLE IF EXISTS dbo.[t1];
CREATE TABLE [t1] ( [a] INT );
CREATE INDEX [nci] ON [t1]([a]);
GO

-- Turn off "Include Actual Execution Plan" so you don't get 
-- a new plan for each insert
INSERT  INTO dbo.[t]
VALUES  ( 1 );
GO 100

INSERT  INTO dbo.[t1]
VALUES  ( 1 ); 
GO 1000

-- Re-enable "Include Actual Execution Plan"

-- Using Batch-Mode Adaptive Joins
DBCC TRACEON(9399,-1);
DBCC TRACEON(9398,-1);
DBCC TRACEON(8666,-1);
DBCC TRACESTATUS;
GO

-- Show the query
SELECT  [t1].[a], [t].[a]
FROM    [t1]
        JOIN [t] ON [t1].[a] = [t].[a]
OPTION  ( RECOMPILE );

-- Key points:
--		In this early build, we show two join alternatives, hash and NL.
--
--		This is a very early build, but in the final build
--		we will have one operator that represents Adaptive Joins.

--		We will track a threshold where, if the build phase rows
--		for the hash join exceeds a value, we will continue with the
--		hash join, but if it is beneath the value, we will switch
--		to using a nested loop join.

--Turn off all trace flags
DBCC TRACEOFF(9399,-1);
DBCC TRACEOFF(9398,-1);
DBCC TRACEOFF(8666,-1);
DBCC TRACESTATUS;