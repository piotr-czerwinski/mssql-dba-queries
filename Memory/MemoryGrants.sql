--which query ask for memory grants
--by https://blogs.msdn.microsoft.com/arvindsh/2015/05/06/query-of-the-day-finding-sql-server-queries-with-large-memory-grants/

SELECT r.session_id
    ,mg.granted_memory_kb
    ,mg.requested_memory_kb
    ,mg.ideal_memory_kb
    ,mg.request_time
    ,mg.grant_time
    ,mg.query_cost
    ,mg.dop
    ,(
        SELECT SUBSTRING(TEXT, statement_start_offset / 2 + 1, (
                    CASE
                        WHEN statement_end_offset = - 1
                            THEN LEN(CONVERT(NVARCHAR(MAX), TEXT)) * 2
                        ELSE statement_end_offset
                        END - statement_start_offset
                    ) / 2)
        FROM sys.dm_exec_sql_text(r.sql_handle)
        ) AS query_text
    ,qp.query_plan
FROM sys.dm_exec_query_memory_grants AS mg
INNER JOIN sys.dm_exec_requests r ON mg.session_id = r.session_id
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp
ORDER BY mg.required_memory_kb DESC;

--Find all queries waiting in the memory queue:

SELECT * FROM sys.dm_exec_query_memory_grants where grant_time is null

--Find who uses the most query memory grant:

SELECT mg.granted_memory_kb, mg.session_id, t.text, qp.query_plan
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) AS t
CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp
ORDER BY 1 DESC OPTION (MAXDOP 1)

--Search cache for queries with memory grants:

SELECT t.text, cp.objtype,qp.query_plan
FROM sys.dm_exec_cached_plans AS cp
JOIN sys.dm_exec_query_stats AS qs ON cp.plan_handle = qs.plan_handle
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
WHERE qp.query_plan.exist('declare namespace n="http://schemas.microsoft.com/sqlserver/2004/07/showplan"; //n:MemoryFractions') = 1