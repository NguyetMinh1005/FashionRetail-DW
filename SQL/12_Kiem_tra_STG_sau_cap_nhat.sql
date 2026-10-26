/* ============================================================
   FILE: 12_Kiem_tra_STG_sau_cap_nhat.sql

   MỤC ĐÍCH:
   - Kiểm tra schema STG sau khi cập nhật.
   - Kiểm tra số cột.
   - Kiểm tra tên cột / kiểu dữ liệu.
   - Kiểm tra các cột Country / Currency / USD.
   - Chưa kiểm tra số dòng vì STG có thể chưa được nạp.

   DATABASE:
   Fashion_Staging
   ============================================================ */

USE Fashion_Staging;
GO


/* ============================================================
   1. DANH SÁCH CÁC BẢNG STG
   ============================================================ */

PRINT N'1. DANH SÁCH BẢNG STG';
PRINT N'------------------------------------------------------------';

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO



/* ============================================================
   2. SỐ CỘT CỦA TỪNG BẢNG STG
   ============================================================ */

PRINT N'2. SỐ CỘT CỦA TỪNG BẢNG STG';
PRINT N'------------------------------------------------------------';

SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COUNT(*) AS SoCot
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
GROUP BY
    TABLE_SCHEMA,
    TABLE_NAME
ORDER BY TABLE_NAME;
GO



/* ============================================================
   3. CẤU TRÚC stg.customers
   ============================================================ */

PRINT N'3. CẤU TRÚC stg.customers';

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'customers'
ORDER BY ORDINAL_POSITION;
GO



/* ============================================================
   4. CẤU TRÚC stg.products
   ============================================================ */

PRINT N'4. CẤU TRÚC stg.products';

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'products'
ORDER BY ORDINAL_POSITION;
GO



/* ============================================================
   5. CẤU TRÚC stg.stores
   ============================================================ */

PRINT N'5. CẤU TRÚC stg.stores';

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'stores'
ORDER BY ORDINAL_POSITION;
GO



/* ============================================================
   6. CẤU TRÚC stg.employees
   ============================================================ */

PRINT N'6. CẤU TRÚC stg.employees';

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'employees'
ORDER BY ORDINAL_POSITION;
GO



/* ============================================================
   7. CẤU TRÚC stg.discounts
   ============================================================ */

PRINT N'7. CẤU TRÚC stg.discounts';

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'discounts'
ORDER BY ORDINAL_POSITION;
GO



/* ============================================================
   8. CẤU TRÚC stg.transactions
   ============================================================ */

PRINT N'8. CẤU TRÚC stg.transactions';

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'transactions'
ORDER BY ORDINAL_POSITION;
GO



/* ============================================================
   9. KIỂM TRA CÁC CỘT TIỀN TỆ CỦA TRANSACTIONS
   ============================================================ */

PRINT N'9. KIỂM TRA CỘT QUỐC GIA / TIỀN TỆ';

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'transactions'
  AND COLUMN_NAME IN
(
    'Country_Code',
    'Expected_Currency',
    'Currency_Match',
    'Net_Amount',
    'Net_Amount_Local',
    'Exchange_Rate_To_USD',
    'Exchange_Rate_Date',
    'Exchange_Rate_Source',
    'Net_Amount_USD'
)
ORDER BY ORDINAL_POSITION;
GO



/* ============================================================
   10. KIỂM TRA CÁC CỘT QUỐC GIA TRONG STORES
   ============================================================ */

PRINT N'10. KIỂM TRA CỘT QUỐC GIA TRONG STORES';

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'stores'
  AND COLUMN_NAME IN
(
    'Country_Code',
    'Country_Name_EN',
    'Country_Name_VI',
    'Expected_Currency'
)
ORDER BY ORDINAL_POSITION;
GO



/* ============================================================
   11. KIỂM TRA CÁC CỘT KỸ THUẬT STG
   ============================================================ */

PRINT N'11. KIỂM TRA CÁC CỘT KỸ THUẬT';

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
AND COLUMN_NAME IN
(
    'Stg_Row_ID',
    'Source_File',
    'Load_Date',
    'Is_Review'
)
ORDER BY
    TABLE_NAME,
    ORDINAL_POSITION;
GO



PRINT N'============================================================';
PRINT N'HOÀN TẤT KIỂM TRA CẤU TRÚC STG';
PRINT N'============================================================';
GO