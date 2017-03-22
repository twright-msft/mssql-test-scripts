--Create and use a new database
CREATE DATABASE demo
GO
USE demo

--Show state of Full Text Search
SELECT SERVERPROPERTY('IsFullTextInstalled')

EXEC sp_help_fulltext_system_components 'filter'

CREATE FULLTEXT STOPLIST myStopList FROM SYSTEM STOPLIST;

SELECT * FROM sys.fulltext_stopwords WHERE language_id = 1033

SELECT COUNT(*) AS word_count, language_id AS lang_id FROM sys.fulltext_stopwords
GROUP BY language_id
ORDER BY word_count desc

-- Insert some nvarchar data and thend do full text search on it
CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT

CREATE TABLE demo (id int IDENTITY, textData NVARCHAR(max), 
	CONSTRAINT pk_demo PRIMARY KEY (id))

CREATE FULLTEXT INDEX ON demo(textData) KEY INDEX pk_demo

INSERT demo VALUES ('Hello this is full text')
INSERT demo VALUES ('I am running to the store')

SELECT * FROM demo
SELECT * FROM demo WHERE CONTAINS (textData, 'full')
SELECT * FROM demo WHERE FREETEXT (textData, 'run')

-- Insert some binary data and then do full text search on it
CREATE TABLE demo2 (id int IDENTITY, binary_text varbinary(max), binaryType CHAR(12),
	CONSTRAINT pk_demo2 PRIMARY KEY (id))

INSERT INTO demo2 VALUES (convert(VARBINARY(max), 'This is my text'), N'.txt')
INSERT INTO demo2 VALUES (convert(VARBINARY(max), 'This is my txt'), N'.txt')

CREATE FULLTEXT INDEX ON demo2(binary_text TYPE COLUMN [binaryType]) KEY INDEX pk_demo2

SELECT * FROM demo2
SELECT * FROM demo2 WHERE CONTAINS(binary_text, N'text')