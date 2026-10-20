/*
====================================================
PROJECT: FASHION RETAIL DATA WAREHOUSE
FILE   : 01_Create_Database.sql
PURPOSE: Tạo Staging Database và Data Warehouse
====================================================
*/

-- =============================================
-- STAGING DATABASE
-- =============================================

IF DB_ID('Fashion_Staging') IS NULL
BEGIN
    CREATE DATABASE Fashion_Staging;
END;
GO

USE Fashion_Staging;
GO


-- RAW schema
IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'raw'
)
BEGIN
    EXEC('CREATE SCHEMA raw');
END;
GO


-- STG schema
IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END;
GO


-- =============================================
-- DATA WAREHOUSE DATABASE
-- =============================================

IF DB_ID('Fashion_DW') IS NULL
BEGIN
    CREATE DATABASE Fashion_DW;
END;
GO