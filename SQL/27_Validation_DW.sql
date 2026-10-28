USE Fashion_DW;
GO

/* ============================================================
   27 - VALIDATION DATA WAREHOUSE
   Dự án: Fashion Retail Data Warehouse

   Mục tiêu:
       Kiểm tra toàn bộ DW sau khi ETL hoàn tất.

   Các bảng:
       Dim_Customer
       Dim_Product
       Dim_Store
       Dim_Employee
       Dim_Date
       Dim_Promotion
       Dim_Payment
       Dim_Currency
       Fact_Sales

   Grain Fact_Sales:
       Một dòng dữ liệu trong Fact_Sales đại diện cho một
       sản phẩm với kích cỡ và màu sắc cụ thể, được bán hoặc
       nhận trả lại trên một hóa đơn, vào một ngày/thời gian
       giao dịch, tại một cửa hàng, bởi một nhân viên bán hàng,
       cho một khách hàng, có áp dụng chương trình khuyến mãi
       nếu có, sử dụng một phương thức thanh toán và được ghi
       nhận theo một loại tiền tệ giao dịch.
   ============================================================ */


/* ============================================================
   1. KIỂM TRA SỐ DÒNG TẤT CẢ DIMENSION + FACT
   ============================================================ */

SELECT
    'Dim_Customer' AS Table_Name,
    COUNT_BIG(*) AS Row_Count
FROM dbo.Dim_Customer

UNION ALL

SELECT
    'Dim_Product',
    COUNT_BIG(*)
FROM dbo.Dim_Product

UNION ALL

SELECT
    'Dim_Store',
    COUNT_BIG(*)
FROM dbo.Dim_Store

UNION ALL

SELECT
    'Dim_Employee',
    COUNT_BIG(*)
FROM dbo.Dim_Employee

UNION ALL

SELECT
    'Dim_Date',
    COUNT_BIG(*)
FROM dbo.Dim_Date

UNION ALL

SELECT
    'Dim_Promotion',
    COUNT_BIG(*)
FROM dbo.Dim_Promotion

UNION ALL

SELECT
    'Dim_Payment',
    COUNT_BIG(*)
FROM dbo.Dim_Payment

UNION ALL

SELECT
    'Dim_Currency',
    COUNT_BIG(*)
FROM dbo.Dim_Currency

UNION ALL

SELECT
    'Fact_Sales',
    COUNT_BIG(*)
FROM dbo.Fact_Sales;
GO


/* ============================================================
   2. ĐỐI SOÁT STG TRANSACTIONS -> FACT

   Hai số phải bằng nhau.
   ============================================================ */

SELECT
    (
        SELECT COUNT_BIG(*)
        FROM Fashion_Staging.stg.transactions
    ) AS STG_Transactions,

    (
        SELECT COUNT_BIG(*)
        FROM dbo.Fact_Sales
    ) AS DW_Fact_Sales,

    (
        SELECT COUNT_BIG(*)
        FROM Fashion_Staging.stg.transactions
    )
    -
    (
        SELECT COUNT_BIG(*)
        FROM dbo.Fact_Sales
    ) AS Difference;
GO


/* ============================================================
   3. KIỂM TRA PRIMARY KEY DUPLICATE TRONG DIM
   ============================================================ */

SELECT
    Customer_ID,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Customer
GROUP BY Customer_ID
HAVING COUNT(*) > 1;
GO


SELECT
    Product_ID,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Product
GROUP BY Product_ID
HAVING COUNT(*) > 1;
GO


SELECT
    Store_ID,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Store
GROUP BY Store_ID
HAVING COUNT(*) > 1;
GO


SELECT
    Employee_ID,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Employee
GROUP BY Employee_ID
HAVING COUNT(*) > 1;
GO


SELECT
    Date_Key,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Date
GROUP BY Date_Key
HAVING COUNT(*) > 1;
GO


SELECT
    Currency_Code,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Currency
GROUP BY Currency_Code
HAVING COUNT(*) > 1;
GO


SELECT
    Payment_Method,
    Transaction_Type,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Payment
GROUP BY
    Payment_Method,
    Transaction_Type
HAVING COUNT(*) > 1;
GO


/* ============================================================
   4. KIỂM TRA FACT KHÔNG CÓ FOREIGN KEY NULL
   ============================================================ */

