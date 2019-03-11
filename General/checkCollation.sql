DECLARE @TableName nvarchar(MAX) 
DECLARE @ColumnName nvarchar(MAX) 

SET @TableName = N'SampleTable'
SET @ColumnName = N'SampleColumn'


SELECT collation_name FROM sys.columns c 
Join sys.tables t on t.object_id = c.object_id and t.name = @TableName
WHERE c.name = @ColumnName;