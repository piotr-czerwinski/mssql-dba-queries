-- statistics of file chunks of database
-- size of data stored in one colum per row
-- inspired by https://stackoverflow.com/questions/14482897/list-all-sql-columns-with-max-length-and-greatest-length

DECLARE @analyzedDBName NVARCHAR(100) = N'TestDB';
DECLARE @analyzedTableName NVARCHAR(100) = N'dbo.SampleTable';
DECLARE @analyzedTableId int = OBJECT_ID(@analyzedTableName) ;

dbcc showcontig (@analyzedTableName) with tableresults
SELECT * FROM sys.dm_db_index_physical_stats
    (DB_ID(@analyzedDBName), @analyzedTableId, NULL, NULL , 'DETAILED');

SELECT 
    Object_Name(c.object_id),
    c.name 'Column Name',
    t.Name 'Data type',
    c.max_length 'Max Length'
FROM    
    sys.columns c
INNER JOIN 
    sys.types t ON c.system_type_id = t.system_type_id
WHERE
    c.object_id = @analyzedTableId
ORDER BY c.max_length DESC