/*-------------------------------------------------------------------
-- 5 - Implicit Conversions
-- 
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE EveryByteCounts;
GO
SET NOCOUNT ON;
GO
SET STATISTICS IO ON
GO




-----
-- SIMPLE VARIABLE EXAMPLES
-- TURN ON ACTUAL EXECUTION PLAN (Ctrl-M)
-- Integer 
DECLARE 
	@MySmallInt SMALLINT = 5,
	@MyBigInt BIGINT = 5;

SELECT 'Matching Types'
WHERE @MySmallInt = @MySmallInt;

SELECT 'Mismatched Types'
WHERE @MySmallInt = @MyBigInt;
GO




-----
-- VARCHAR & NVARCHAR
DECLARE 
	@MyNVarChar NVARCHAR(50) = 'This is a string',
	@MyVarChar VARCHAR(50) = 'This is a string';

SELECT 'Matching Types'
WHERE @MyVarChar = @MyVarChar;

SELECT 'Mismatched Types'
WHERE @MyNVarChar = @MyVarChar;
GO




-----
-- Create a covering index
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_Employee_Narrow_LastName')
	DROP INDEX Employee_Narrow.[IX_Employee_Narrow_LastName]

CREATE NONCLUSTERED INDEX IX_Employee_Narrow_LastName 
ON Employee_Narrow (
	LastName, EmployeeID
) INCLUDE (Salary, DateHired);
GO




-----
-- Query with matching data type
-- What were my data types? 
DECLARE @LastName_Matching VARCHAR(100) = 'Smith'

SELECT EmployeeID, LastName, Salary, DateHired
FROM Employee_Narrow
WHERE LastName = @LastName_Matching
GO








-----
-- Query with larger data type
DECLARE @LastName_NVARCHAR NVARCHAR(100) = 'Smith'

SELECT EmployeeID, LastName, Salary, DateHired
FROM Employee_Narrow
WHERE LastName = @LastName_NVARCHAR
GO








-----
-- Query with smaller data type
DECLARE @LastName_CHAR CHAR(5) = 'Smith'

SELECT EmployeeID, LastName, Salary, DateHired
FROM Employee_Narrow
WHERE LastName = @LastName_CHAR
GO








-----
-- CHAR(x) & VARCHAR(x) conversions are "free"
-- NCHAR(x) & NVARCHAR(x) conversions are "free"
-----








-- Query with larger "free" data type
DECLARE @LastName_CHAR VARCHAR(500) = 'Smith'

SELECT EmployeeID, LastName, Salary, DateHired
FROM Employee_Narrow
WHERE LastName = @LastName_CHAR
GO








-- Query with MAX data type
DECLARE @LastName_CHAR VARCHAR(MAX) = 'Smith'

SELECT EmployeeID, LastName, Salary, DateHired
FROM Employee_Narrow
WHERE LastName = @LastName_CHAR
GO


