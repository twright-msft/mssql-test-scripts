SELECT SERVERPROPERTY('IsNonGolden') -- RESULT: NULL
SELECT SERVERPROPERTY('IsFullTextInstalled') -- RESULT: 1
SELECT FULLTEXTSERVICEPROPERTY('VerifySignature') -- RESULT: 1
SELECT FULLTEXTSERVICEPROPERTY('LoadOsResources') -- RESULT: 0

EXEC sp_help_fulltext_system_components 'filter' -- 104 rows

DECLARE @LCID INT, @CNT INT 
DECLARE MYCURSOR CURSOR FOR SELECT [LCID]  FROM sys.fulltext_languages 
OPEN MYCURSOR FETCH NEXT FROM MYCURSOR INTO @LCID 
WHILE @@FETCH_STATUS = 0 
BEGIN 
	SELECT @CNT = COUNT(*) FROM sys.dm_fts_parser('"MICROSOFT SQL SERVER VNext ROCKS. INSTALL-IT-IMMEDIATELY!!!"', @LCID,0,0) 
	IF @CNT =0 
	BEGIN 
		SELECT 'FAIL' 
		BREAK 
	END 
	FETCH NEXT FROM MYCURSOR INTO @LCID 
END 
SELECT 'PASS' 
CLOSE MYCURSOR 
DEALLOCATE MYCURSOR
-- RESULT:
-- 1st TIME - ERROR: An error has occurred during the full-text query. Common causes include: word-breaking errors or timeout, FDHOST permissions/ACL issues, service account missing privileges, malfunctioning IFilters, communication channel issues with FDHost and sqlservr.exe, etc.
-- 2nd TIME+ - PASS

CREATE DATABASE test
GO
USE test

CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT
CREATE TABLE test (id int IDENTITY, text NVARCHAR(max), 
	CONSTRAINT pk_test PRIMARY KEY (id))
INSERT test VALUES ('Hello this is full text')
CREATE FULLTEXT INDEX ON test(text) KEY INDEX pk_test
SELECT * from TEST WHERE CONTAINS(text, 'full')
-- RESULT: PASS

DECLARE @table_id int =  OBJECT_ID(N'test');
EXEC sp_fulltext_keymappings @table_id
-- RESULT: 1, 1

SELECT table_id, status FROM sys.fulltext_index_fragments  
-- RESULT status = 4 - is that good?

ALTER FULLTEXT CATALOG ftCatalog REORGANIZE;  
-- RESULT: PASS

SELECT * FROM sys.fulltext_index_catalog_usages
-- RESULT: PASS

SELECT * FROM sys.fulltext_index_columns 
-- RESULT: PASS

SELECT * FROM sys.fulltext_indexes 
-- RESULT: PASS

SELECT * FROM sys.dm_fts_index_keywords( DB_ID('test'), OBJECT_ID('dbo.test') ) 
-- RESULT: PASS

SELECT * FROM sys.dm_fts_index_keywords_by_document(db_id('test'), object_id('dbo.test'));  
-- RESULT: PASS

SELECT * FROM sys.dm_fts_index_population
-- RESULT: PASS

SELECT database_id, table_id, COUNT(*) AS batch_count FROM sys.dm_fts_outstanding_batches GROUP BY database_id, table_id ;  
-- RESULT: PASS, no outstanding batches

SELECT * FROM sys.dm_fts_active_catalogs
-- RESULT: PASS

SELECT * FROM sys.dm_fts_fdhosts
-- RESULT: PASS

SELECT * FROM sys.dm_fts_index_keywords_by_property( DB_ID('test'), OBJECT_ID('test') ) 
--RESULT: No results.  Expected?

SELECT * FROM sys.dm_fts_index_keywords_position_by_document( DB_ID('test'), OBJECT_ID('test') ) 
-- RESULT: PASS

SELECT * FROM sys.dm_fts_memory_buffers
--RESULT: No results.  Expected?

SELECT * FROM sys.dm_fts_memory_pools
-- RESULT: PASS

SELECT * FROM sys.dm_fts_population_ranges
--RESULT: No results.  Expected?

SELECT * FROM sys.dm_fts_semantic_similarity_population
--RESULT: PASS


sp_fulltext_service 'verify_signature', '1'
SELECT FULLTEXTSERVICEPROPERTY('VerifySignature') -- RESULT: 0
--RESULT: PASS, value changed from 1 to 0


CREATE TABLE test2 (id int IDENTITY, binary_text varbinary(max), text NVARCHAR(max),
	CONSTRAINT pk_test2 PRIMARY KEY (id))
INSERT INTO test2 VALUES (convert(VARBINARY(max), 'This is my txt'), N'.txt')
CREATE FULLTEXT INDEX ON test2(text) KEY INDEX pk_test2
SELECT * FROM test2 WHERE CONTAINS(text, N'txt')
--RESULT: PASS

sp_fulltext_service 'pause_indexing', '1'
--RESULT: SUCCEEDED, but if I run SELECT * FROM sys.dm_fts_active_catalogs then is_paused = 0 for ftCatalog.  Is that expected? How do I verify that in fact the FTS service is paused?

