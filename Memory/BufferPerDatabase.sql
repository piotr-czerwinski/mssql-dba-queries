    --stats of all cached pages
    --by http://dbadiaries.com/sql-server-how-to-find-buffer-pool-usage-per-database/
	SELECT 
      CASE WHEN database_id = 32767 THEN 'ResourceDB' ELSE DB_NAME(database_id) END AS DatabaseName,
      COUNT(*) AS cached_pages,
      (COUNT(*) * 8.0) / 1024 AS MBsInBufferPool
    FROM
      sys.dm_os_buffer_descriptors
    GROUP BY
      database_id
    ORDER BY
      MBsInBufferPool DESC
    GO