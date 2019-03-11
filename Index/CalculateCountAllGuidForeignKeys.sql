-- Calculate count all references to table with guid type od
BEGIN
    CREATE TABLE #tempTable (ParentTName NVARCHAR(200), TName NVARCHAR(200), FKey NVARCHAR(100), RCount BIGINT)

    INSERT INTO #tempTable(ParentTName,TName, FKey)
    SELECT
		pt.name AS ParentTName,
		'['+s.name+'].['+t.NAME+ ']' as TName,
        c.NAME AS ForeignKeyColumn 
    FROM sys.foreign_key_columns AS fk 
    INNER JOIN sys.tables AS t 
        ON fk.parent_object_id = t.object_id 
    INNER JOIN sys.columns AS c 
        ON fk.parent_object_id = c.object_id 
            AND fk.parent_column_id = c.column_id 
			join sys.tables pt
			on pt.object_id = fk.referenced_object_id
	INNER JOIN sys.schemas s on s.schema_id=t.schema_id
	where c.system_type_id = 36; --guid

    --SELECT * FROM #tempTable

    DECLARE tempT CURSOR FOR SELECT TName FROM #tempTable

    DECLARE @tn NVARCHAR(200)

    OPEN tempT

    FETCH NEXT FROM tempT INTO @tn

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC (N'UPDATE #tempTable SET RCount = (SELECT COUNT(*) FROM ' + @tn + ') WHERE TName =''' +  @tn + '''')

        FETCH NEXT FROM tempT INTO @tn
    END 
    CLOSE tempT;
    DEALLOCATE tempT;

	CREATE TABLE #tempGroupedTable (TName NVARCHAR(200), RCount BIGINT);

	INSERT INTO #tempGroupedTable(TName, RCount)
    SELECT
		tt.ParentTName AS TName,
		sum(tt.RCount) ASRCount
    FROM #tempTable as tt Group by(tt.ParentTName);

	DECLARE @countALL int;
	SET @countALL = (SELECT sum(RCount) as Referencji FROM #tempGroupedTable)

	SELECT @countALL as [Reference count],
	  (@countALL * 16 /(1024 * 1024)) as [Size when GUID key (MB)]
	   ,(@countALL * 4 /(1024 * 1024)) as [Size when int key (MB)]
	   ,(@countALL * 12 /(1024 * 1024)) as [Saving (MB)]
	   ;

    SELECT ttg.TName as [Reference name],
	 ttg.RCount as  [Rows count],
	  ttg.RCount * 16 /(1024 * 1024) as  [Size when GUID key (MB)],
	  ttg.RCount * 4 /(1024 * 1024) as  [Size when int key (MB)],
	  ttg.RCount * 12 /(1024 * 1024) as [Saving (MB)],
	  (ttg.RCount*100.0)/@countALL as [Percentage of all references]
	  
	  FROM #tempGroupedTable as ttg  where (ttg.RCount*100.0)/@countALL>1 order by RCount desc;

    DROP TABLE #tempTable
    DROP TABLE #tempGroupedTable
END