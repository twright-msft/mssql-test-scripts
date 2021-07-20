--Run in Controller SQL instance not in Master SQL instance
USE Controller
GO

SELECT last_exception FROM ControlPlaneFsm
SELECT last_exception FROM BigDataClusterFsm