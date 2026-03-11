USE [master];
GO


-- run this to see the files names:
RESTORE FILELISTONLY
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorksDW2025.bak';


-- restore the data
USE [master];
GO

RESTORE DATABASE AdventureWorksDWV2
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorksDW2025.bak'
WITH
    MOVE 'AdventureWorksDW'     TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorksDWV2.mdf',
    MOVE 'AdventureWorksDW_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorksDWV2_log.ldf',
    REPLACE;