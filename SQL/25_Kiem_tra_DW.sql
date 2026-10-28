USE Fashion_DW;
GO

/* ============================================================
   25 - KIỂM TRA DATA WAREHOUSE
   ============================================================ */


/* ============================================================
   1. KIỂM TRA SỐ DÒNG CÁC BẢNG
   ============================================================ */

SELECT N'Dim_Customer' AS Bang, COUNT(*) AS SoDong
FROM dbo.Dim_Customer

UNION ALL

SELECT N'Dim_Product', COUNT(*)
FROM dbo.Dim_Product

UNION ALL

SELECT N'Dim_Store', COUNT(*)
FROM dbo.Dim_Store

UNION ALL

SELECT N'Dim_Employee', COUNT(*)
FROM dbo.Dim_Employee

UNION ALL

SELECT N'Dim_Date', COUNT(*)
FROM dbo.Dim_Date

UNION ALL

SELECT N'Fact_Sales', COUNT(*)
FROM dbo.Fact_Sales;
GO


/* ============================================================
   2. ĐỐI SOÁT STAGING VỚI DATA WAREHOUSE
   ============================================================ */

SELECT
    N'Customer' AS Bang,
    (SELECT COUNT(*) 
     FROM Fashion_Staging.stg.customers) AS SoDong_STG,

    (SELECT COUNT(*) 
     FROM dbo.Dim_Customer) AS SoDong_DW,

    CASE
        WHEN
            (SELECT COUNT(*) 
             FROM Fashion_Staging.stg.customers)
            =
            (SELECT COUNT(*) 
             FROM dbo.Dim_Customer)
        THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END AS KetQua

UNION ALL

SELECT
    N'Product',
    (SELECT COUNT(*) FROM Fashion_Staging.stg.products),
    (SELECT COUNT(*) FROM dbo.Dim_Product),

    CASE
        WHEN
            (SELECT COUNT(*) FROM Fashion_Staging.stg.products)
            =
            (SELECT COUNT(*) FROM dbo.Dim_Product)
        THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END

UNION ALL

SELECT
    N'Store',
    (SELECT COUNT(*) FROM Fashion_Staging.stg.stores),
    (SELECT COUNT(*) FROM dbo.Dim_Store),

    CASE
        WHEN
            (SELECT COUNT(*) FROM Fashion_Staging.stg.stores)
            =
            (SELECT COUNT(*) FROM dbo.Dim_Store)
        THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END

UNION ALL

SELECT
    N'Employee',
    (SELECT COUNT(*) FROM Fashion_Staging.stg.employees),
    (SELECT COUNT(*) FROM dbo.Dim_Employee),

    CASE
        WHEN
            (SELECT COUNT(*) FROM Fashion_Staging.stg.employees)
            =
            (SELECT COUNT(*) FROM dbo.Dim_Employee)
        THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END

UNION ALL

SELECT
    N'Transactions',
    (SELECT COUNT(*) FROM Fashion_Staging.stg.transactions),
    (SELECT COUNT(*) FROM dbo.Fact_Sales),

    CASE
        WHEN
            (SELECT COUNT(*) FROM Fashion_Staging.stg.transactions)
            =
            (SELECT COUNT(*) FROM dbo.Fact_Sales)
        THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END;
GO


/* ============================================================
   3. KIỂM TRA KHÓA NGOẠI TRONG FACT_SALES
   ============================================================ */

SELECT
    SUM(CASE WHEN Customer_Key IS NULL THEN 1 ELSE 0 END)
        AS Thieu_Khoa_Khach_Hang,

    SUM(CASE WHEN Product_Key IS NULL THEN 1 ELSE 0 END)
        AS Thieu_Khoa_San_Pham,

    SUM(CASE WHEN Store_Key IS NULL THEN 1 ELSE 0 END)
        AS Thieu_Khoa_Cua_Hang,

    SUM(CASE WHEN Employee_Key IS NULL THEN 1 ELSE 0 END)
        AS Thieu_Khoa_Nhan_Vien,

    SUM(CASE WHEN Date_Key IS NULL THEN 1 ELSE 0 END)
        AS Thieu_Khoa_Ngay

FROM dbo.Fact_Sales;
GO


/* ============================================================
   4. KIỂM TRA BẢN GHI FACT KHÔNG TÌM THẤY DIMENSION
   ============================================================ */