SELECT
    SUM(CASE WHEN Date_Key IS NULL THEN 1 ELSE 0 END)
        AS Null_Date_Key,

    SUM(CASE WHEN Product_Key IS NULL THEN 1 ELSE 0 END)
        AS Null_Product_Key,

    SUM(CASE WHEN Store_Key IS NULL THEN 1 ELSE 0 END)
        AS Null_Store_Key,

    SUM(CASE WHEN Customer_Key IS NULL THEN 1 ELSE 0 END)
        AS Null_Customer_Key,

    SUM(CASE WHEN Employee_Key IS NULL THEN 1 ELSE 0 END)
        AS Null_Employee_Key,

    SUM(CASE WHEN Promotion_Key IS NULL THEN 1 ELSE 0 END)
        AS Null_Promotion_Key,

    SUM(CASE WHEN Payment_Key IS NULL THEN 1 ELSE 0 END)
        AS Null_Payment_Key,

    SUM(CASE WHEN Currency_Key IS NULL THEN 1 ELSE 0 END)
        AS Null_Currency_Key

FROM dbo.Fact_Sales;
GO


/* ============================================================
   5. KIỂM TRA ORPHAN FOREIGN KEY

   Tất cả phải = 0.
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Orphan_Date
FROM dbo.Fact_Sales AS f
LEFT JOIN dbo.Dim_Date AS d
    ON f.Date_Key = d.Date_Key
WHERE d.Date_Key IS NULL;
GO


SELECT
    COUNT_BIG(*) AS Orphan_Product
FROM dbo.Fact_Sales AS f
LEFT JOIN dbo.Dim_Product AS d
    ON f.Product_Key = d.Product_Key
WHERE d.Product_Key IS NULL;
GO


SELECT
    COUNT_BIG(*) AS Orphan_Store
FROM dbo.Fact_Sales AS f
LEFT JOIN dbo.Dim_Store AS d
    ON f.Store_Key = d.Store_Key
WHERE d.Store_Key IS NULL;
GO


SELECT
    COUNT_BIG(*) AS Orphan_Customer
FROM dbo.Fact_Sales AS f
LEFT JOIN dbo.Dim_Customer AS d
    ON f.Customer_Key = d.Customer_Key
WHERE d.Customer_Key IS NULL;
GO


SELECT
    COUNT_BIG(*) AS Orphan_Employee
FROM dbo.Fact_Sales AS f
LEFT JOIN dbo.Dim_Employee AS d
    ON f.Employee_Key = d.Employee_Key
WHERE d.Employee_Key IS NULL;
GO


SELECT
    COUNT_BIG(*) AS Orphan_Promotion
FROM dbo.Fact_Sales AS f
LEFT JOIN dbo.Dim_Promotion AS d
    ON f.Promotion_Key = d.Promotion_Key
WHERE d.Promotion_Key IS NULL;
GO


SELECT
    COUNT_BIG(*) AS Orphan_Payment
FROM dbo.Fact_Sales AS f
LEFT JOIN dbo.Dim_Payment AS d
    ON f.Payment_Key = d.Payment_Key
WHERE d.Payment_Key IS NULL;
GO


SELECT
    COUNT_BIG(*) AS Orphan_Currency
FROM dbo.Fact_Sales AS f
LEFT JOIN dbo.Dim_Currency AS d
    ON f.Currency_Key = d.Currency_Key
WHERE d.Currency_Key IS NULL;
GO


/* ============================================================
   6. KIỂM TRA UNKNOWN DIMENSIONS
   ============================================================ */

DECLARE @UnknownCustomerKey INT;
DECLARE @UnknownProductKey INT;
DECLARE @UnknownStoreKey INT;
DECLARE @UnknownEmployeeKey INT;
DECLARE @UnknownPaymentKey INT;
DECLARE @UnknownCurrencyKey INT;

SELECT @UnknownCustomerKey = Customer_Key
FROM dbo.Dim_Customer
WHERE Customer_ID = -1;

SELECT @UnknownProductKey = Product_Key
FROM dbo.Dim_Product
WHERE Product_ID = -1;

SELECT @UnknownStoreKey = Store_Key
FROM dbo.Dim_Store
WHERE Store_ID = -1;

SELECT @UnknownEmployeeKey = Employee_Key
FROM dbo.Dim_Employee
WHERE Employee_ID = -1;

