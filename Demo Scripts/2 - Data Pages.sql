/*-------------------------------------------------------------------
-- 2 - Exploring Data Pages with DBCC PAGE
-- 
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE EveryByteCounts;
GO

-- Activate Trace Flag to print output to query window
DBCC TRACEON(3604, 1);
GO




-----
-- Create Mixed Data Type Table
IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'DBCC_PAGE_Example')
	DROP TABLE dbo.DBCC_PAGE_Example;
GO
CREATE TABLE dbo.DBCC_PAGE_Example (
	StringOne VARCHAR(50),
	StringTwo CHAR(5),
	RecID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED
);

-- Insert a single record
INSERT INTO dbo.DBCC_PAGE_Example (
	StringOne, StringTwo
)
SELECT 'Sample String', 'Foo';




-----
-- Use DBCC IND to get information 
-- Usage: DBCC IND([DatabaseName], [TableName], [IndexID]);
-- SQL Server 2012 replaces DBCC IND with 
-- DMF sys.dm_db_database_page_allocations()
DBCC IND(EveryByteCounts, DBCC_PAGE_Example, 1);

-- PageTypes
--  1 = data page
--  2 = index page
--  3 = text pages
--  4 = text pages
--  8 = GAM page
--  9 = SGAM page
-- 10 = IAM page
-- 11 = PFS page




-----
-- Use DBCC PAGE to examine contents of data page
-- USAGE: DBCC PAGE([DatabaseName], [FileNumber], [PageID], [OutputType])
-- OutputType = 0 -> View Page Header Only
-- OutputType = 3 -> Per Record Breakdown
DBCC PAGE(EveryByteCounts, 1, xxxx, 3);

/*
FIXVAR Breakdown
NOTE: multi-byte values are stored as least-significant byte first 

3000				= status bits (2 bytes)
0d00				= total fixed length size (2 bytes)
01000000			= value inside RecID INT column (4 bytes)
466f6f20 20			= value inside StringTwo column (5 bytes)
0300				= total number of columns (2 bytes)
00					= NULL BITMAP (1 byte)
0100				= total # of var length columns (2 bytes)
2100				= variable column offset array (2 bytes per column)
53616d70 6c652053
7472696e 67			= value inside StringOne column (N bytes)
*/

-- Can reverse engineer the hex into string values!
SELECT 
	CHAR(CONVERT(INT, 0x46)) + CHAR(CONVERT(INT, 0x6f)) + CHAR(CONVERT(INT, 0x6f)) + 
	CHAR(CONVERT(INT, 0x20)) + CHAR(CONVERT(INT, 0x20)) AS StringOne,	-- 0x20 = space
	--
	CHAR(CONVERT(INT, 0x53)) + CHAR(CONVERT(INT, 0x61)) + CHAR(CONVERT(INT, 0x6d)) + 
	CHAR(CONVERT(INT, 0x70)) + CHAR(CONVERT(INT, 0x6c)) + CHAR(CONVERT(INT, 0x65)) +
	CHAR(CONVERT(INT, 0x20)) + CHAR(CONVERT(INT, 0x53)) + CHAR(CONVERT(INT, 0x74)) +
	CHAR(CONVERT(INT, 0x72)) + CHAR(CONVERT(INT, 0x69)) + CHAR(CONVERT(INT, 0x6e)) +
	CHAR(CONVERT(INT, 0x67)) AS StringTwo;








-----
-- Create Table with a MAX datatype
IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'DBCC_PAGE_MAXColumn')
	DROP TABLE dbo.DBCC_PAGE_MAXColumn;
GO
CREATE TABLE DBCC_PAGE_MAXColumn (
	MaxString VARCHAR(MAX),
	RecID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED
);

-----
-- String Value Example
INSERT INTO dbo.DBCC_PAGE_MAXColumn (
	MaxString
) 
SELECT 'ShortString';




-- View output of sys.dm_db_index_physical_stats
SELECT index_type_desc, alloc_unit_type_desc, page_count, record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'DBCC_PAGE_MAXColumn'), 1, NULL, 'Detailed'
);




-----
-- Let's insert a very long string now.
SELECT LEN(REPLICATE(CAST('VeryLongString' AS VARCHAR(MAX)), 1000)) AS Length,
	REPLICATE(CAST('VeryLongString' AS VARCHAR(MAX)), 1000) AS VeryLongString;

INSERT INTO dbo.DBCC_PAGE_MAXColumn (
	MaxString
) 
SELECT REPLICATE(CAST('VeryLongString' AS VARCHAR(MAX)), 1000);




-- View output of sys.dm_db_index_physical_stats
SELECT index_type_desc, alloc_unit_type_desc, page_count, record_count
FROM sys.dm_db_index_physical_stats(
	DB_ID(N'EveryByteCounts'), OBJECT_ID(N'DBCC_PAGE_MAXColumn'), 1, NULL, 'Detailed'
);




-- Get Page Information
DBCC IND(EveryByteCounts, DBCC_PAGE_MAXColumn, 1);

-- PageTypes
--  1 = data page
--  3 = text pages




-- Check DBCC PAGE for in-row data page
-- See value of MaxString
DBCC PAGE(EveryByteCounts, 1, xxxx, 3);

-- Check DBCC PAGE for a LOB data page
DBCC PAGE(EveryByteCounts, 1, xxxx, 3);




-----
-- See consequence of MAX in I/O
SET STATISTICS IO ON
SELECT RecID, MaxString
FROM dbo.DBCC_PAGE_MAXColumn
WHERE RecID = 1;

SELECT RecID, MaxString
FROM dbo.DBCC_PAGE_MAXColumn
WHERE RecID = 2;

SELECT RecID, MaxString
FROM dbo.DBCC_PAGE_MAXColumn;
SET STATISTICS IO OFF




-- OPTIONAL
-- Change value of 1st record to something else long
UPDATE dbo.DBCC_PAGE_MAXColumn 
SET MaxString = REPLICATE(CAST('DifferentLongString' AS VARCHAR(MAX)), 1000)
WHERE RecID = 1;


-- Check DBCC IND
DBCC IND(EveryByteCounts, DBCC_PAGE_MAXColumn, 1);


-- Check DBCC PAGE in-row data page for value of MaxString
DBCC PAGE(EveryByteCounts, 1, xxxx, 3);




-----
-- See consequence of MAX in I/O
SET STATISTICS IO ON
SELECT RecID, MaxString
FROM dbo.DBCC_PAGE_MAXColumn
WHERE RecID = 1;

SELECT RecID, MaxString
FROM dbo.DBCC_PAGE_MAXColumn
WHERE RecID = 2;

SELECT RecID, MaxString
FROM dbo.DBCC_PAGE_MAXColumn;
SET STATISTICS IO OFF