SELECT
    SUM(CASE WHEN c.Customer_Key IS NULL THEN 1 ELSE 0 END)
        AS Khong_Tim_Thay_Khach_Hang,

    SUM(CASE WHEN p.Product_Key IS NULL THEN 1 ELSE 0 END)
        AS Khong_Tim_Thay_San_Pham,

    SUM(CASE WHEN s.Store_Key IS NULL THEN 1 ELSE 0 END)
        AS Khong_Tim_Thay_Cua_Hang,

    SUM(CASE WHEN e.Employee_Key IS NULL THEN 1 ELSE 0 END)
        AS Khong_Tim_Thay_Nhan_Vien,

    SUM(CASE WHEN d.Date_Key IS NULL THEN 1 ELSE 0 END)
        AS Khong_Tim_Thay_Ngay

FROM dbo.Fact_Sales f

LEFT JOIN dbo.Dim_Customer c
    ON f.Customer_Key = c.Customer_Key

LEFT JOIN dbo.Dim_Product p
    ON f.Product_Key = p.Product_Key

LEFT JOIN dbo.Dim_Store s
    ON f.Store_Key = s.Store_Key

LEFT JOIN dbo.Dim_Employee e
    ON f.Employee_Key = e.Employee_Key

LEFT JOIN dbo.Dim_Date d
    ON f.Date_Key = d.Date_Key;
GO


/* ============================================================
   5. KIỂM TRA TRÙNG KHÓA NGHIỆP VỤ TRONG DIMENSION
   ============================================================ */

SELECT Customer_ID, COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Customer
GROUP BY Customer_ID
HAVING COUNT(*) > 1;
GO

SELECT Product_ID, COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Product
GROUP BY Product_ID
HAVING COUNT(*) > 1;
GO

SELECT Store_ID, COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Store
GROUP BY Store_ID
HAVING COUNT(*) > 1;
GO

SELECT Employee_ID, COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Employee
GROUP BY Employee_ID
HAVING COUNT(*) > 1;
GO

SELECT Date_Key, COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Date
GROUP BY Date_Key
HAVING COUNT(*) > 1;
GO


/* ============================================================
   6. KIỂM TRA BÁN HÀNG VÀ TRẢ HÀNG
   ============================================================ */

SELECT
    Transaction_Type AS Loai_Giao_Dich,
    COUNT(*) AS SoDong,
    SUM(Sales_Quantity) AS Tong_So_Luong_Ban,
    SUM(Return_Quantity) AS Tong_So_Luong_Tra,
    SUM(Net_Amount_USD) AS Doanh_Thu_Thuan_USD
FROM dbo.Fact_Sales
GROUP BY Transaction_Type;
GO


/* ============================================================
   7. KIỂM TRA TỔNG DOANH THU
   ============================================================ */

SELECT
    SUM(Net_Amount) AS Tong_Doanh_Thu,
    SUM(Net_Amount_Local) AS Tong_Doanh_Thu_Noi_Te,
    SUM(Net_Amount_USD) AS Tong_Doanh_Thu_USD,
    SUM(Sales_Quantity) AS Tong_So_Luong_Ban,
    SUM(Return_Quantity) AS Tong_So_Luong_Tra
FROM dbo.Fact_Sales;
GO


/* ============================================================
   8. KIỂM TRA KHOẢNG THỜI GIAN
   ============================================================ */

SELECT
    MIN(Full_Date) AS Ngay_Dau,
    MAX(Full_Date) AS Ngay_Cuoi,
    COUNT(*) AS Tong_So_Ngay
FROM dbo.Dim_Date;
GO


/* ============================================================
   9. KIỂM TRA 5 FOREIGN KEY
   ============================================================ */

SELECT
    fk.name AS Ten_Khoa_Ngoai,
    OBJECT_NAME(fk.parent_object_id) AS Bang_Fact,
    COL_NAME(
        fkc.parent_object_id,
        fkc.parent_column_id
    ) AS Cot_Fact,

    OBJECT_NAME(fk.referenced_object_id) AS Bang_Dimension,

    COL_NAME(
        fkc.referenced_object_id,
        fkc.referenced_column_id
    ) AS Cot_Dimension

FROM sys.foreign_keys fk

JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id

WHERE fk.parent_object_id = OBJECT_ID('dbo.Fact_Sales');
GO


/* ============================================================
   10. XEM DỮ LIỆU FACT MẪU
   ============================================================ */

SELECT TOP 20 *
FROM dbo.Fact_Sales
ORDER BY Sales_Key;
GO