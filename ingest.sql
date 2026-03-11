USE [master];
GO

-- restore the data
RESTORE DATABASE AdventureWorks2025
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorks2025.bak'
WITH
    MOVE 'AdventureWorks'     TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorks.mdf',
    MOVE 'AdventureWorks_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\AdventureWorks_log.ldf',
    REPLACE;


-- run this to see the files names:
RESTORE FILELISTONLY
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorks2025.bak';

