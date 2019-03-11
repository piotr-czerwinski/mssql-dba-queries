-- List tables, where nullable columns withh mostly null values exists (candidates for issparse)
DECLARE @schemaName NVARCHAR(100) = N'dbo';

BEGIN
	CREATE TABLE #nullableColumns (
	TName NVARCHAR(100),
	CName NVARCHAR(200),
	CColumnId int,
	CObjectId int,
	NullCount BIGINT,
	NotNullCount BIGINT,
	Clength smallint)

	INSERT INTO #nullableColumns(TName, CName, CColumnId, CObjectId, Clength)
	SELECT t.NAME AS TableName,
			c.name as CName,
			c.column_id as CColumnId,
			c.object_id as CObjectId,
			c.max_length as Clength
	 FROM sys.columns AS c 
	 JOIN sys.tables as t
		ON t.object_id = c.object_id
	INNER JOIN 
	sys.schemas s on s.schema_id=t.schema_id
	WHERE c.max_length<20 AND c.max_length>1 AND c.is_nullable = 1 AND s.name =@schemaName AND c.is_sparse = 0;

	--select * from #nullableColumns;
    DECLARE nullCounterIterator CURSOR FOR SELECT TName, CName FROM #nullableColumns

    DECLARE @tn NVARCHAR(100)
    DECLARE @cn NVARCHAR(100)

    OPEN nullCounterIterator

    FETCH NEXT FROM nullCounterIterator INTO @tn,@cn

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC (N'UPDATE #nullableColumns SET NullCount = (SELECT COUNT(*) FROM [' + @schemaName + '].[' + @tn + '] WHERE [' + @cn + '] is null) WHERE CName =''' +  @cn + ''' and TName =''' +  @tn + '''')
        EXEC (N'UPDATE #nullableColumns SET NotNullCount = (SELECT COUNT(*) FROM [' + @schemaName + '].[' + @tn + '] WHERE [' + @cn + '] is not null) WHERE CName =''' +  @cn + ''' and TName =''' +  @tn + '''')

        FETCH NEXT FROM nullCounterIterator INTO @tn,@cn
    END 
    CLOSE nullCounterIterator;
    DEALLOCATE nullCounterIterator;

	SELECT *
	INTO #nonClusteredNullableIndexes
	FROM(
	select *
	FROM(
	SELECT
		t.NAME AS TableName,
		i.name as indexName,
		--i.index_id as index_id,
		--i.object_id as indexObject_id,
		col.object_id as ColumnObject_Id,
		col.column_id as Column_Id,
		sum(p.rows) as RowCounts,
		sum(a.total_pages) as TotalPages,
		(sum(a.total_pages) * 8) / 1024.0 as TotalSpaceMB 
	FROM 
		sys.tables t
	INNER JOIN      
		sys.indexes i ON t.OBJECT_ID = i.object_id
	INNER JOIN 
		sys.index_columns ic ON  i.object_id = ic.object_id and i.index_id = ic.index_id		
	INNER JOIN 
		sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
	INNER JOIN 
		sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
	INNER JOIN 
		sys.allocation_units a ON p.partition_id = a.container_id
	WHERE 
		t.NAME NOT LIKE 'dt%' 
		AND i.OBJECT_ID > 255    
		AND i.index_id > 1
		and col.is_nullable = 1	
		and ic.is_included_column = 0
	GROUP BY 
		t.NAME, i.object_id, i.index_id, i.name, col.object_id, col.column_id) tempresult
		INNER JOIN #nullableColumns nc ON nc.CObjectId = tempresult.ColumnObject_Id and nc.CColumnId = tempresult.Column_Id
		) as joined;
	--select * from #nonClusteredNullableIndexes;

    SELECT top 100 tt.TName as Tabela,
	tt.CName as [Column name],
	TT.NotNullCount + TT.NullCount as [Rows count],
	TT.NullCount as [Null values],
	TT.NotNullCount as [Not null values],
	(NullCount*1.0/(NotNullCount+NullCount+1))*100 as [Nulls count percentage],
	tt.Clength  as [Field size (B)],
	(NullCount * Clength)/(1024.0 * 1024.0)  as [Nulls size]
	FROM #nullableColumns as tt
	where (NullCount+NotNullCount) * Clength > 100*1024 -- >100 kB column size
		and NullCount>9*NotNullCount -- Null values more than 9 times not nulls
	order by NullCount * Clength  desc;

	SELECT top 100
	tt.indexName as [Index name],
	tt.TableName as [Table name],
	tt.CName as [Index key],	
	(NullCount*1.0/(NotNullCount+NullCount+1))*100 as [Nulls count percentage],
	tt.RowCounts AS [Rows in leaves],
	tt.TotalPages AS [Total pages count],
	tt.TotalSpaceMB AS [Index size (MB)]
	FROM #nonClusteredNullableIndexes as tt
	where (NullCount+NotNullCount)* Clength > 100*1024 -- >100 kB column size
		and NullCount>9*NotNullCount -- Null values more than 9 times not nulls
		and tt.TotalSpaceMB > 2 -- Indexes of size more than 2 MB
	order by tt.TotalSpaceMB  desc;

	
	SELECT 
	(sum((tt.NullCount+tt.NotNullCount) * tt.Clength))/(1024.0*1024.0) as [All nullable columns size (MB)]
	,(sum(CASE WHEN (tt.NullCount>9*tt.NotNullCount) THEN (tt.NullCount+tt.NotNullCount) * tt.Clength ELSE 0 END))/(1024.0*1024.0) as [Nullable with (>90%) null values size(MB)]
	FROM #nullableColumns as tt;


	select 
	sum(uniqueIndex.indexSpace) as [Indexes on nullable keys]
	,sum(CASE WHEN (uniqueIndex.NullCount>9*uniqueIndex.NotNullCount) THEN uniqueIndex.indexSpace ELSE 0 END) as [With >90% null values (MB)]
	FROM(
	SELECT 
	nc.indexName
	, max(nc.TotalSpaceMB) as indexSpace
	, max(nc.NullCount) as NullCount
	, max(nc.NotNullCount) as NotNullCount
	 FROM #nonClusteredNullableIndexes as nc
	group by nc.indexName) uniqueIndex;

    DROP TABLE #nullableColumns
	DROP TABLE #nonClusteredNullableIndexes
END