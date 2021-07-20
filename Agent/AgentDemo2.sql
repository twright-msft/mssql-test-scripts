CREATE DATABASE SampleDB ;

USE msdb ;
GO

EXEC dbo.sp_add_job
@job_name = N'Daily SampleDB Backup' ;
GO

EXEC sp_add_jobstep
@job_name = N'Daily SampleDB Backup',
@step_name = N'Backup database',
@subsystem = N'TSQL',
@command = N'BACKUP DATABASE SampleDB TO DISK = \
N"/var/opt/mssql/data/SampleDB.bak” WITH NOFORMAT, NOINIT, \
NAME = "SampleDB-full", SKIP, NOREWIND, NOUNLOAD, STATS = 10',
@retry_attempts = 5,
@retry_interval = 5 ;
GO

EXEC dbo.sp_add_schedule
@schedule_name = N'Daily SampleDB',
@freq_type = 4,
@freq_interval = 1,
@active_start_time = 233000 ;
USE msdb ;
GO

EXEC sp_attach_schedule
@job_name = N'Daily SampleDB Backup',
@schedule_name = N'Daily SampleDB';
GO

EXEC dbo.sp_add_jobserver
@job_name = N'Daily SampleDB Backup',
@server_name = N'(LOCAL)';
GO

EXEC dbo.sp_start_job N'Daily SampleDB Backup';
GO
