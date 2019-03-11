select *
from sys.dm_os_wait_stats  
where wait_type like 'PAGEIOLATCH%'
order by wait_type asc


--DBCC SQLPERF("sys.dm_os_wait_stats",CLEAR); 

--SELECT * FROM sys.dm_io_virtual_file_stats (null,NULL)