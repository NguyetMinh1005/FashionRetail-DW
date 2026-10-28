USE Fashion_DW;
GO

/* ============================================================
   20 - LOAD DIM STORE
   Dự án: Fashion Retail Data Warehouse

   Nguồn chính:
       Fashion_Staging.stg.stores

   Nguồn bổ sung:
       Fashion_Staging.stg.employees

   Đích:
       Fashion_DW.dbo.Dim_Store

   Business Key:
       Store_ID

   Surrogate Key:
       Store_Key

   Lưu ý:
       Employee_Count được tính từ stg.employees,
       KHÔNG lấy Number_Of_Employees từ stg.stores.
   ============================================================ */


/* ============================================================
   1. KIỂM TRA FACT TRƯỚC KHI RELOAD DIM
   ============================================================ */

IF EXISTS (SELECT 1 FROM dbo.Fact_Sales)
BEGIN
    THROW 50003,
          N'Fact_Sales đã có dữ liệu. Không được reload Dim_Store trước khi xử lý Fact.',
          1;
END;
GO


/* ============================================================
   2. XÓA DỮ LIỆU DIM STORE CŨ
   ============================================================ */

/*
   Không dùng TRUNCATE vì Dim_Store đang được
   Fact_Sales tham chiếu bằng FOREIGN KEY.
*/

DELETE FROM dbo.Dim_Store;
GO

DBCC CHECKIDENT ('dbo.Dim_Store', RESEED, 0);
GO


/* ============================================================
   3. TẠO BẢN GHI UNKNOWN STORE
   ============================================================ */

INSERT INTO dbo.Dim_Store
(
    Store_ID,
    Store_Name,
    City,
    Country,
    Country_Code,
    ZIP_Code,
    Latitude,
    Longitude,
    Employee_Count
)
VALUES
(
    -1,
    N'Unknown',
    N'Unknown',
    N'Unknown',
    N'UNK',
    N'Unknown',
    NULL,
    NULL,
    0
);
GO


/* ============================================================
   4. ĐẾM NHÂN VIÊN THỰC TẾ THEO STORE_ID
   ============================================================ */

/*
   employees.csv được dùng làm nguồn chuẩn để xác định
   số lượng nhân viên của từng cửa hàng.

   Không sử dụng stores.Number_Of_Employees vì dữ liệu
   này không khớp với employees.
*/

;WITH Employee_Count_By_Store AS
(
    SELECT
        TRY_CONVERT(INT, Store_ID) AS Store_ID,
        COUNT(DISTINCT TRY_CONVERT(INT, Employee_ID))
            AS Employee_Count
    FROM Fashion_Staging.stg.employees
    WHERE TRY_CONVERT(INT, Store_ID) IS NOT NULL
      AND TRY_CONVERT(INT, Employee_ID) IS NOT NULL
    GROUP BY TRY_CONVERT(INT, Store_ID)
)


/* ============================================================
   5. NẠP STORE TỪ STAGING
   ============================================================ */

INSERT INTO dbo.Dim_Store
(
    Store_ID,
    Store_Name,
    City,
    Country,
    Country_Code,
    ZIP_Code,
    Latitude,
    Longitude,
    Employee_Count
)
SELECT
    TRY_CONVERT(INT, s.Store_ID) AS Store_ID,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(s.Store_Name)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(s.Store_Name))
    END AS Store_Name,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(s.City)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(s.City))
    END AS City,

    /*
       Ưu tiên Country_Name_EN vì đây là tên quốc gia
       đã chuẩn hóa để phục vụ phân tích đa quốc gia.
    */
    CASE
        WHEN NULLIF(LTRIM(RTRIM(s.Country_Name_EN)), '') IS NOT NULL
            THEN LTRIM(RTRIM(s.Country_Name_EN))

        WHEN NULLIF(LTRIM(RTRIM(s.Country)), '') IS NOT NULL
            THEN LTRIM(RTRIM(s.Country))

        ELSE N'Unknown'
    END AS Country,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(s.Country_Code)), '') IS NULL
            THEN N'UNK'
        ELSE UPPER(LTRIM(RTRIM(s.Country_Code)))
    END AS Country_Code,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(s.ZIP_Code)), '') IS NULL
            THEN N'Unknown'
        ELSE LTRIM(RTRIM(s.ZIP_Code))
    END AS ZIP_Code,

    TRY_CONVERT(DECIMAL(9,4), s.Latitude)
        AS Latitude,

    TRY_CONVERT(DECIMAL(9,4), s.Longitude)
        AS Longitude,

    ISNULL(e.Employee_Count, 0)
        AS Employee_Count

