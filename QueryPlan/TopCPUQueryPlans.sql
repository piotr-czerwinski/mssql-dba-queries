--Top Queries by CPU
--https://blog.sqlauthority.com/2014/07/29/sql-server-ssms-top-queries-by-cpu-and-io/

--dbcc freeproccache

SELECT TOP 10 execution_count as [Execution count],
min_worker_time/execution_count/1000 AS [Min CPU Time ms],
max_worker_time/execution_count/1000 AS [Max CPU Time ms],
total_worker_time/execution_count/1000 AS [Avg CPU Time ms],
total_logical_reads/execution_count AS [Avg reads],
Plan_handle
-- ,query_plan
 --,st.text
FROM sys.dm_exec_query_stats AS qs
--CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle)
--cross apply sys.dm_exec_sql_text(qs.plan_handle) st
ORDER BY total_worker_time/execution_count DESC;
GO
