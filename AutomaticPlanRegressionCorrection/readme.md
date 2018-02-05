This is a demonstration of the Automatic Tuning (Automatic Plan Regression Correction or ARPC) feature in SQL Server 2017. This feature is using telemtry from the Query Store feature we launched with Azure SQL Database and SQL Server 2016 to provide built-in intelligence.

This demo is for SQL Server 2017 on Linux using  SQL Server Operations Studio result chart viewer.

This demo assumes:

* You have SQL Server 2017 installed on Linux (requires Developer or Enteprise Edition)
* You have downloaded and installed SQL Server Operations Studio on your client. [Download it!](https://docs.microsoft.com/en-us/sql/sql-operations-studio/download)
* You have the WorldWideImporters .bak file somewhere that SQL Server can access. You can [download WideWorldImporters](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0) if you don't already have it.

In this demo, you will use SQL Operations Studio on your preferred platform to perform the demo to showcase automatic tuning (automatic plan regression correction). NOTE: To connect with SQL Ops Studio you may be connecting with an IP address. If so, be sure to use  <IP Address>:1433 to connect to SQL Server.

1. If you have not already done so, restore the WideWorldImporters database to your SQL Server 2017 instance. The 0_restore_wwi_linux.sql script can be used to restore the database.  Note - you may need to do the following:
    * Copy the .bak file to your Linux server into the /var/opt/mssql directory and run chown mssql:mssql WidwWorldImporters-Full.bak after copying.
    * Change the file path of where the .bak file is located in the script before you run it if you place it somewhere other than /backups.

2. Run the 1_setup.sql script against the WideWorldImporters database.  This will create a couple of stored procedures that will mimic running a report and introducing a regression later in the demo.

3. Run the 2_initalize.sql script to clear the query store and disable auto tune. If you need to restart the demo, you don't need to run setup.sql but you need to run initialize.sql.

4. Open up the following SQL Server script files:

* 3_batchrequests_perf_collector.sql
* 4_reporting_query_simulator.sql
* 5_batch_requests_history.sql
* 6_introduce_regression.sql
* 7_show_recommendations.sql

5. Start the query in 3_batchrequests_perf_collector.sql.  It will just run in the background to collect the rate of batch requests per second into a temp table that will be queried later to show the history of batch request rates.

6. Start the query in 4_reporting_query_simulator.sql. This simulates a bunch of users running a reporting query against SQL Server.  Let this run for about 10 seconds to allow the batchrequests_perf_collector script to collect some batch requests rate perf data.

7. Run the query in 5_batch_requests_history.sql. In the results window of SQL Ops Studio, pick Chart Viewer and change to Time Series type. This shows the historical batches/second rate for the simulated reporting workload.

8. Run the query in 6_introduce_regression.sql.  This will cause a regression in batches per second.

9. Repeat #7 and observe the performance degradation.  The batch requests/second will show a drop.

10. Run the query in 7_show_recommendations.sql. Notice the time difference under the reason column and value of state_transition_reason which should be AutomaticTuningOptionNotEnabled. This means we found a regression but are recommending it only, not automatically fixing it. The script column shows a query that could be used to fix the problem.

11. Open up and run 8_enable_auto_tune.sql. This will set FORCE_LAST_GOOD_PLAN to ON.  Now regressions like this will be automatically corrected by reverting to a previously good plan.

12. Cancel query in  3_batchrequests_perf_collector.sql. Start it again. Also stop 4_reporting_query_simulator.sql.

13. Repeat steps 6-10.

In SQL Ops Studio Chart Viewer you will see the batch requests/sec dip but within a second go right back up. This is because SQL Server detected the regression and automatically reverted to "last known good" or the last known good query plan as found in the Query Store. Note in the output of recommendations.sql the state_transition_reason now says LastGoodPlanForced.