FROM Fashion_Staging.stg.stores AS s

LEFT JOIN Employee_Count_By_Store AS e
    ON TRY_CONVERT(INT, s.Store_ID) = e.Store_ID

WHERE TRY_CONVERT(INT, s.Store_ID) IS NOT NULL;
GO


/* ============================================================
   6. KIỂM TRA TỔNG SỐ DÒNG
   ============================================================ */

SELECT
    COUNT(*) AS Total_Dim_Store
FROM dbo.Dim_Store;
GO


/* ============================================================
   7. KIỂM TRA STORE_ID BỊ TRÙNG
   Kết quả mong đợi: 0 dòng
   ============================================================ */

SELECT
    Store_ID,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Store
GROUP BY Store_ID
HAVING COUNT(*) > 1;
GO


/* ============================================================
   8. KIỂM TRA STORE_ID NULL
   Kết quả mong đợi: 0
   ============================================================ */

SELECT
    COUNT(*) AS Null_Store_ID
FROM dbo.Dim_Store
WHERE Store_ID IS NULL;
GO


/* ============================================================
   9. KIỂM TRA BẢN GHI UNKNOWN
   Kết quả mong đợi: 1 dòng
   ============================================================ */

SELECT *
FROM dbo.Dim_Store
WHERE Store_ID = -1;
GO


/* ============================================================
   10. KIỂM TRA SỐ CỬA HÀNG VÀ QUỐC GIA
   Không tính dòng Unknown
   ============================================================ */

SELECT
    COUNT(*) AS So_Cua_Hang,
    COUNT(DISTINCT Country) AS So_Quoc_Gia
FROM dbo.Dim_Store
WHERE Store_ID <> -1;
GO


/* ============================================================
   11. KIỂM TRA TỔNG SỐ NHÂN VIÊN

   Kết quả mong đợi:
       404
   ============================================================ */

SELECT
    SUM(Employee_Count) AS Tong_Nhan_Vien
FROM dbo.Dim_Store
WHERE Store_ID <> -1;
GO


/* ============================================================
   12. ĐỐI CHIẾU SỐ NHÂN VIÊN
       stores gốc vs employees thực tế
   ============================================================ */

SELECT
    TRY_CONVERT(INT, s.Store_ID) AS Store_ID,
    s.Store_Name,

    TRY_CONVERT(INT, s.Number_Of_Employees)
        AS Employees_From_Stores,

    d.Employee_Count
        AS Employees_From_Employees,

    d.Employee_Count
        - TRY_CONVERT(INT, s.Number_Of_Employees)
        AS Difference

FROM Fashion_Staging.stg.stores AS s

INNER JOIN dbo.Dim_Store AS d
    ON d.Store_ID = TRY_CONVERT(INT, s.Store_ID)

ORDER BY TRY_CONVERT(INT, s.Store_ID);
GO


/* ============================================================
   13. KIỂM TRA STORE CÓ 0 NHÂN VIÊN
   Kết quả mong đợi: 0 dòng
   ============================================================ */

SELECT
    Store_ID,
    Store_Name,
    Employee_Count
FROM dbo.Dim_Store
WHERE Store_ID <> -1
  AND Employee_Count = 0;
GO


/* ============================================================
   14. XEM DỮ LIỆU MẪU
   ============================================================ */

SELECT TOP (20)
    Store_Key,
    Store_ID,
    Store_Name,
    City,
    Country,
    Country_Code,
    ZIP_Code,
    Latitude,
    Longitude,
    Employee_Count
FROM dbo.Dim_Store
ORDER BY Store_Key;
GO


/* ============================================================
   15. ĐỐI SOÁT STG -> DW
   ============================================================ */

SELECT
    (SELECT COUNT(*)
     FROM Fashion_Staging.stg.stores)
        AS STG_Stores,

    (SELECT COUNT(*)
     FROM dbo.Dim_Store
     WHERE Store_ID <> -1)
        AS DW_Stores,

    (SELECT COUNT(*)
     FROM dbo.Dim_Store)
        AS DW_Including_Unknown;
GO