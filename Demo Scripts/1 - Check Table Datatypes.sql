/*-------------------------------------------------------------------
-- 1 - Exploring Data Records & Pages
-- 
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE EveryByteCounts;
GO








-----
-- Take a quick look inside our two example tables
SELECT TOP 1000 *
FROM dbo.Employee_Large
ORDER BY LastName, FirstName;

SELECT TOP 1000 *
FROM dbo.Employee_Narrow
ORDER BY LastName, FirstName;








-----
-- Use sp_help to quickly reference detailed information
EXEC sp_help 'dbo.Employee_Large';
GO

EXEC sp_help 'dbo.Employee_Narrow';
GO








-----
-- Keyboard Shortcut!
--
-- Tools -> Options
-- Environment -> Keyboard -> Query Shortcuts








-----
-- DMV Query: sys.dm_db_index_physical_stats
-- Use avg_record_size_in_bytes to gauge current record density
SELECT 
	OBJECT_NAME(object_id) AS TblName,
	index_type_desc, record_count, 
	page_count, avg_page_space_used_in_percent, 
	min_record_size_in_bytes, max_record_size_in_bytes, 
	avg_record_size_in_bytes
FROM sys.dm_db_index_physical_stats (
	DB_ID('EveryByteCounts'),		-- database_id
	OBJECT_ID(N'Employee_Large'),	-- object_id
	NULL,							-- index_id
	NULL,							-- partition_number
	'DETAILED'						-- mode: DEFAULT, NULL, LIMITED, SAMPLED, DETAILED
)
WHERE index_level = 0				-- Only show Leaf Level
	AND alloc_unit_type_desc = 'IN_ROW_DATA';
GO

SELECT 
	OBJECT_NAME(object_id) AS TblName,
	index_type_desc, record_count, 
	page_count, avg_page_space_used_in_percent, 
	min_record_size_in_bytes, max_record_size_in_bytes, 
	avg_record_size_in_bytes
FROM sys.dm_db_index_physical_stats (
	DB_ID('EveryByteCounts'),		-- database_id
	OBJECT_ID(N'Employee_Narrow'),	-- object_id
	NULL,							-- index_id
	NULL,							-- partition_number
	'DETAILED'						-- mode: DEFAULT, NULL, LIMITED, SAMPLED, DETAILED
)
WHERE index_level = 0				-- Only show Leaf Level
	AND alloc_unit_type_desc = 'IN_ROW_DATA';
GO








-----
-- Using STATISTICS IO
SET STATISTICS IO ON;
GO




-- Let's query a set of data
SELECT TOP 50000 * 
FROM dbo.Employee_Large
ORDER BY EmployeeID;

SELECT TOP 50000 *
FROM dbo.Employee_Narrow
ORDER BY EmployeeID;
GO




-- Let's only query a couple of columns
SELECT TOP 50000 FirstName, LastName
FROM dbo.Employee_Large

SELECT TOP 50000 FirstName, LastName
FROM dbo.Employee_Narrow
GO




-- OPTIONAL: Query a nonclustered index
-- Turn on Actual Execution Plan, execute, & note 
-- physical operator & # of Logical Reads
SELECT TOP 50000 FirstName, LastName
FROM dbo.Employee_Narrow
GO




-- Create a covering index
SET STATISTICS IO OFF;
IF EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_Employee_Narrow_FirstNameLastName')
	DROP INDEX Employee_Narrow.IX_Employee_Narrow_FirstNameLastName;
GO
CREATE NONCLUSTERED INDEX IX_Employee_Narrow_FirstNameLastName 
	ON Employee_Narrow (
		FirstName, LastName 
	);
SET STATISTICS IO ON;
GO




-- Let's only query a couple of columns again
-- Why is there a change?
SELECT TOP 50000 FirstName, LastName
FROM dbo.Employee_Narrow
GO




-- Clean Up
IF EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_Employee_Narrow_FirstNameLastName')
	DROP INDEX Employee_Narrow.IX_Employee_Narrow_FirstNameLastName;
GO