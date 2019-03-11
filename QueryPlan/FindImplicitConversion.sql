/*****************************************************************************
* Presentation: Performance Tuning with the Plan Cache
* FileName: 3.2 - Implicit Column Side Conversions.sql
*
* Summary: Demonstrates how to find column side implicit conversions and the
* statements that generated it by parsing XML Plans stored in the
* plan cache.
*
* Date: October 16, 2010
*
* SQL Server Versions:
* 2005, 2008, 2008 R2
*
******************************************************************************
* Copyright (C) 2010 Jonathan M. Kehayias
* All rights reserved.
*
* For more scripts and sample code, check out
* http://sqlblog.com/blogs/jonathan_kehayias
*
* You may alter this code for your own *non-commercial* purposes. You may
* republish altered code as long as you include this copyright and give
* due credit.
*
*
* THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF
* ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED
* TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
* PARTICULAR PURPOSE.
*
******************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @dbname SYSNAME
SET @dbname = QUOTENAME(DB_NAME());

WITH XMLNAMESPACES
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT top 50
stmt.value('(@StatementText)[1]', 'varchar(max)'),
t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)'),
t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)'),
t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)'),
ic.DATA_TYPE AS ConvertFrom,
ic.CHARACTER_MAXIMUM_LENGTH AS ConvertFromLength,
t.value('(@DataType)[1]', 'varchar(128)') AS ConvertTo,
t.value('(@Length)[1]', 'int') AS ConvertToLength,
query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
CROSS APPLY stmt.nodes('.//Convert[@Implicit="1"]') AS n(t)
JOIN INFORMATION_SCHEMA.COLUMNS AS ic
ON QUOTENAME(ic.TABLE_SCHEMA) = t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)')
AND QUOTENAME(ic.TABLE_NAME) = t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)')
AND ic.COLUMN_NAME = t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)')
WHERE t.exist('ScalarOperator/Identifier/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]') = 1 