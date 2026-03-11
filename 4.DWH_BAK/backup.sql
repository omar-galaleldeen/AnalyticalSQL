BACKUP DATABASE [AdventureWorksDW]
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorksDW_Export.bak'
WITH 
    FORMAT,
    MEDIANAME = 'AdventureWorksDW',
    NAME = 'AdventureWorksDW Full Backup',
    STATS = 10;
GO

-- Verify the backup was created successfully
RESTORE VERIFYONLY
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorksDW_Export.bak';
GO