USE [master];
GO

RESTORE DATABASE [AdventureWorksDW]
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorksDW_Export.bak'
WITH
    MOVE 'AdventureWorksDW'     TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW.mdf',
    MOVE 'AdventureWorksDW_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW_log.ldf',
    REPLACE;
GO