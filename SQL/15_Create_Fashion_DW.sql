USE master;
GO

IF DB_ID('Fashion_DW') IS NULL
BEGIN
    CREATE DATABASE Fashion_DW;
END
GO

USE Fashion_DW;
GO