sp_fulltext_service 'pause_indexing', '0'
--RESULT: SUCCEEDED

EXEC sp_fulltext_table 'dbo.test2', 'Start_background_updateindex';  
--RESULT: Warning: Full-text auto propagation is currently enabled for table or indexed view 'dbo.test2'.  Expected?

EXEC sp_help_fulltext_catalogs 'ftCatalog'
--RESULT: PASS, STATUS=0, NUMBER_FULLTEXt_TABLES =2 (test and test2)

EXEC sp_help_fulltext_catalog_components
--RESULT: No results

DECLARE @mycursor CURSOR;  
EXEC sp_help_fulltext_catalogs_cursor @mycursor OUTPUT, 'ftCatalog';  
FETCH NEXT FROM @mycursor;  
WHILE (@@FETCH_STATUS <> -1)  
   BEGIN  
      FETCH NEXT FROM @mycursor;  
   END  
CLOSE @mycursor;  
DEALLOCATE @mycursor;  
GO  
--RESULT: PASS

EXEC sp_help_fulltext_columns 'test2'
--RESULT: PASS

EXEC sp_help_fulltext_system_components 'all'
--RESULT: PASS, 157 rows

EXEC sp_help_fulltext_tables 'ftCatalog'
--RESULT: PASS, 2 rows (test and test2 tables)

/* - Working out the plan on semantic search.  Current proposala is to include the .mdf/.ldf files in the mssql-server-fts package on Linux and not change anything for the Windows side.
Once we have the DB files attached, these should just work
EXEC sp_fulltext_semantic_register_language_statistics_db  
    [ @dbname = ] ‘database_name’;  
GO  
EXEC sp_fulltext_semantic_unregister_language_statistics_db;  
GO
*/  

DECLARE @table_id int =  OBJECT_ID(N'test2');
EXEC sp_fulltext_pendingchanges @table_id
--RESULT:PASS, no rows

EXEC sys.sp_fulltext_load_thesaurus_file 1033
GO  
--RESULT: completed successfully, how to verify?  No errors in errorlog.

sp_fulltext_database 'enable'
--RESULT: Completed successfully.

sp_fulltext_database 'disable'
--RESULT: Completed successfully.

EXEC sp_fulltext_catalog 'ftCatalog', 'rebuild';
--RESULT: Completed successfully

SELECT FULLTEXTCATALOGPROPERTY('ftCatalog','ItemCount');
--RESULT: PASS

CREATE FULLTEXT STOPLIST myStopList FROM SYSTEM STOPLIST;
--RESULT: PASS

SELECT * FROM sys.fulltext_stopwords
--RESULT: PASS, 15,829 rows

SELECT count(*) AS word_count, language_id AS lang_id FROM sys.fulltext_stopwords
GROUP BY language_id
ORDER BY word_count desc
--RESULT: PASS, 46 languages

SELECT * FROM sys.fulltext_stoplists
--RESULT: PASS, myStopList exists


--GUI TESTS
-- 1) Use SSMS to create ftCatalog2.  RESULT: PASS
-- 2) Use SSMS to edit the properties of ftCatalog2 to add test and test2 to the index, change the accent, and default catalog properties.  RESULT: PASS
-- 3) Use SSMS to edit the properties of ftCatalog2 to add a recurring schedule. RESULT: FAIL.  Missing SQL Server agent?  Need to doc.
-- 4) Use SSMS to edit the properties of ftCatalog2 to add a idle CPU schedule.  RESULT: PASS.
-- 5) Use SSMS to rebuild ftCatalog2. RESULT: PASS
-- 6) Use SSMS to delete ftCatalog2.  RESULT: PASS
-- 7) Use SSMS to delete myStopList.  RESULT: PASS
-- 8) Use SSMS Full-text Index Wizard to create a new index using STATISTICAL_SEMANTICS.  RESULT: FAIL.  ERROR: A semantic language statistics database is not registered.  Full-text indexes using 'STATISTICAL_SEMANTICS' cannot be created or populated.  #41209
-- 9) Use SSMS Full-text Index Wizard to create a new index and catalog at the same time.  RESULT: PASS.
-- 10) Use SSMS Full-text Index Wizard to create a new index using an existing catalog.  RESULT: PASS.
-- 11) Use SSMS to disable Full-text Index.  RESULT: PASS
-- 12) Use SSMS to enable Full-text Index.  RESULT: PASS
-- 13) Use SSMS to start full repopulation of an index.  RESULT: PASS
-- 14) Use SSMS to start incremental repopulation of an index.  RESULT: PASS
-- 15) Use SSMS to disable change tracking.  RESULT: PASS
-- 16) Use SSMS to change to track changes manually.  RESULT: PASS
-- 17) Use SSMS to change to track changes automatically.  RESULT: PASS
-- 18) Use SSMS to apply tracked changes.  RESULT: PASS
-- 19) Use SSMS to change full text properties like enabled/disabled and kick off an index repopulate.  RESULT: PASS

