SELECT @UnknownPaymentKey = Payment_Key
FROM dbo.Dim_Payment
WHERE Payment_Method = N'Unknown'
  AND Transaction_Type = N'Unknown';

SELECT @UnknownCurrencyKey = Currency_Key
FROM dbo.Dim_Currency
WHERE Currency_Code = 'UNK';


SELECT
    SUM(
        CASE
            WHEN Customer_Key = @UnknownCustomerKey
                THEN 1 ELSE 0
        END
    ) AS Unknown_Customer,

    SUM(
        CASE
            WHEN Product_Key = @UnknownProductKey
                THEN 1 ELSE 0
        END
    ) AS Unknown_Product,

    SUM(
        CASE
            WHEN Store_Key = @UnknownStoreKey
                THEN 1 ELSE 0
        END
    ) AS Unknown_Store,

    SUM(
        CASE
            WHEN Employee_Key = @UnknownEmployeeKey
                THEN 1 ELSE 0
        END
    ) AS Unknown_Employee,

    SUM(
        CASE
            WHEN Payment_Key = @UnknownPaymentKey
                THEN 1 ELSE 0
        END
    ) AS Unknown_Payment,

    SUM(
        CASE
            WHEN Currency_Key = @UnknownCurrencyKey
                THEN 1 ELSE 0
        END
    ) AS Unknown_Currency

FROM dbo.Fact_Sales;
GO


/* ============================================================
   7. KIỂM TRA EMPLOYEE THUỘC ĐÚNG STORE

   Mong đợi = 0.
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Employee_Store_Mismatch

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Employee AS e
    ON f.Employee_Key = e.Employee_Key

INNER JOIN dbo.Dim_Store AS s
    ON f.Store_Key = s.Store_Key

WHERE e.Employee_ID <> -1
  AND s.Store_ID <> -1
  AND e.Store_ID <> s.Store_ID;
GO


/* ============================================================
   8. KIỂM TRA DATE RANGE
   ============================================================ */

SELECT
    MIN(Full_Date) AS Min_Date,
    MAX(Full_Date) AS Max_Date,
    COUNT(*) AS Total_Days

FROM dbo.Dim_Date;
GO


/* ============================================================
   9. KIỂM TRA DATE_KEY FORMAT
   ============================================================ */

SELECT
    Date_Key,
    Full_Date

FROM dbo.Dim_Date

WHERE Date_Key <>
      YEAR(Full_Date) * 10000
      + MONTH(Full_Date) * 100
      + DAY(Full_Date);
GO


/* ============================================================
   10. SALE / RETURN SUMMARY
   ============================================================ */

SELECT
    p.Transaction_Type,

    COUNT_BIG(*) AS So_Dong,

    SUM(
        CAST(f.Quantity AS BIGINT)
    ) AS Quantity,

    SUM(
        CAST(f.Net_Quantity AS BIGINT)
    ) AS Net_Quantity,

    SUM(
        f.Net_Amount_Local
    ) AS Net_Amount_Local,

    SUM(
        f.Net_Amount_USD
    ) AS Net_Amount_USD

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Payment AS p
    ON f.Payment_Key = p.Payment_Key

GROUP BY p.Transaction_Type

ORDER BY p.Transaction_Type;
GO


