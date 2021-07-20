IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.##tblPerfCount'))
DROP TABLE ##tblPerfCount;
-- When counter type = 272696576 (find delta from two collection points)

IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.##tblPerfCount'))
CREATE TABLE ##tblPerfCount (
       [counter_name] [NVARCHAR](128),
       [retrieval_time] [DATETIME],
       [batch_requests_second] FLOAT NULL,
       );

WHILE 1=1
BEGIN
       INSERT INTO ##tblPerfCount
       SELECT counter_name, GETDATE(), cntr_value AS batch_requests_second
       FROM sys.dm_os_performance_counters pc0 (NOLOCK)
       WHERE counter_name LIKE 'Batch Requests/sec%';

       WAITFOR DELAY '00:00:01'
END;

