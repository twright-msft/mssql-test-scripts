USE master;  
GO  
CREATE DATABASE Test  
ON   
( NAME = Test_dat,  
    FILENAME = 'C:\binn\testdat.mdf',  
    SIZE = 10,  
    MAXSIZE = 50,  
    FILEGROWTH = 5 )  
LOG ON  
( NAME = Test_log,  
    FILENAME = 'C:\binn\testlog.ldf',  
    SIZE = 5MB,  
    MAXSIZE = 25MB,  
    FILEGROWTH = 5MB ) ;  
GO  