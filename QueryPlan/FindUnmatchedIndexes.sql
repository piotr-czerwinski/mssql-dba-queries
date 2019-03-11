	-- find query whiuch skips ffiltered index due to general parameter
    --https://sqlblogcasts.com/blogs/sqlandthelike/archive/2011/11/29/execution-plan-warnings-the-final-chapter.aspx
	WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
    SELECT  st.text,
            qp.query_plan
    FROM    (
        SELECT  TOP 500000 *
        FROM    sys.dm_exec_query_stats
        ORDER BY total_worker_time DESC
    ) AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
    WHERE qp.query_plan.value('count(//p:UnmatchedIndexes)', 'int') > 0 ;