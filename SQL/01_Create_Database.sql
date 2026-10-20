IF DB_ID('Fashion_Staging') IS NULL
BEGIN
    CREATE DATABASE Fashion_Staging;
END;
GO

USE Fashion_Staging;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'raw'
)
BEGIN
    EXEC('CREATE SCHEMA raw');
END;
GO