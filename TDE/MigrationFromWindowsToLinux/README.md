# tde-migration-demo
Simple demo migrating an encrypted database from SQL Server on Windows to Linux.

## Prerequisites
 * Windows machine running SQL Server
 * Linux machine running SQL Server

## Steps
**01-setup.sql**

   * Connect to SQL Server on Windows (e.g. using SSMS)
   * Create a certificate
   * Create a new database, 'TestDb'
   * Turn on [Transparent Data Encryption](https://msdn.microsoft.com/en-us/library/bb934049.aspx)
   * Back up the database and the certificate to files
  
**02-bash-commands.txt**

   * Copy the database and certificate files to Linux machine
   * ssh to Linux machine
   * chown and chmod files so the mssql account can read/write
  
**03-restore.sql**

   * Connect to SQL Server on Linux (e.g. using SSMS)
   * Re-create the certificate from file
   * Restore the database from file
 
## Useful links
 * [aka.ms/sqldev](aka.ms/sqldev) - Build a simple app with SQL Server in any language, on any platform
 * [msdn.microsoft.com/commandline/wsl/install_guide] (https://msdn.microsoft.com/commandline/wsl/install_guide) - Enable Bash on Windows 10
