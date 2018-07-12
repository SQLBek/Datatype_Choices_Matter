USE [master]
RESTORE DATABASE [EveryByteCounts] FROM  
DISK = N'\\vmware-host\Shared Folders\VM Shared Folders\EveryByteCounts_2012.bak' 
WITH  FILE = 1,  
MOVE N'EveryByteCounts' TO N'F:\SQL Server 2014\MSSQL12.MYSTIQUE\Data\EveryByteCounts.mdf',  
MOVE N'EveryByteCounts_log' TO N'L:\SQL Server 2014\MSSQL12.MYSTIQUE\Log\EveryByteCounts_log.ldf',  
NOUNLOAD,  REPLACE,  STATS = 5

GO


