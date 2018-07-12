/*-------------------------------------------------------------------
-- 0 - Reset Demo Tables
-- 
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE EveryByteCounts;
GO

IF EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_Employee_Narrow_LastName')
	DROP INDEX Employee_Narrow.IX_Employee_Narrow_LastName;
GO

IF EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_Employee_Narrow_Salary')
	DROP INDEX Employee_Narrow.IX_Employee_Narrow_Salary;
GO

IF EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_Employee_Narrow_FirstNameLastName')
	DROP INDEX Employee_Narrow.IX_Employee_Narrow_FirstNameLastName;
GO

-- Flush cache
DBCC FREEPROCCACHE;
GO

-- Force to Simple recovery
ALTER DATABASE [EveryByteCounts]
	SET RECOVERY SIMPLE;
GO

-- 4 - Page Splitting.sql
-- Clean up prior runs
DELETE FROM Employee_Large
WHERE RecordCreatedDate = '1900-01-01';
GO
DELETE FROM Employee_Narrow
WHERE RecordCreatedDate = '1900-01-01';
GO

ALTER INDEX CK_Employee_Large ON Employee_Large
REBUILD;
GO

ALTER INDEX CK_Employee_Narrow ON Employee_Narrow
REBUILD;
GO

-----
-- Check Table Structure
-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count,	record_count AS total_record_count,
	avg_page_space_used_in_percent, avg_record_size_in_bytes, 
	avg_fragmentation_in_percent,
	alloc_unit_type_desc
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), 
	OBJECT_ID(N'Employee_Large'), 
	1, NULL, 'DETAILED'
);


SELECT 
	index_type_desc, index_depth, index_level,
	page_count,	record_count AS total_record_count,
	avg_page_space_used_in_percent, avg_record_size_in_bytes, 
	avg_fragmentation_in_percent,
	alloc_unit_type_desc
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), 
	OBJECT_ID(N'Employee_Narrow'), 
	1, NULL, 'DETAILED'
);

-----
-- Populate Buffer Pool
SELECT *
FROM dbo.Employee_Large


SELECT *
FROM dbo.Employee_Narrow
