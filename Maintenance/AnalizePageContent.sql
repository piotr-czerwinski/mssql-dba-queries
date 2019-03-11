-- Analyze single physical data page
-- more https://www.sqlskills.com/blogs/paul/finding-table-name-page-id/

DECLARE @dbName NVARCHAR(100) = N'TestDB';
DECLARE @tableName NVARCHAR(100) = N'dbo.SanpleTable';
--Id tabeli
--DBCC ind ( @dbName, @tableName, 2)
--GO 

SELECT *
FROM   sys.dm_os_buffer_descriptors 
WHERE Db_name (database_id) = dbName and [is_modified] = 0-- and page_type = 'INDEX_PAGE'
order by page_id;

DBCC TRACEON (3604);
DBCC PAGE (7, 1, 50490, 0); --database_id, file_Id, pageId from query above
DBCC TRACEOFF (3604);
GO

SELECT OBJECT_NAME (130255669); -- m_objId (AllocUnitId.idObj) from page headera from above query
GO

select  *
from      sys.objects
where type_desc = 'SQL_TRIGGER';

select  type_desc,  count(*)
from      sys.objects
group by type_desc;

--select * from sys.objects;

--select * from sys.syscolumns;