/* ============================================================
   11. KIỂM TRA SIGN FLAG
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Invalid_Sign_Flag

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Payment AS p
    ON f.Payment_Key = p.Payment_Key

WHERE
       (
           p.Transaction_Type = 'Sale'
           AND f.Sign_Flag <> 1
       )

    OR (
           p.Transaction_Type = 'Return'
           AND f.Sign_Flag <> -1
       );
GO


/* ============================================================
   12. NET_QUANTITY = QUANTITY * SIGN_FLAG

   Mong đợi = 0.
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Invalid_Net_Quantity

FROM dbo.Fact_Sales

WHERE Net_Quantity <>
      Quantity * Sign_Flag;
GO


/* ============================================================
   13. KIỂM TRA DẤU NET AMOUNT

   Sale   > 0
   Return < 0

   Mong đợi = 0 / 0.
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN p.Transaction_Type = 'Sale'
             AND f.Net_Amount <= 0
                THEN 1 ELSE 0
        END
    ) AS Sale_Sai_Dau,

    SUM(
        CASE
            WHEN p.Transaction_Type = 'Return'
             AND f.Net_Amount >= 0
                THEN 1 ELSE 0
        END
    ) AS Return_Sai_Dau

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Payment AS p
    ON f.Payment_Key = p.Payment_Key;
GO


/* ============================================================
   14. QUANTITY / UNIT PRICE / DISCOUNT DOMAIN
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN Quantity <= 0
                THEN 1 ELSE 0
        END
    ) AS Invalid_Quantity,

    SUM(
        CASE
            WHEN Unit_Price <= 0
                THEN 1 ELSE 0
        END
    ) AS Invalid_Unit_Price,

    SUM(
        CASE
            WHEN Discount_Rate < 0
              OR Discount_Rate > 1
                THEN 1 ELSE 0
        END
    ) AS Invalid_Discount

FROM dbo.Fact_Sales;
GO


/* ============================================================
   15. KIỂM TRA TIỀN TỆ
   ============================================================ */

SELECT
    c.Currency_Code,

    COUNT_BIG(*) AS So_Giao_Dich,

    SUM(f.Net_Amount_Local)
        AS Net_Amount_Local,

    SUM(f.Net_Amount_USD)
        AS Net_Amount_USD

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Currency AS c
    ON f.Currency_Key = c.Currency_Key

GROUP BY c.Currency_Code

ORDER BY c.Currency_Code;
GO


/* ============================================================
   16. KIỂM TRA TỶ GIÁ
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN Exchange_Rate_To_USD IS NULL
                THEN 1 ELSE 0
        END
    ) AS Missing_Exchange_Rate,

    SUM(
        CASE
            WHEN Exchange_Rate_To_USD <= 0
                THEN 1 ELSE 0
        END
    ) AS Invalid_Exchange_Rate,

    SUM(
        CASE
            WHEN Exchange_Rate_Date IS NULL
                THEN 1 ELSE 0
        END
    ) AS Missing_Exchange_Rate_Date,

    SUM(
        CASE
            WHEN Exchange_Rate_Source IS NULL
                THEN 1 ELSE 0
        END
    ) AS Missing_Exchange_Rate_Source,

    SUM(
        CASE
            WHEN Net_Amount_USD IS NULL
                THEN 1 ELSE 0
        END
    ) AS Missing_Net_Amount_USD

FROM dbo.Fact_Sales;
GO


/* ============================================================
   17. USD PHẢI RATE = 1

   Mong đợi = 0.
   ============================================================ */

SELECT
    COUNT_BIG(*) AS USD_Rate_Not_One

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Currency AS c
    ON f.Currency_Key = c.Currency_Key

WHERE c.Currency_Code = 'USD'

AND ABS(
    f.Exchange_Rate_To_USD - 1
) > 0.00000001;
GO


/* ============================================================
   18. KIỂM TRA CÔNG THỨC USD

   Net_Amount_USD
   =
   Net_Amount_Local × Exchange_Rate_To_USD

   Cho phép sai số 0.01.
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Invalid_USD_Conversion

FROM dbo.Fact_Sales

WHERE ABS
(
    Net_Amount_USD
    -
    (
        Net_Amount_Local
        * Exchange_Rate_To_USD
    )
) > 0.01;
GO


/* ============================================================
   19. KIỂM TRA PAYMENT COMBINATION
   ============================================================ */

SELECT
    p.Payment_Method,
    p.Transaction_Type,

    COUNT_BIG(*) AS So_Giao_Dich

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Payment AS p
    ON f.Payment_Key = p.Payment_Key

GROUP BY
    p.Payment_Method,
    p.Transaction_Type

ORDER BY
    p.Payment_Method,
    p.Transaction_Type;
GO


/* ============================================================
   20. KIỂM TRA PROMOTION SUMMARY
   ============================================================ */

SELECT
    p.Promotion_Name,

    COUNT_BIG(*) AS So_Dong,

    SUM(f.Net_Amount_USD)
        AS Net_Amount_USD

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Promotion AS p
    ON f.Promotion_Key = p.Promotion_Key

GROUP BY p.Promotion_Name

ORDER BY So_Dong DESC;
GO


/* ============================================================
   21. GLOBAL PROMOTION

   Mong đợi Dim_Promotion có 10 dòng global.
   ============================================================ */

