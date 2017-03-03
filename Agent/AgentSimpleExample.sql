
EXEC sp_add_jobstep  
    @job_name = N'Agent Bug Bash',  
    @step_name = N'Insert Values into Sales',  
    @subsystem = N'TSQL', 
    @database_name = N'SampleDB', 
    @command = N'INSERT INTO dbo.Sales Values (1)',   
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
   @job_name = N'Agent Bug Bash',  
   @schedule_name = N'Run Once';  
GO  
 
EXEC dbo.sp_add_jobserver  
    @job_name = N'Agent Bug Bash';  
GO
 
USE msdb
EXEC dbo.sp_start_job N'Agent Bug Bash' ;  
GO
