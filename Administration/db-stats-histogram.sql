--
-- sys.dm_db_stats_histogram
--

CREATE TABLE Country
(Country_ID int IDENTITY PRIMARY KEY,
Country_Name varchar(120) NOT NULL);
INSERT Country (Country_Name) VALUES ('Canada'), ('Denmark'), ('Iceland'), ('Peru');
go

CREATE STATISTICS Country_Stats  
    ON Country (Country_Name) ;
go

SELECT * FROM sys.dm_db_stats_histogram(OBJECT_ID('Country'), 2); -- expect four steps, each with 1 equal_row
go

