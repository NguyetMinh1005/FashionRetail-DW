/* ============================================================
   FILE: 11_Cap_nhat_cau_truc_STG_quoc_gia_tien_te.sql

   MỤC ĐÍCH:
   - Cập nhật cấu trúc STG sau khi Python bổ sung xử lý
     dữ liệu đa quốc gia và quy đổi tiền tệ.
   - Bổ sung các cột Country / Currency / Exchange Rate / USD.
   - Không xóa dữ liệu hay tạo lại bảng.
   - Chỉ ADD cột nếu cột chưa tồn tại.

   DATABASE:
   Fashion_Staging
   ============================================================ */

USE Fashion_Staging;
GO


/* ============================================================
   1. KIỂM TRA SCHEMA STG
   ============================================================ */

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


/* ============================================================
   2. CẬP NHẬT stg.transactions
   ============================================================ */


/* Country_Code */
IF COL_LENGTH(
    'stg.transactions',
    'Country_Code'
) IS NULL
BEGIN

    ALTER TABLE stg.transactions
    ADD Country_Code NVARCHAR(10) NULL;

    PRINT N'Đã thêm Country_Code vào stg.transactions';

END;
GO


/* Expected_Currency */
IF COL_LENGTH(
    'stg.transactions',
    'Expected_Currency'
) IS NULL
BEGIN

    ALTER TABLE stg.transactions
    ADD Expected_Currency NVARCHAR(10) NULL;

    PRINT N'Đã thêm Expected_Currency vào stg.transactions';

END;
GO


/* Currency_Match */
IF COL_LENGTH(
    'stg.transactions',
    'Currency_Match'
) IS NULL
BEGIN

    ALTER TABLE stg.transactions
    ADD Currency_Match NVARCHAR(10) NULL;

    PRINT N'Đã thêm Currency_Match vào stg.transactions';

END;
GO


/* Net_Amount_Local */
IF COL_LENGTH(
    'stg.transactions',
    'Net_Amount_Local'
) IS NULL
BEGIN

    ALTER TABLE stg.transactions
    ADD Net_Amount_Local NVARCHAR(30) NULL;

    PRINT N'Đã thêm Net_Amount_Local vào stg.transactions';

END;
GO


/* Exchange_Rate_To_USD */
IF COL_LENGTH(
    'stg.transactions',
    'Exchange_Rate_To_USD'
) IS NULL
BEGIN

    ALTER TABLE stg.transactions
    ADD Exchange_Rate_To_USD NVARCHAR(30) NULL;

    PRINT N'Đã thêm Exchange_Rate_To_USD vào stg.transactions';

END;
GO


/* Exchange_Rate_Date */
IF COL_LENGTH(
    'stg.transactions',
    'Exchange_Rate_Date'
) IS NULL
BEGIN

    ALTER TABLE stg.transactions
    ADD Exchange_Rate_Date NVARCHAR(20) NULL;

    PRINT N'Đã thêm Exchange_Rate_Date vào stg.transactions';

END;
GO


/* Exchange_Rate_Source */
IF COL_LENGTH(
    'stg.transactions',
    'Exchange_Rate_Source'
) IS NULL
BEGIN

    ALTER TABLE stg.transactions
    ADD Exchange_Rate_Source NVARCHAR(50) NULL;

    PRINT N'Đã thêm Exchange_Rate_Source vào stg.transactions';

END;
GO


/* Net_Amount_USD */
IF COL_LENGTH(
    'stg.transactions',
    'Net_Amount_USD'
) IS NULL
BEGIN

    ALTER TABLE stg.transactions
    ADD Net_Amount_USD NVARCHAR(30) NULL;

    PRINT N'Đã thêm Net_Amount_USD vào stg.transactions';

END;
GO



/* ============================================================
   3. CẬP NHẬT stg.stores

   File stores sau chuẩn hóa có thêm:
   - Country_Code
   - Country_Name_EN
   - Country_Name_VI
   - Expected_Currency
   ============================================================ */


/* Country_Code */
IF COL_LENGTH(
    'stg.stores',
    'Country_Code'
) IS NULL
BEGIN

    ALTER TABLE stg.stores
    ADD Country_Code NVARCHAR(10) NULL;

    PRINT N'Đã thêm Country_Code vào stg.stores';

END;
GO


/* Country_Name_EN */
IF COL_LENGTH(
    'stg.stores',
    'Country_Name_EN'
) IS NULL
BEGIN

    ALTER TABLE stg.stores
    ADD Country_Name_EN NVARCHAR(100) NULL;

    PRINT N'Đã thêm Country_Name_EN vào stg.stores';

END;
GO


/* Country_Name_VI */
IF COL_LENGTH(
    'stg.stores',
    'Country_Name_VI'
) IS NULL
BEGIN

    ALTER TABLE stg.stores
    ADD Country_Name_VI NVARCHAR(100) NULL;

    PRINT N'Đã thêm Country_Name_VI vào stg.stores';

END;
GO


/* Expected_Currency */
IF COL_LENGTH(
    'stg.stores',
    'Expected_Currency'
) IS NULL
BEGIN

    ALTER TABLE stg.stores
    ADD Expected_Currency NVARCHAR(10) NULL;

    PRINT N'Đã thêm Expected_Currency vào stg.stores';

END;
GO



/* ============================================================
   4. THÔNG BÁO HOÀN TẤT
   ============================================================ */

PRINT N'============================================================';
PRINT N'HOÀN TẤT CẬP NHẬT CẤU TRÚC STG QUỐC GIA / TIỀN TỆ';
PRINT N'============================================================';
GO