SELECT
    COUNT(*) AS Global_Promotion_Rows

FROM dbo.Dim_Promotion

WHERE Promotion_Name NOT IN
(
    N'Unknown',
    N'No Promotion'
)

AND Category IS NULL
AND Sub_Category IS NULL;
GO


/* ============================================================
   22. RETURN PHẢI DÙNG UNKNOWN PROMOTION

   Theo thiết kế hiện tại:
   Return chưa lookup về Sale gốc nên dùng Unknown.

   Mong đợi = 0.
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Return_Not_Unknown_Promotion

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Payment AS pay
    ON f.Payment_Key = pay.Payment_Key

INNER JOIN dbo.Dim_Promotion AS p
    ON f.Promotion_Key = p.Promotion_Key

WHERE pay.Transaction_Type = 'Return'
AND p.Promotion_Name <> N'Unknown';
GO


/* ============================================================
   23. SALE NO PROMOTION

   Đây KHÔNG PHẢI lỗi.

   Chỉ thống kê số giao dịch Sale không thuộc promotion.
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Sale_No_Promotion

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Payment AS pay
    ON f.Payment_Key = pay.Payment_Key

INNER JOIN dbo.Dim_Promotion AS p
    ON f.Promotion_Key = p.Promotion_Key

WHERE pay.Transaction_Type = 'Sale'
AND p.Promotion_Name = N'No Promotion';
GO


/* ============================================================
   24. KIỂM TRA SALE BỊ UNKNOWN PROMOTION

   Sale phải:
       Promotion thật
       HOẶC No Promotion

   Không nên là Unknown.

   Mong đợi = 0.
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Sale_Unknown_Promotion

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Payment AS pay
    ON f.Payment_Key = pay.Payment_Key

INNER JOIN dbo.Dim_Promotion AS p
    ON f.Promotion_Key = p.Promotion_Key

WHERE pay.Transaction_Type = 'Sale'
AND p.Promotion_Name = N'Unknown';
GO


/* ============================================================
   25. KIỂM TRA SỐ NHÂN VIÊN THEO STORE
   ============================================================ */

SELECT
    s.Store_ID,
    s.Store_Name,

    s.Employee_Count
        AS Store_Employee_Count,

    COUNT(e.Employee_ID)
        AS Dim_Employee_Count,

    COUNT(e.Employee_ID)
        - s.Employee_Count
        AS Difference

FROM dbo.Dim_Store AS s

LEFT JOIN dbo.Dim_Employee AS e
    ON s.Store_ID = e.Store_ID
   AND e.Employee_ID <> -1

WHERE s.Store_ID <> -1

GROUP BY
    s.Store_ID,
    s.Store_Name,
    s.Employee_Count

ORDER BY s.Store_ID;
GO


/* ============================================================
   26. KIỂM TRA STORE EMPLOYEE COUNT KHÔNG KHỚP

   Mong đợi = 0 cửa hàng.
   ============================================================ */

WITH EmployeeCount AS
(
    SELECT
        Store_ID,
        COUNT(*) AS Employee_Count

    FROM dbo.Dim_Employee

    WHERE Employee_ID <> -1

    GROUP BY Store_ID
)

SELECT
    COUNT(*) AS Store_Employee_Count_Mismatch

FROM dbo.Dim_Store AS s

LEFT JOIN EmployeeCount AS e
    ON s.Store_ID = e.Store_ID

WHERE s.Store_ID <> -1

AND s.Employee_Count <>
    ISNULL(e.Employee_Count, 0);
GO


/* ============================================================
   27. KIỂM TRA FACT THEO NĂM
   ============================================================ */

SELECT
    d.Year_Number,

    COUNT_BIG(*) AS So_Giao_Dich,

    SUM(f.Net_Quantity)
        AS Net_Quantity,

    SUM(f.Net_Amount_USD)
        AS Net_Sales_USD

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Date AS d
    ON f.Date_Key = d.Date_Key

GROUP BY d.Year_Number

ORDER BY d.Year_Number;
GO


/* ============================================================
   28. KIỂM TRA FACT THEO STORE
   ============================================================ */

