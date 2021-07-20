--A couple of ways to test for if a given SQL Server instance is a BDC master
SELECT TOP(1) 1 FROM sys.dm_cluster_endpoints;
SELECT COUNT(*) FROM sys.dm_cluster_endpoints;