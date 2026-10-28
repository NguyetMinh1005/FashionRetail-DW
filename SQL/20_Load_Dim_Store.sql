USE Fashion_DW;
GO

/* ============================================================
   20 - LOAD DIM STORE
   ============================================================ */

TRUNCATE TABLE dbo.Dim_Store;
GO

INSERT INTO dbo.Dim_Store
(
    Store_ID,
    Country,
    City,
    Store_Name,
    Number_Of_Employees,
    ZIP_Code,
    Latitude,
    Longitude,
    Country_Original,
    Country_Code,
    Country_Name_EN,
    Country_Name_VI,
    Expected_Currency
)
SELECT
    Store_ID,
    Country,
    City,
    Store_Name,
    TRY_CONVERT(INT, Number_Of_Employees),
    ZIP_Code,
    TRY_CONVERT(DECIMAL(18,8), Latitude),
    TRY_CONVERT(DECIMAL(18,8), Longitude),

    /* STG không có Country_Original
       nên giữ Country làm giá trị gốc */
    Country AS Country_Original,

    Country_Code,
    Country_Name_EN,
    Country_Name_VI,
    Expected_Currency
FROM Fashion_Staging.stg.stores;
GO


/* ============================================================
   KIỂM TRA SỐ DÒNG
   ============================================================ */

SELECT COUNT(*) AS SoDong
FROM dbo.Dim_Store;
GO


/* ============================================================
   XEM DỮ LIỆU MẪU
   ============================================================ */

SELECT TOP 10 *
FROM dbo.Dim_Store
ORDER BY Store_Key;
GO