-- Demo of Graph DB support in SQL Server 2017
--
-- Why Graph?
-- The rapid growth & complexity of data (e.g. social graphs, health & insurance data, etc.)
-- can cause challenges with optimal schema and query design
-- Graph support in SQL Server 2017 addresses this by introducing simple constructs of nodes and relationships
-- that enable sophisticated modeling.
--
-- SQL Server 2017 and Azure SQL Database now has fully integrated Graph extensions,
-- enabling users to define graph schema with the help of graph objects.
--
-- T-SQL language extensions help users find patterns and use multi-hop navigation.
-- Multi-hop navigation and join-free pattern matching
-- Queries can lookup against existing SQL database tables and JOIN with graph nodes/edges. 
-- Works out of the box: Column store, 'R', Python, Always On, Security & Compliance,
-- backup/restore, import/export, existing tools
--
--
-- Let us simulate an assembly line in a factory that looks like this:
-- The '--' lines are EDGES connecting the NODES.
--
--                        PRODUCERS
--    FACTORY ------------------------------- PRODUCT
--      |                                         |
--      |      PART_OF              ASSEMBLIES    |
--      +------------------+   +------------------+
--                         |   |
--                         |   |                     
--   SENSOR ------------- MACHINE ------------ FAILURE
--            MONITORS       |      REPORTS      |
--                           |                   |
--                           |                   |
--                           +-------------------+
--                                  AFFECTS
--

USE [master];
GO

ALTER DATABASE [Machines] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE IF EXISTS [Machines];
GO
CREATE DATABASE [Machines];
GO
USE [Machines];
GO

-- Create the Nodes: machine, sensor, factory, product and failure
-- Note new T-SQL construct: "AS NODE"
-- Even if nodes and edges are created in different schemas, they still belong to a single graph.
CREATE TABLE MACHINE (ID INTEGER, NAME VARCHAR(50), MODEL INTEGER) AS NODE;
CREATE TABLE SENSOR (ID INTEGER, NAME VARCHAR(100)) AS NODE;
CREATE TABLE FACTORY (ID INTEGER, FACTORY_NAME VARCHAR(100), ADDRESS VARCHAR(100)) AS NODE;
CREATE TABLE PRODUCT (PRODUCT_ID INTEGER, PRODUCT_NAME VARCHAR(100)) AS NODE;
CREATE TABLE FAILURE (ID INTEGER, FAILURE_REASON VARCHAR(100), FAILURE_REPORTED_AT DATETIME) AS NODE;

-- Create the edges: monitors, producers, part_of, assemblies, reports and affects
-- Note new T-SQL construct: "AS EDGE"
CREATE TABLE MONITORS(ISWORKING BIT) AS EDGE;
CREATE TABLE PRODUCERS AS EDGE;
CREATE TABLE PART_OF (INSTALLED_ON DATETIME) AS EDGE;
CREATE TABLE ASSEMBLES (STATUS VARCHAR(50)) AS EDGE;
CREATE TABLE REPORTS (ERR_NO INTEGER) AS EDGE;
CREATE TABLE AFFECTS (ERR_NO INTEGER) AS EDGE;

-- INSERT some data into the NODE tables.
-- Inserting into a NODE table is the same as inserting into a regular table. 
INSERT INTO MACHINE VALUES (1,'Chassis Assembly',1111 ),
			(2, 'Axle and Tire Assembly',2222),
			(3, 'Engine Assembly', 3333);

INSERT INTO SENSOR VALUES (1, 'Optic Sensor'), (2, 'Wheel Speed Sensor'), (3, 'Engine Speed Sensor'); 
INSERT INTO FACTORY VALUES (8, 'Munich  Group Plant','Munich');

INSERT INTO PRODUCT VALUES(1, ' 1 Series'),(2, 'Contoso Ltd. 3 Series'), (3, 'Contoso Ltd. 5 Series');

-- failures detected by Wheel speed sensor and airflow meter.
INSERT INTO FAILURE VALUES(1, 'Less Stability under icy or wet driving conditions', '10/20/2016'),
		(2, 'Hesitation and jerking during acceleration', '10/2/2016');

-- INSERT some data into the EDGE tables.
-- When inserting data into an EDGE, you need to specify the 2 nodes this edge connects.
-- i.e. specify the FROM node (the node where this edge starts) and the TO node (the node where this edge ends).
-- You can select the $NODE_ID from the node table and insert into the EDGE table,
-- using an INSERT statement similar to one below: 

-- Connect the 'SENSOR' node to the 'MACHINE' node via the 'MONITORS' edge
INSERT INTO MONITORS VALUES((SELECT $NODE_ID FROM SENSOR WHERE ID = 1), (SELECT $NODE_ID FROM MACHINE WHERE ID =1), 1 );
INSERT INTO MONITORS VALUES((SELECT $NODE_ID FROM SENSOR WHERE ID = 2), (SELECT $NODE_ID FROM MACHINE WHERE ID =2), 1 );

DECLARE @fromNode nvarchar(64), @toNode nvarchar(64)
SELECT @fromNode = S.$NODE_ID FROM SENSOR S WHERE ID = 3
SELECT @toNode = M.$NODE_ID FROM MACHINE M WHERE ID = 3
INSERT INTO MONITORS ($from_id, $to_id, ISWORKING) VALUES (@fromNode, @toNode, 1 );

