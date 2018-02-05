USE WideWorldImporters
GO
SELECT reason, score,
	JSON_VALUE(STATE, '$.currentValue') STATE,
	JSON_VALUE(STATE, '$.reason') state_transition_reason,
    JSON_VALUE(details, '$.implementationDetails.script') script,
    planForceDetails.*
FROM sys.dm_db_tuning_recommendations
  CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] INT '$.queryId',
            [new plan_id] INT '$.regressedPlanId',
            [forcedPlanId] INT '$.forcedPlanId'
          ) AS planForceDetails;
GO