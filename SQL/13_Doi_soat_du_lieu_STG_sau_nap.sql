/* ============================================================
   FILE: 13_Doi_soat_du_lieu_STG_sau_nap.sql

   MỤC ĐÍCH:
   - Đối soát dữ liệu sau khi nạp cleaned CSV vào STG.
   - Kiểm tra số dòng.
   - Kiểm tra NULL khóa.
   - Kiểm tra duplicate.
   - Kiểm tra quan hệ tham chiếu.
   - Kiểm tra quốc gia / tiền tệ.
   - Kiểm tra tỷ giá và Net Amount USD.

   DATABASE:
   Fashion_Staging
   ============================================================ */

USE Fashion_Staging;
GO


/* ============================================================
   1. KIỂM TRA SỐ DÒNG
   ============================================================ */

PRINT N'1. KIỂM TRA SỐ DÒNG';
PRINT N'------------------------------------------------------------';


SELECT
    'customers' AS Bang,
    COUNT(*) AS SoDong
FROM stg.customers

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM stg.products

UNION ALL

SELECT
    'stores',
    COUNT(*)
FROM stg.stores

UNION ALL

SELECT
    'employees',
    COUNT(*)
FROM stg.employees

UNION ALL

SELECT
    'discounts',
    COUNT(*)
FROM stg.discounts

UNION ALL

SELECT
    'transactions',
    COUNT(*)
FROM stg.transactions;
GO



/* ============================================================
   2. SỐ DÒNG KỲ VỌNG TỪ CLEANED
   ============================================================ */

PRINT N'2. SỐ DÒNG KỲ VỌNG';
PRINT N'------------------------------------------------------------';


SELECT
    'customers' AS Bang,
    1643306 AS SoDongKyVong

UNION ALL
SELECT
    'products',
    17940

UNION ALL
SELECT
    'stores',
    35

UNION ALL
SELECT
    'employees',
    404

UNION ALL
SELECT
    'discounts',
    181

UNION ALL
SELECT
    'transactions',
    6416029;
GO



/* ============================================================
   3. KIỂM TRA NULL CUSTOMER_ID
   ============================================================ */

PRINT N'3. CUSTOMER_ID';

SELECT
    COUNT(*) AS TongDong,

    SUM(
        CASE
            WHEN Customer_ID IS NULL
              OR LTRIM(RTRIM(Customer_ID)) = ''
            THEN 1
            ELSE 0
        END
    ) AS SoDongNull

FROM stg.customers;
GO



/* ============================================================
   4. KIỂM TRA TRÙNG CUSTOMER_ID
   ============================================================ */

SELECT
    Customer_ID,
    COUNT(*) AS SoLuong
FROM stg.customers
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID
HAVING COUNT(*) > 1;
GO



/* ============================================================
   5. KIỂM TRA PRODUCT_ID
   ============================================================ */

PRINT N'5. PRODUCT_ID';

SELECT
    COUNT(*) AS TongDong,

    SUM(
        CASE
            WHEN Product_ID IS NULL
              OR LTRIM(RTRIM(Product_ID)) = ''
            THEN 1
            ELSE 0
        END
    ) AS SoDongNull

FROM stg.products;
GO


SELECT
    Product_ID,
    COUNT(*) AS SoLuong
FROM stg.products
WHERE Product_ID IS NOT NULL
GROUP BY Product_ID
HAVING COUNT(*) > 1;
GO



/* ============================================================
   6. KIỂM TRA STORE_ID
   ============================================================ */

PRINT N'6. STORE_ID';

SELECT
    COUNT(*) AS TongDong,

    SUM(
        CASE
            WHEN Store_ID IS NULL
              OR LTRIM(RTRIM(Store_ID)) = ''
            THEN 1
            ELSE 0
        END
    ) AS SoDongNull

FROM stg.stores;
GO


SELECT
    Store_ID,
    COUNT(*) AS SoLuong
FROM stg.stores
WHERE Store_ID IS NOT NULL
GROUP BY Store_ID
HAVING COUNT(*) > 1;
GO



/* ============================================================
   7. KIỂM TRA EMPLOYEE_ID
   ============================================================ */

PRINT N'7. EMPLOYEE_ID';

SELECT
    COUNT(*) AS TongDong,

    SUM(
        CASE
            WHEN Employee_ID IS NULL
              OR LTRIM(RTRIM(Employee_ID)) = ''
            THEN 1
            ELSE 0
        END
    ) AS SoDongNull

FROM stg.employees;
GO


SELECT
    Employee_ID,
    COUNT(*) AS SoLuong
FROM stg.employees
WHERE Employee_ID IS NOT NULL
GROUP BY Employee_ID
HAVING COUNT(*) > 1;
GO



/* ============================================================
   8. KIỂM TRA TRANSACTIONS KHÔNG TÌM THẤY CUSTOMER
   ============================================================ */

PRINT N'8. TRANSACTIONS -> CUSTOMERS';

SELECT
    COUNT(*) AS SoGiaoDichKhongTimThayCustomer
FROM stg.transactions t

LEFT JOIN stg.customers c
    ON t.Customer_ID = c.Customer_ID

WHERE c.Customer_ID IS NULL;
GO



/* ============================================================
   9. TRANSACTIONS -> PRODUCTS
   ============================================================ */

PRINT N'9. TRANSACTIONS -> PRODUCTS';

SELECT
    COUNT(*) AS SoGiaoDichKhongTimThayProduct
FROM stg.transactions t

LEFT JOIN stg.products p
    ON t.Product_ID = p.Product_ID

WHERE p.Product_ID IS NULL;
GO



