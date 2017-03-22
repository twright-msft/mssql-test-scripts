--Run each EXEC  step separately

CREATE DATABASE demo2
GO
USE demo2

CREATE TABLE demoTable (demoData int)

EXEC sp_add_jobstep  
    @job_name = N'Agent Demo Job',  
    @step_name = N'Insert demoData into demoTable',  
    @subsystem = N'TSQL', 
    @database_name = N'demo2', 
    @command = N'INSERT INTO dbo.demoTable VALUES (1)',   
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
   @job_name = N'Agent Demo Job',  
   @schedule_name = N'Run Once';  
GO  
 
EXEC dbo.sp_add_jobserver  
    @job_name = N'Agent Test Job';  
GO
 
USE msdb
EXEC dbo.sp_start_job N'Agent Test Job' ;  
GO

SELECT * FROM demoData