-- Connect the 'FACTORY' node to the 'PRODUCT' node via the 'PRODUCERS' edge
INSERT INTO PRODUCERS VALUES((SELECT $NODE_ID FROM FACTORY WHERE ID=8),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =1));
INSERT INTO PRODUCERS VALUES((SELECT $NODE_ID FROM FACTORY WHERE ID=8),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =2));
INSERT INTO PRODUCERS VALUES((SELECT $NODE_ID FROM FACTORY WHERE ID=8),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =3));

-- Connect the 'MACHINE' node to the 'FACTORY' node via the 'PART_OF' edge
INSERT INTO PART_OF VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=1),(SELECT $NODE_ID FROM FACTORY WHERE ID =8), '10/10/2000' );
INSERT INTO PART_OF VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=2),(SELECT $NODE_ID FROM FACTORY WHERE ID =8), '09/21/2016');
INSERT INTO PART_OF VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=3),(SELECT $NODE_ID FROM FACTORY WHERE ID =8), '07/30/2016' );

-- Connect the 'MACHINE' node to the 'PRODUCT' node via the 'ASSEMBLES' edge
INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=1),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =1) , 'ACTIVE');
INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=2),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =1) , 'ACTIVE');
INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=3),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =1) , 'ACTIVE');

INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=1),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =2) , 'ACTIVE');
INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=2),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =2) , 'ACTIVE');
INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=3),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =2) , 'ACTIVE');

INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=1),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =3) , 'ACTIVE');
INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=2),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =3) , 'ACTIVE');
INSERT INTO ASSEMBLES VALUES((SELECT $NODE_ID FROM MACHINE WHERE ID=3),(SELECT $NODE_ID FROM PRODUCT WHERE PRODUCT_ID =3) , 'ACTIVE');

-- Connect the 'MACHINE' node to the 'FAILURE' node via the 'REPORTS' edge
INSERT INTO REPORTS VALUES ((SELECT $NODE_ID FROM MACHINE WHERE ID=2),(SELECT $NODE_ID FROM FAILURE WHERE ID =1), 1234);
INSERT INTO REPORTS VALUES ((SELECT $NODE_ID FROM MACHINE WHERE ID=3),(SELECT $NODE_ID FROM FAILURE WHERE ID =2), 456);

-- Connect the 'FAILURE' node to the 'MACHINE' node via the 'AFFECTS' edge
INSERT INTO AFFECTS VALUES ((SELECT $NODE_ID FROM FAILURE WHERE ID = 1),(SELECT $NODE_ID FROM MACHINE WHERE ID=2), 1234);
INSERT INTO AFFECTS VALUES ((SELECT $NODE_ID FROM FAILURE WHERE ID = 2),(SELECT $NODE_ID FROM MACHINE WHERE ID=3), 456);

--
-- Question #1: which sensors are reporting failure and which machines are affected?
-- Traverse graph: Sensor -> Monitors -> Machine -> Reports -> Failure -> Affects -> Machine
--
SELECT S.NAME AS SENSOR, 
	   M.NAME AS MACHINE, 
	   F.FAILURE_REASON, 
	   M1.NAME AFFECTED_MACHINE
FROM SENSOR S, MACHINE M, MONITORS MO, 
	REPORTS R, FAILURE F, AFFECTS A, MACHINE M1
WHERE MATCH(S-(MO)->M-(R)->F-(A)->M1)
GO

--
-- Question #2: which machines that are affected by the failure and production is affected for which products?
-- Traverse graph: Sensor -> Monitors -> Machine -> Reports -> Failure -> Affects -> Machine -> Assemblies -> Product
--
SELECT DISTINCT M.NAME Machine_with_error, 
	   P.PRODUCT_NAME AS Affected_Product
FROM SENSOR S, MONITORS MO, MACHINE M, REPORTS R, 
	FAILURE F, AFFECTS A, MACHINE M1, ASSEMBLES A1, PRODUCT P
WHERE MATCH(S-(MO)->M-(R)->F-(A)->M1-(A1)->P)
GO

--
-- Question #3: which factory produces the product whose production is affected by the machine failure?
-- Traverse graph: Sensor -> Monitors -> Machine -> Reports -> Failure -> Affects -> Machine -> Assemblies -> Product
--                 Product <- Producers <- Factory
--
SELECT DISTINCT P.PRODUCT_NAME AS Affected_Products,
	   FA.FACTORY_NAME AS Producing_Factory
FROM SENSOR O, MONITORS MO, MACHINE M, REPORTS R, FAILURE F, 
AFFECTS A, MACHINE M1, ASSEMBLES A1, PRODUCT P, FACTORY FA, PRODUCERS PP
WHERE MATCH(O-(MO)->M-(R)->F-(A)->M1-(A1)->P<-(PP)-FA)
GO

-- We can also leverage other advanced features of SQL Server such as clustered columnstore indexes on these tables
CREATE CLUSTERED COLUMNSTORE INDEX index_machine ON MACHINE





-- Clean up from demo
DROP TABLE IF EXISTS MACHINE;
DROP TABLE IF EXISTS SENSOR;
DROP TABLE IF EXISTS OPERATOR;
DROP TABLE IF EXISTS FACTORY;
DROP TABLE IF EXISTS PRODUCT;
DROP TABLE IF EXISTS FAILURE;
DROP TABLE IF EXISTS MONITORS;
DROP TABLE IF EXISTS WORKS_FOR;
DROP TABLE IF EXISTS PRODUCERS;
DROP TABLE IF EXISTS PART_OF;
DROP TABLE IF EXISTS ASSEMBLES;
DROP TABLE IF EXISTS REPORTS;
DROP TABLE IF EXISTS AFFECTS;