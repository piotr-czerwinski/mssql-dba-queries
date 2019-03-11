-- all loaded to chace pages
-- by https://www.mssqltips.com/sqlservertip/2393/determine-sql-server-memory-use-by-database-and-object/
WITH s_obj as (
    SELECT
        OBJECT_NAME(OBJECT_ID) AS name, index_id ,allocation_unit_id, OBJECT_ID
    FROM sys.allocation_units AS au
    INNER JOIN sys.partitions AS p
    ON au.container_id = p.hobt_id
    AND (au.type = 1 
        OR au.type = 3)
    UNION ALL
    SELECT OBJECT_NAME(OBJECT_ID) AS name, index_id, allocation_unit_id, OBJECT_ID
    FROM sys.allocation_units AS au
    INNER JOIN sys.partitions AS p
    ON au.container_id = p.partition_id
    AND au.type = 2
    ),
obj as (
    SELECT
        s_obj.name, s_obj.index_id, s_obj.allocation_unit_id, s_obj.OBJECT_ID, i.name IndexName, i.type_desc IndexTypeDesc
    FROM s_obj
    INNER JOIN sys.indexes i 
    ON i.index_id = s_obj.index_id
    AND i.OBJECT_ID = s_obj.OBJECT_ID
    )
SELECT
    COUNT(*) AS cached_pages_count, COUNT(*)  * 8 AS cached_pages_size_Kb, obj.name AS BaseTableName, IndexName, IndexTypeDesc
FROM sys.dm_os_buffer_descriptors AS bd
INNER JOIN obj
ON bd.allocation_unit_id = obj.allocation_unit_id
INNER JOIN sys.tables t
ON t.object_id = obj.OBJECT_ID
WHERE database_id = DB_ID()

GROUP BY obj.name, index_id, IndexName, IndexTypeDesc
ORDER BY BaseTableName DESC;