SELECT
    s.Store_ID,
    s.Store_Name,
    s.Country,

    COUNT_BIG(*) AS So_Giao_Dich,

    SUM(f.Net_Amount_USD)
        AS Net_Sales_USD

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Store AS s
    ON f.Store_Key = s.Store_Key

WHERE s.Store_ID <> -1

GROUP BY
    s.Store_ID,
    s.Store_Name,
    s.Country

ORDER BY Net_Sales_USD DESC;
GO


/* ============================================================
   29. KIỂM TRA FACT THEO PRODUCT CATEGORY
   ============================================================ */

SELECT
    p.Category,

    COUNT_BIG(*) AS So_Giao_Dich,

    SUM(f.Net_Quantity)
        AS Net_Quantity,

    SUM(f.Net_Amount_USD)
        AS Net_Sales_USD

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Product AS p
    ON f.Product_Key = p.Product_Key

WHERE p.Product_ID <> -1

GROUP BY p.Category

ORDER BY Net_Sales_USD DESC;
GO


/* ============================================================
   30. KIỂM TRA GRAIN - INVOICE / LINE

   Đây chỉ là thống kê.

   Vì Return có thể tái xuất hiện theo ngày khác nhau,
   không mặc định Invoice_ID + Line_Number là duy nhất tuyệt đối.
   ============================================================ */

SELECT TOP (100)
    Invoice_ID,
    Line_Number,

    COUNT(*) AS SoLanXuatHien

FROM dbo.Fact_Sales

GROUP BY
    Invoice_ID,
    Line_Number

HAVING COUNT(*) > 1

ORDER BY SoLanXuatHien DESC;
GO


/* ============================================================
   31. KIỂM TRA DUPLICATE THEO GRAIN FACT_SALES

   Grain hiện tại gồm:
       Invoice + Line
       Product + Size + Color
       Date + Hour
       Store
       Employee
       Customer
       Promotion
       Payment
       Currency
       Sale / Return

   Nếu query trả dòng thì mới cần kiểm tra tiếp.
   ============================================================ */

SELECT TOP (100)

    Invoice_ID,
    Line_Number,

    Date_Key,
    Hour_Of_Day,

    Product_Key,
    Size,
    Color,

    Store_Key,
    Employee_Key,
    Customer_Key,

    Promotion_Key,
    Payment_Key,
    Currency_Key,

    Sign_Flag,

    COUNT(*) AS Duplicate_Count

FROM dbo.Fact_Sales

GROUP BY
    Invoice_ID,
    Line_Number,

    Date_Key,
    Hour_Of_Day,

    Product_Key,
    Size,
    Color,

    Store_Key,
    Employee_Key,
    Customer_Key,

    Promotion_Key,
    Payment_Key,
    Currency_Key,

    Sign_Flag

HAVING COUNT(*) > 1

ORDER BY Duplicate_Count DESC;
GO
/* ============================================================
   32. FINAL VALIDATION SUMMARY
   ============================================================ */

SELECT
    (SELECT COUNT_BIG(*)
     FROM Fashion_Staging.stg.transactions)
        AS STG_Rows,

    (SELECT COUNT_BIG(*)
     FROM dbo.Fact_Sales)
        AS Fact_Rows,

    (SELECT COUNT(*)
     FROM dbo.Dim_Customer)
        AS Dim_Customer_Rows,

    (SELECT COUNT(*)
     FROM dbo.Dim_Product)
        AS Dim_Product_Rows,

    (SELECT COUNT(*)
     FROM dbo.Dim_Store)
        AS Dim_Store_Rows,

    (SELECT COUNT(*)
     FROM dbo.Dim_Employee)
        AS Dim_Employee_Rows,

    (SELECT COUNT(*)
     FROM dbo.Dim_Date)
        AS Dim_Date_Rows,

    (SELECT COUNT(*)
     FROM dbo.Dim_Promotion)
        AS Dim_Promotion_Rows,

    (SELECT COUNT(*)
     FROM dbo.Dim_Payment)
        AS Dim_Payment_Rows,

    (SELECT COUNT(*)
     FROM dbo.Dim_Currency)
        AS Dim_Currency_Rows;
GO


/* ============================================================
   33. THÔNG BÁO HOÀN TẤT
   ============================================================ */

PRINT N'===============================================';
PRINT N'HOÀN TẤT VALIDATION FASHION DATA WAREHOUSE';
PRINT N'===============================================';
GO