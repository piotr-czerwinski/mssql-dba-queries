-- Calculate rows count with in tables with colum name matching pattarn

DECLARE @columnNamePattern NVARCHAR(100) = '%Sample%' ;
DECLARE @schemaName NVARCHAR(100) = N'dbo';

BEGIN
    CREATE TABLE #tempTable (TName NVARCHAR(100),CName NVARCHAR(200), RCount BIGINT)

    INSERT INTO #tempTable(TName, CName)
    SELECT t.NAME AS TableName,
			min(c.name) as CName
     FROM sys.columns AS c 
	 JOIN sys.tables as t
        ON t.object_id = c.object_id 
    WHERE c.name LIKE @columnNamePattern and c.system_type_id = 36 --guid
	Group by t.name

   -- SELECT * FROM #tempTable

    DECLARE tempT CURSOR FOR SELECT TName FROM #tempTable

    DECLARE @tn NVARCHAR(100)

    OPEN tempT

    FETCH NEXT FROM tempT INTO @tn

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC (N'UPDATE #tempTable SET RCount = (SELECT COUNT(*) FROM [' + @schemaName + '].[' + @tn + ']) WHERE TName =''' +  @tn + '''')

        FETCH NEXT FROM tempT INTO @tn
    END 
    CLOSE tempT;
    DEALLOCATE tempT;

    SELECT * FROM #tempTable order by RCount desc;

	SELECT 
		sum(RCount) as [Rows count],
		(sum(RCount) * 16 /(1024 * 1024)) [Size (MB)] FROM #tempTable
    DROP TABLE #tempTable
END