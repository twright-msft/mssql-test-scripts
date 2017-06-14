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

--More realistic example
CREATE TABLE books (id int IDENTITY, title NVARCHAR(max), abstract NVARCHAR(max), 
	CONSTRAINT pk_demo2 PRIMARY KEY (id))

CREATE FULLTEXT INDEX ON books(title,abstract) KEY INDEX pk_demo2

INSERT books VALUES ('The Grapes of Wrath','Steinbeck’s Pulitzer Prize-winning epic of the Great Depression chronicles the Dust Bowl migration of the 1930s and tells the story of one Oklahoma farm family, the Joads.')
INSERT books VALUES ('From Vines to Wines','From planting vines to savoring the finished product, Jeff Cox covers every aspect of growing flawless grapes and making extraordinary wine')
INSERT books VALUES ('War and Peace','War and Peace broadly focuses on Napoleon’s invasion of Russia in 1812 and follows three of the most well-known Russian characters in literature.')
INSERT books VALUES ('Anna Karenina','Anna Karenina is Tolstoy’s classic tale of love and adultery set against the backdrop of Russian high society in St. Petersburg')

--Search across multiple columns
SELECT * FROM books WHERE FREETEXT((title,abstract),'Grapes')
--Search using matching patterns
SELECT * FROM books WHERE CONTAINS((title,abstract),'"Russia*"')
--Return ranked results 
SELECT   k.rank, b.title, b.abstract
FROM     books AS b
         INNER JOIN
         CONTAINSTABLE(books,abstract, 'ISABOUT ("Russia*",
            title WEIGHT(0.5),
            abstract WEIGHT(0.9))', 3) AS k
         ON b.id = K.[KEY];






















-- Insert some binary data and then do full text search on it
CREATE TABLE demo2 (id int IDENTITY, binary_text varbinary(max), binaryType CHAR(12),
	CONSTRAINT pk_demo2 PRIMARY KEY (id))

INSERT INTO demo2 VALUES (convert(VARBINARY(max), 'This is my text'), '.txt')
INSERT INTO demo2 VALUES (convert(VARBINARY(max), 'This is my txt'), '.txt')
INSERT INTO demo2 VALUES (convert(VARBINARY(max), 'The dog went walking down the street'), '.txt')

SELECT * FROM sys.fulltext_document_types
EXEC sp_fulltext_service @action='load_os_resources', @value=1;

CREATE FULLTEXT INDEX ON demo2(binary_text TYPE COLUMN [binaryType]) KEY INDEX pk_demo2

SELECT * FROM demo2
SELECT * FROM demo2 WHERE CONTAINS(binary_text, 'street')