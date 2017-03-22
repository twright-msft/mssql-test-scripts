-- Connect to the SQL Server instance on Linux
USE master
go

-- Make sure the master database has a database master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'AnyStrongPassword123'
go

-- Re-create the server certificate from the file you copied from Windows
-- The wonky 'c:\' syntax is a bug that is being fixed! :)
CREATE CERTIFICATE MyServerCert FROM FILE = 'c:\var\opt\mssql\data\MyServerCert.cer'  
WITH PRIVATE KEY (  
	FILE = 'c:\var\opt\mssql\data\MyServerCert-PrivateKey.pvk',  
	DECRYPTION BY PASSWORD = 'AnotherStrongPassword123'  
)  
go
	
-- Restore the database backup 
RESTORE DATABASE TestDB FROM DISK = N'/var/opt/mssql/data/TestDB.bak' 
	WITH FILE = 1,  
	MOVE N'TestDB' TO N'/var/opt/mssql/data/TestDB.mdf',  
	MOVE N'TestDB_log' TO N'/var/opt/mssql/data/TestDB_log.ldf',
	NOUNLOAD,
	STATS = 5
go

-- Verify that the database is still encrypted. Done!
SELECT
	db.name,
	db.is_encrypted,
	dek.encryption_state,
	dek.key_algorithm,
	dek.key_length
FROM sys.dm_database_encryption_keys dek
INNER JOIN sys.databases db ON db.database_id = dek.database_id
go


-- Cleanup/reset the whole demo 
USE master
go

DROP DATABASE TestDB
go

DROP CERTIFICATE MyServerCert
go

DROP MASTER KEY
go
