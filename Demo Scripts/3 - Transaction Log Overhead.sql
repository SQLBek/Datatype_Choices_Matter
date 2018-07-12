/*-------------------------------------------------------------------
-- 3 - Transaction Log Overhead
-- 
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE EveryByteCounts;
GO
SET STATISTICS IO ON;
GO


-----
-- DMV: sys.dm_tran_database_transactions
-- sp_help the DMV
SELECT *
FROM sys.dm_tran_database_transactions
WHERE database_id = DB_ID('EveryByteCounts');
GO








-----
-- Example 1: SELECT
BEGIN TRANSACTION;

SELECT TOP 10000 *
FROM dbo.Employee_Large;

SELECT database_transaction_log_bytes_used
FROM sys.dm_tran_database_transactions
WHERE database_id = DB_ID('EveryByteCounts');

ROLLBACK TRANSACTION;
GO
-----







-----
-- Example 2a: UPDATE Employee_Large
BEGIN TRANSACTION;

UPDATE dbo.Employee_Large
SET FirstName = REPLACE(FirstName, ' ', '_')
WHERE LastName = 'Smith';

SELECT database_transaction_log_bytes_used
FROM sys.dm_tran_database_transactions
WHERE database_id = DB_ID('EveryByteCounts');

ROLLBACK TRANSACTION;
GO
-- T-Log Bytes Used: xxxx
-----








-----
-- Example 2b: UPDATE Employee_Narrow
BEGIN TRANSACTION;

UPDATE dbo.Employee_Narrow
SET FirstName = REPLACE(FirstName, ' ', '_')
WHERE LastName = 'Smith';

SELECT database_transaction_log_bytes_used
FROM sys.dm_tran_database_transactions
WHERE database_id = DB_ID('EveryByteCounts');

ROLLBACK TRANSACTION;
GO
-- T-Log Bytes Used: xxxx
-----








-----
-- Example 3a: DELETE Employee_Large
BEGIN TRANSACTION;

DELETE FROM dbo.Employee_Large
WHERE LastName = 'Abrams';

SELECT database_transaction_log_bytes_used
FROM sys.dm_tran_database_transactions
WHERE database_id = DB_ID('EveryByteCounts');

ROLLBACK TRANSACTION;
GO
-- T-Log Bytes Used: xxxx
-----








-----
-- Example 3b: DELETE Employee_Narrow
BEGIN TRANSACTION

DELETE FROM dbo.Employee_Narrow
WHERE LastName = 'Abrams';

SELECT database_transaction_log_bytes_used
FROM sys.dm_tran_database_transactions
WHERE database_id = DB_ID('EveryByteCounts');

ROLLBACK TRANSACTION
GO
-- T-Log Bytes Used: xxxx
-----

