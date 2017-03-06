--Run each EXEC  step separately
CREATE DATABASE TestDB
GO

USE TestDB
GO

CREATE TABLE TestTable (TestData int)
GO

USE msdb; 
GO

EXEC sp_add_jobstep  
    @job_name = N'Agent Test Job',  
    @step_name = N'Insert Data into TestTable',  
    @subsystem = N'TSQL', 
    @database_name = N'TestDB', 
    @command = N'INSERT INTO dbo.TestTable VALUES (1)',   
    @retry_attempts = 5,  
    @retry_interval = 5 ;  
GO  
 
EXEC dbo.sp_add_schedule  
    @schedule_name = N'Run Once',  
    @freq_type = 1,  
    @active_start_time = 133000 ;  
USE msdb ;  
GO  
 
EXEC sp_attach_schedule  
   @job_name = N'Agent Test Job',  
   @schedule_name = N'Run Once';  
GO  
 
EXEC dbo.sp_add_jobserver  
    @job_name = N'Agent Test Job';  
GO
 
USE msdb
EXEC dbo.sp_start_job N'Agent Test Job' ;  
GO

--Confirm that a row has been added to the TestData table
SELECT * FROM TestData
