-- Connect to a SQL Server 2016 instance on Windows
-- Create a database for the demo
USE master
go

CREATE DATABASE TestDB
go
 
-- Add some dummy data
USE TestDB
go

CREATE TABLE MyTable (
	id INT IDENTITY(1,1),
	data NVARCHAR(64)
)
	 
INSERT INTO MyTable VALUES ('I love Linux!')
go

-- Enable Transparent Data Encryption (TDE) on TestDB
USE master
go

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SomeStrongPassword123'
go

CREATE CERTIFICATE MyServerCert WITH SUBJECT = 'My DEK Certificate'
go

USE TestDB
go

CREATE DATABASE ENCRYPTION KEY 
	WITH ALGORITHM = AES_256 
	ENCRYPTION BY SERVER CERTIFICATE MyServerCert
go

ALTER DATABASE TestDB SET ENCRYPTION ON
go

-- Verify that the database is encrypted
SELECT
	db.name,
	db.is_encrypted,
	dek.encryption_state,
	dek.key_algorithm,
	dek.key_length
FROM sys.dm_database_encryption_keys dek
INNER JOIN sys.databases db ON db.database_id = dek.database_id
go

-- To move this database to a different SQL Server instance,
-- we need to back up a few things to file:
--  1) The database file itself (.bak)
--  2) The server certificate (.cer)
--  3) The server certificate's private key (.pvk)
USE master
go

BACKUP DATABASE TestDB TO DISK = 'C:\TestDB.bak'
go

BACKUP CERTIFICATE MyServerCert TO FILE = 'C:\MyServerCert.cer' 
WITH PRIVATE KEY (
	FILE = 'C:\MyServerCert-PrivateKey.pvk', 
	ENCRYPTION BY PASSWORD = 'AnotherStrongPassword123'
)
go

-- Now copy the backup, certificate, and private key files to the Linux machine. 
-- I suggest using scp via Bash on Ubuntu on Windows (Windows Subsystem for Linux). 
-- Note, you'll have to "Run as administrator" in order to be able to access the 
-- certificate files.


-- Cleanup/reset the demo 
USE master
go

DROP DATABASE TestDB
go

DROP CERTIFICATE MyServerCert
go

DROP MASTER KEY
go
