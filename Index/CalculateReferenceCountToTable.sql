-- Calculate count of rows that reference provided table (by foreign key)
-- by https://stackoverflow.com/a/12345409

DECLARE @referencedTable NVARCHAR(100) = 'SampleTable' ;
DECLARE @schemaName NVARCHAR(100) = N'dbo';

BEGIN
    CREATE TABLE #tempTable (TName NVARCHAR(100), FKey NVARCHAR(100), RCount BIGINT)

    INSERT INTO #tempTable(TName, FKey)
    SELECT t.NAME AS TableWithForeignKey, 
        c.NAME AS ForeignKeyColumn 
    FROM sys.foreign_key_columns AS fk 
    INNER JOIN sys.tables AS t 
        ON fk.parent_object_id = t.object_id 
    INNER JOIN sys.columns AS c 
        ON fk.parent_object_id = c.object_id 
            AND fk.parent_column_id = c.column_id 
    WHERE fk.referenced_object_id = ( 
            SELECT object_id 
            FROM sys.tables 
            WHERE NAME = @referencedTable
            ) 

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

	SELECT sum(RCount) as ReferenceCount FROM #tempTable
    DROP TABLE #tempTable
END