RESTORE FILELISTONLY FROM DISK = '/backup/wwi.bak'

RESTORE DATABASE WideWorldImporters FROM DISK = '/backup/wwi.bak'
WITH 
    MOVE 'WWI_Primary' TO '/var/opt/mssql/data/WideWorldImporters.mdf',
    MOVE 'WWI_UserData' TO '/var/opt/mssql/data/WideWorldImporters_UserData.ndf',
    MOVE 'WWI_Log' TO '/var/opt/mssql/log/WideWorldImporters.ldf',
    MOVE 'WWI_InMemory_Data_1' TO '/var/opt/mssql/data/WideWorldImporters_InMemory_Data_1'

SELECT Name FROM sys.databases

USE WideWorldImporters

SELECT * FROM Application.Cities

INSERT INTO Application.Cities 
    (CityName,StateProvinceID, LastEditedBy)
    VALUES ('NYC',1, 1)

SELECT * FROM Application.Cities ORDER BY CityID DESC

DELETE FROM Application.Cities WHERE CityName = 'NYC'