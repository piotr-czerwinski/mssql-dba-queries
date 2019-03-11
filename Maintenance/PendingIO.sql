-- pending io operations IO, ie saving to log file
-- by https://sqlperformance.com/2013/11/sql-performance/transaction-log-monitoring
SELECT
	COUNT (*) AS [PendingIOs],
	DB_NAME ([vfs].[database_id]) AS [DBName],
	[mf].[name] AS [FileName],
	[mf].[type_desc] AS [FileType],
	SUM ([pior].[io_pending_ms_ticks]) AS [TotalStall]
FROM sys.dm_io_pending_io_requests AS [pior]
JOIN sys.dm_io_virtual_file_stats (NULL, NULL) AS [vfs]
	ON [vfs].[file_handle] = [pior].[io_handle]
JOIN sys.master_files AS [mf]
	ON [mf].[database_id] = [vfs].[database_id]
	AND [mf].[file_id] = [vfs].[file_id]
WHERE
   [pior].[io_pending] = 1
GROUP BY [vfs].[database_id], [mf].[name], [mf].[type_desc]
ORDER BY [vfs].[database_id], [mf].[name];
