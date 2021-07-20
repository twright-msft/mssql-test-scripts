SELECT top 70 counter_name, [retrieval_time],
              CASE WHEN LAG(batch_requests_second,1) OVER (ORDER BY [retrieval_time]) IS NULL THEN  
                     batch_requests_second-batch_requests_second
                     ELSE batch_requests_second - LAG(batch_requests_second,1) OVER (ORDER BY [retrieval_time]) END AS batch_requests_second
FROM ##tblPerfCount
ORDER BY [retrieval_time] DESC
GO