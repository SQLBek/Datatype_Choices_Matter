/*-------------------------------------------------------------------
-- 4 - Page Splitting
-- 
-- Written By: Andy Yun
--
-- Inspired By Paul S. Randal's PageSplitCost.sql from Summit 2013
-------------------------------------------------------------------*/
USE EveryByteCounts;
GO
SET NOCOUNT ON
GO




---------------------------------------------
-- Example 1: Table with wide records
---------------------------------------------
IF EXISTS(SELECT 1 FROM sys.objects WHERE objects.OBJECT_ID = OBJECT_ID(N'SingleDataPage'))
	DROP TABLE SingleDataPage;
GO
CREATE TABLE SingleDataPage (
	RecID INT PRIMARY KEY CLUSTERED,
	MyValue CHAR(1000)
);
INSERT INTO SingleDataPage 
SELECT 1, 'One' UNION ALL
SELECT 2, 'Two' UNION ALL
SELECT 3, 'Three' UNION ALL
SELECT 5, 'Five' UNION ALL
SELECT 6, 'Six' UNION ALL
SELECT 7, 'Seven';
GO
-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count, record_count AS total_record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'SingleDataPage'), NULL, NULL, 'DETAILED'
);
GO
-----




-----
-- INSERT record at end of clustering key sequence
BEGIN TRANSACTION;

INSERT INTO SingleDataPage
SELECT 8, 'Eight';

SELECT [database_transaction_log_bytes_used]
FROM sys.dm_tran_database_transactions
WHERE [database_id] = DB_ID (N'EveryByteCounts');
GO

COMMIT TRANSACTION;
GO
-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count, record_count AS total_record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'SingleDataPage'), NULL, NULL, 'DETAILED'
);
GO
-- T-Log Bytes Used: xxxx
-----




-----
-- INSERT record in middle of clustering key sequence
BEGIN TRANSACTION;

INSERT INTO SingleDataPage
SELECT 4, 'Four';

SELECT [database_transaction_log_bytes_used]
FROM sys.dm_tran_database_transactions
WHERE [database_id] = DB_ID (N'EveryByteCounts');
GO

COMMIT TRANSACTION;
GO
-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count, record_count AS total_record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'SingleDataPage'), NULL, NULL, 'DETAILED'
);
GO
-- T-Log Bytes Used: xxxx
-----







---------------------------------------------
-- Example 2: Skewed key distribution
-- Integer Key based Cross-Reference Table
---------------------------------------------
IF EXISTS(SELECT 1 FROM sys.objects WHERE objects.OBJECT_ID = OBJECT_ID(N'IntegerXRefTable'))
	DROP TABLE IntegerXRefTable;

CREATE TABLE IntegerXRefTable (
	RecID INT NOT NULL,
	MyValueOne INT,
	MyValueTwo INT,
	MyValueThree INT,
	MyValueFour INT
);
CREATE CLUSTERED INDEX CK_IntegerXRefTable_RecID ON IntegerXRefTable (RecID);
GO
-- Populate with skewed records
INSERT INTO IntegerXRefTable 
SELECT 1, CAST(RAND() * 1000 AS INT), CAST(RAND() * 1000 AS INT), 
	NULL, CAST(RAND() * 1000 AS INT);
GO 1

INSERT INTO IntegerXRefTable
SELECT 3, CAST(RAND() * 1000 AS INT), CAST(RAND() * 1000 AS INT), 
	NULL, CAST(RAND() * 1000 AS INT);
GO 217

-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count, record_count AS total_record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'IntegerXRefTable'), NULL, NULL, 'DETAILED'
);
GO
-----




-----
-- INSERT record in the middle of clustering key sequence
BEGIN TRANSACTION;

INSERT INTO IntegerXRefTable
SELECT 2, CAST(RAND() * 1000 AS INT), CAST(RAND() * 1000 AS INT),
	NULL, CAST(RAND() * 1000 AS INT);
GO 

SELECT [database_transaction_log_bytes_used]
FROM sys.dm_tran_database_transactions
WHERE [database_id] = DB_ID (N'EveryByteCounts');
GO

COMMIT TRANSACTION;
GO
-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count, record_count AS total_record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'IntegerXRefTable'), NULL, NULL, 'DETAILED'
);
GO
-- T-Log Bytes Used: xxxx
-----




-----
-- INSERT additional record in the middle of clustering key sequence
BEGIN TRANSACTION;

INSERT INTO IntegerXRefTable
SELECT 2, CAST(RAND() * 1000 AS INT), CAST(RAND() * 1000 AS INT), 
	NULL, CAST(RAND() * 1000 AS INT);
GO 

SELECT [database_transaction_log_bytes_used]
FROM sys.dm_tran_database_transactions
WHERE [database_id] = DB_ID (N'EveryByteCounts');
GO

COMMIT TRANSACTION;
GO
-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count, record_count AS total_record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'IntegerXRefTable'), NULL, NULL, 'DETAILED'
);
GO
-- T-Log Bytes Used: xxxx
-----








---------------------------------------------
-- Example 3: Employee_Large
-- Clustered on GUID
-- Will have a random INSERT pattern using NEWID()
---------------------------------------------
-- Clean up prior runs
DELETE FROM Employee_Large
WHERE RecordCreatedDate = '1900-01-01';
GO
ALTER INDEX CK_Employee_Large ON Employee_Large
REBUILD;
GO
-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count, record_count AS total_record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'Employee_Large'), 1, NULL, 'DETAILED'
)
WHERE alloc_unit_type_desc = 'IN_ROW_DATA';

-- Starting # of leaf pages = xxxx
-- Starting # of intermediate pages = xxxx
-----




-----
-- INSERT record at random position of clustering key sequence
BEGIN TRANSACTION;

INSERT INTO Employee_Large (
	EmployeeID, FirstName, LastName, Gender, SocialSecurityNumber, 
	Title, ManagerID, DateHired, Salary, EmailAddress, HomeOfficeLocationCode, 
	VacationDaysRemaining, RecordCreatedDate, RecordCreatedBy, 
	RecordLastModifiedDate, RecordLastModifiedBy
)
SELECT TOP 1
	NEWID(), FirstName, LastName, Gender, SocialSecurityNumber, 
	Title, ManagerID, DateHired, Salary, EmailAddress, HomeOfficeLocationCode, 
	VacationDaysRemaining, '1900-01-01', RecordCreatedBy, 
	RecordLastModifiedDate, RecordLastModifiedBy
FROM Employee_Large
GO 

SELECT [database_transaction_log_bytes_used]
FROM sys.dm_tran_database_transactions
WHERE [database_id] = DB_ID (N'EveryByteCounts');
GO

COMMIT TRANSACTION;
GO
-- Show page information from sys.dm_db_index_physical_stats
SELECT 
	index_type_desc, index_depth, index_level,
	page_count, record_count AS total_record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'Employee_Large'), 1, NULL, 'DETAILED'
)
WHERE alloc_unit_type_desc = 'IN_ROW_DATA';
GO