/* ============================================================
   10. TRANSACTIONS -> STORES
   ============================================================ */

PRINT N'10. TRANSACTIONS -> STORES';

SELECT
    COUNT(*) AS SoGiaoDichKhongTimThayStore
FROM stg.transactions t

LEFT JOIN stg.stores s
    ON t.Store_ID = s.Store_ID

WHERE s.Store_ID IS NULL;
GO



/* ============================================================
   11. TRANSACTIONS -> EMPLOYEES
   ============================================================ */

PRINT N'11. TRANSACTIONS -> EMPLOYEES';

SELECT
    COUNT(*) AS SoGiaoDichKhongTimThayEmployee
FROM stg.transactions t

LEFT JOIN stg.employees e
    ON t.Employee_ID = e.Employee_ID

WHERE e.Employee_ID IS NULL;
GO



/* ============================================================
   12. EMPLOYEE PHẢI THUỘC ĐÚNG STORE
   ============================================================ */

PRINT N'12. EMPLOYEE -> STORE';

SELECT
    COUNT(*) AS SoDongSaiStoreEmployee
FROM stg.transactions t

INNER JOIN stg.employees e
    ON t.Employee_ID = e.Employee_ID

WHERE t.Store_ID <> e.Store_ID;
GO



/* ============================================================
   13. KIỂM TRA COUNTRY_CODE
   ============================================================ */

PRINT N'13. COUNTRY_CODE';

SELECT
    Country_Code,
    COUNT(*) AS SoDong
FROM stg.transactions
GROUP BY Country_Code
ORDER BY Country_Code;
GO



/* ============================================================
   14. KIỂM TRA CURRENCY
   ============================================================ */

PRINT N'14. CURRENCY';

SELECT
    Currency,
    COUNT(*) AS SoDong
FROM stg.transactions
GROUP BY Currency
ORDER BY Currency;
GO



/* ============================================================
   15. CURRENCY KHÔNG HỢP LỆ
   ============================================================ */

PRINT N'15. CURRENCY KHÔNG HỢP LỆ';

SELECT
    COUNT(*) AS SoDongCurrencyKhongHopLe
FROM stg.transactions
WHERE Currency IS NULL
   OR LTRIM(RTRIM(Currency)) = ''
   OR Currency NOT IN
   (
       'USD',
       'EUR',
       'GBP',
       'CNY'
   );
GO



/* ============================================================
   16. CURRENCY KHÔNG KHỚP EXPECTED_CURRENCY
   ============================================================ */

PRINT N'16. CURRENCY KHÔNG KHỚP COUNTRY';

SELECT
    COUNT(*) AS SoDongCurrencyKhongKhop
FROM stg.transactions
WHERE Currency <> Expected_Currency
   OR Currency IS NULL
   OR Expected_Currency IS NULL;
GO



/* ============================================================
   17. KIỂM TRA EXCHANGE RATE
   ============================================================ */

PRINT N'17. EXCHANGE RATE';

SELECT
    COUNT(*) AS TongDong,

    SUM(
        CASE
            WHEN TRY_CONVERT(
                DECIMAL(18,8),
                Exchange_Rate_To_USD
            ) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS TyGiaThieuHoacSai,

    SUM(
        CASE
            WHEN TRY_CONVERT(
                DECIMAL(18,8),
                Exchange_Rate_To_USD
            ) <= 0
            THEN 1
            ELSE 0
        END
    ) AS TyGiaNhoHonBang0

FROM stg.transactions;
GO



/* ============================================================
   18. KIỂM TRA NET_AMOUNT_USD
   ============================================================ */

PRINT N'18. NET_AMOUNT_USD';

SELECT
    COUNT(*) AS TongDong,

    SUM(
        CASE
            WHEN TRY_CONVERT(
                DECIMAL(18,4),
                Net_Amount_USD
            ) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS NetAmountUSDThieu

FROM stg.transactions;
GO



/* ============================================================
   19. KIỂM TRA CÔNG THỨC QUY ĐỔI USD
   ============================================================ */

PRINT N'19. KIỂM TRA CÔNG THỨC USD';

SELECT
    COUNT(*) AS SoDongSaiCongThuc
FROM stg.transactions
WHERE
    TRY_CONVERT(
        DECIMAL(18,4),
        Net_Amount_USD
    )
    <>
    ROUND
    (
        TRY_CONVERT(
            DECIMAL(18,4),
            Net_Amount_Local
        )
        *
        TRY_CONVERT(
            DECIMAL(18,8),
            Exchange_Rate_To_USD
        ),
        4
    );
GO



/* ============================================================
   20. KIỂM TRA USD RATE = 1
   ============================================================ */

PRINT N'20. USD RATE';

SELECT
    COUNT(*) AS SoDongUSDRateKhongBang1
FROM stg.transactions
WHERE Currency = 'USD'
  AND TRY_CONVERT(
        DECIMAL(18,8),
        Exchange_Rate_To_USD
      ) <> 1;
GO



/* ============================================================
   21. REVIEW R13
   ============================================================ */

PRINT N'21. REVIEW R13';

SELECT
    COUNT(*) AS SoDongReview
FROM stg.transactions
WHERE Is_Review = 1;
GO



/* ============================================================
   22. LOAD DATE
   ============================================================ */

PRINT N'22. LOAD DATE';

SELECT
    MIN(Load_Date) AS LoadDateMin,
    MAX(Load_Date) AS LoadDateMax,
    COUNT(*) AS TongDong
FROM stg.transactions;
GO



PRINT N'============================================================';
PRINT N'HOÀN TẤT ĐỐI SOÁT STG SAU NẠP';
PRINT N'============================================================';
GO