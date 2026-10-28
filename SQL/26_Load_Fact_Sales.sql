USE Fashion_DW;
GO

/* ============================================================
   26 - LOAD FACT SALES
   Dự án: Fashion Retail Data Warehouse

   Nguồn:
       Fashion_Staging.stg.transactions

   Đích:
       Fashion_DW.dbo.Fact_Sales

   Grain:
       
   Một dòng dữ liệu trong bảng Fact_Sales đại diện cho một
   sản phẩm với kích cỡ và màu sắc cụ thể, được bán hoặc
   nhận trả lại trên một hóa đơn, vào một ngày/thời gian
   giao dịch, tại một cửa hàng, bởi một nhân viên bán hàng,
   cho một khách hàng, có áp dụng chương trình khuyến mãi
   nếu có, sử dụng một phương thức thanh toán và được ghi
   nhận theo một loại tiền tệ giao dịch.

   8 Dimension:
       Dim_Date
       Dim_Product
       Dim_Store
       Dim_Customer
       Dim_Employee
       Dim_Promotion
       Dim_Payment
       Dim_Currency

   Chiến lược:
       Full Refresh
       Load theo Batch dựa trên Stg_Row_ID

   Promotion:
       Sale:
           - Exact Category/Sub_Category ưu tiên trước
           - Global promotion NULL/NULL ưu tiên sau
           - Không match -> No Promotion

       Return:
           - Unknown Promotion
           - Không suy đoán promotion bằng ngày Return
             vì preprocessing hiện chưa tạo liên kết
             Return -> Sale gốc.

   Tiền tệ:
       Lấy trực tiếp từ STG:
           Net_Amount_Local
           Exchange_Rate_To_USD
           Exchange_Rate_Date
           Exchange_Rate_Source
           Net_Amount_USD
   ============================================================ */


/* ============================================================
   0. KIỂM TRA FACT PHẢI CÓ CẤU TRÚC CẦN THIẾT
   ============================================================ */

IF COL_LENGTH('dbo.Fact_Sales', 'Net_Amount_Local') IS NULL
    THROW 50020,
          N'Fact_Sales thiếu Net_Amount_Local.',
          1;

IF COL_LENGTH('dbo.Fact_Sales', 'Exchange_Rate_To_USD') IS NULL
    THROW 50021,
          N'Fact_Sales thiếu Exchange_Rate_To_USD.',
          1;

IF COL_LENGTH('dbo.Fact_Sales', 'Exchange_Rate_Date') IS NULL
    THROW 50022,
          N'Fact_Sales thiếu Exchange_Rate_Date.',
          1;

IF COL_LENGTH('dbo.Fact_Sales', 'Exchange_Rate_Source') IS NULL
    THROW 50023,
          N'Fact_Sales thiếu Exchange_Rate_Source.',
          1;

IF COL_LENGTH('dbo.Fact_Sales', 'Net_Amount_USD') IS NULL
    THROW 50024,
          N'Fact_Sales thiếu Net_Amount_USD.',
          1;
GO


/* ============================================================
   1. KIỂM TRA STAGING CÓ DỮ LIỆU
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM Fashion_Staging.stg.transactions
)
BEGIN
    THROW 50025,
          N'stg.transactions không có dữ liệu.',
          1;
END;
GO


/* ============================================================
   2. XÓA FACT CŨ - FULL REFRESH
   ============================================================ */

DELETE FROM dbo.Fact_Sales;
GO

DBCC CHECKIDENT ('dbo.Fact_Sales', RESEED, 0);
GO


/* ============================================================
   3. LẤY CÁC SPECIAL KEY

   Không hard-code key vì Identity có thể thay đổi.
   ============================================================ */

DECLARE @UnknownCustomerKey INT;
DECLARE @UnknownProductKey INT;
DECLARE @UnknownStoreKey INT;
DECLARE @UnknownEmployeeKey INT;
DECLARE @UnknownPromotionKey INT;
DECLARE @NoPromotionKey INT;
DECLARE @UnknownPaymentKey INT;
DECLARE @UnknownCurrencyKey INT;


/* Customer */
SELECT
    @UnknownCustomerKey = Customer_Key
FROM dbo.Dim_Customer
WHERE Customer_ID = -1;


/* Product */
SELECT
    @UnknownProductKey = Product_Key
FROM dbo.Dim_Product
WHERE Product_ID = -1;


/* Store */
SELECT
    @UnknownStoreKey = Store_Key
FROM dbo.Dim_Store
WHERE Store_ID = -1;


/* Employee */
SELECT
    @UnknownEmployeeKey = Employee_Key
FROM dbo.Dim_Employee
WHERE Employee_ID = -1;


/* Promotion */
SELECT
    @UnknownPromotionKey = Promotion_Key
FROM dbo.Dim_Promotion
WHERE Promotion_Name = N'Unknown';

SELECT
    @NoPromotionKey = Promotion_Key
FROM dbo.Dim_Promotion
WHERE Promotion_Name = N'No Promotion';


/* Payment */
SELECT
    @UnknownPaymentKey = Payment_Key
FROM dbo.Dim_Payment
WHERE Payment_Method = N'Unknown'
  AND Transaction_Type = N'Unknown';


/* Currency */
SELECT
    @UnknownCurrencyKey = Currency_Key
FROM dbo.Dim_Currency
WHERE Currency_Code = 'UNK';


/* ============================================================
   4. KIỂM TRA SPECIAL KEY
   ============================================================ */

IF @UnknownCustomerKey IS NULL
    THROW 50030, N'Thiếu Unknown Customer.', 1;

IF @UnknownProductKey IS NULL
    THROW 50031, N'Thiếu Unknown Product.', 1;

IF @UnknownStoreKey IS NULL
    THROW 50032, N'Thiếu Unknown Store.', 1;

IF @UnknownEmployeeKey IS NULL
    THROW 50033, N'Thiếu Unknown Employee.', 1;

IF @UnknownPromotionKey IS NULL
    THROW 50034, N'Thiếu Unknown Promotion.', 1;

IF @NoPromotionKey IS NULL
    THROW 50035, N'Thiếu No Promotion.', 1;

IF @UnknownPaymentKey IS NULL
    THROW 50036, N'Thiếu Unknown Payment.', 1;

IF @UnknownCurrencyKey IS NULL
    THROW 50037, N'Thiếu Unknown Currency.', 1;


/* ============================================================
   5. THÔNG SỐ LOAD BATCH
   ============================================================ */

DECLARE @BatchSize BIGINT = 250000;

DECLARE @StartID BIGINT;
DECLARE @MaxID BIGINT;
DECLARE @EndID BIGINT;

SELECT
    @StartID = MIN(Stg_Row_ID),
    @MaxID   = MAX(Stg_Row_ID)
FROM Fashion_Staging.stg.transactions;


IF @StartID IS NULL OR @MaxID IS NULL
BEGIN
    THROW 50040,
          N'Không xác định được Stg_Row_ID.',
          1;
END;


/* ============================================================
   6. THÔNG TIN LOAD
   ============================================================ */

PRINT N'===============================================';
PRINT N'BẮT ĐẦU LOAD FACT_SALES';
PRINT N'===============================================';

PRINT N'Start Stg_Row_ID: '
      + CAST(@StartID AS NVARCHAR(30));

PRINT N'Max Stg_Row_ID  : '
      + CAST(@MaxID AS NVARCHAR(30));

PRINT N'Batch Size      : '
      + CAST(@BatchSize AS NVARCHAR(30));


/* ============================================================
   7. LOAD FACT THEO BATCH
   ============================================================ */

WHILE @StartID <= @MaxID
BEGIN

    SET @EndID = @StartID + @BatchSize - 1;


    PRINT N'-----------------------------------------------';
    PRINT N'Đang load Stg_Row_ID '
          + CAST(@StartID AS NVARCHAR(30))
          + N' -> '
          + CAST(@EndID AS NVARCHAR(30));


    /* ========================================================
       INSERT FACT
       ======================================================== */

    INSERT INTO dbo.Fact_Sales
    (
        Date_Key,
        Product_Key,
        Store_Key,
        Customer_Key,
        Employee_Key,
        Promotion_Key,
        Payment_Key,
        Currency_Key,

        Invoice_ID,
        Line_Number,

        Size,
        Color,
        SKU,

        Hour_Of_Day,

        Sign_Flag,

        Unit_Price,
        Discount_Rate,

        Quantity,
        Net_Quantity,

        Gross_Amount,
        Net_Amount,
        Discount_Amount,

        Cost_Amount,

        Net_Amount_Local,
        Exchange_Rate_To_USD,
        Exchange_Rate_Date,
        Exchange_Rate_Source,
        Net_Amount_USD
    )

    SELECT

        /* ====================================================
           DIM DATE
           ==================================================== */

        dd.Date_Key,


        /* ====================================================
           DIM PRODUCT
           ==================================================== */

        COALESCE(
            dp.Product_Key,
            @UnknownProductKey
        ) AS Product_Key,


        /* ====================================================
           DIM STORE
           ==================================================== */

        COALESCE(
            ds.Store_Key,
            @UnknownStoreKey
        ) AS Store_Key,


        /* ====================================================
           DIM CUSTOMER
           ==================================================== */

        COALESCE(
            dc.Customer_Key,
            @UnknownCustomerKey
        ) AS Customer_Key,


        /* ====================================================
           DIM EMPLOYEE
           ==================================================== */

        COALESCE(
            de.Employee_Key,
            @UnknownEmployeeKey
        ) AS Employee_Key,


        /* ====================================================
           DIM PROMOTION

           Sale:
               exact/global promotion nếu match
               nếu không -> No Promotion

           Return:
               Unknown Promotion
        ==================================================== */

        CASE
            WHEN LTRIM(RTRIM(t.Transaction_Type)) = 'Return'
                THEN @UnknownPromotionKey

            ELSE COALESCE(
                promo.Promotion_Key,
                @NoPromotionKey
            )
        END AS Promotion_Key,


        /* ====================================================
           DIM PAYMENT
           ==================================================== */

        COALESCE(
            dpay.Payment_Key,
            @UnknownPaymentKey
        ) AS Payment_Key,


        /* ====================================================
           DIM CURRENCY
           ==================================================== */

        COALESCE(
            dcur.Currency_Key,
            @UnknownCurrencyKey
        ) AS Currency_Key,


        /* ====================================================
           TRANSACTION ATTRIBUTES
           ==================================================== */

        LTRIM(RTRIM(t.Invoice_ID))
            AS Invoice_ID,

        TRY_CONVERT(INT, t.Line)
            AS Line_Number,

        NULLIF(
            LTRIM(RTRIM(t.Size)),
            ''
        ) AS Size,

        NULLIF(
            LTRIM(RTRIM(t.Color)),
            ''
        ) AS Color,

        NULLIF(
            LTRIM(RTRIM(t.SKU)),
            ''
        ) AS SKU,


        /* Hour */
        DATEPART
        (
            HOUR,
            TRY_CONVERT(
                TIME,
                t.Transaction_Time
            )
        ) AS Hour_Of_Day,


        /* ====================================================
           SIGN FLAG

           Sale   = +1
           Return = -1
           ==================================================== */

        CASE
            WHEN LTRIM(RTRIM(t.Transaction_Type)) = 'Return'
                THEN -1
            ELSE 1
        END AS Sign_Flag,


        /* ====================================================
           UNIT PRICE
           ==================================================== */

        TRY_CONVERT(
            DECIMAL(18,2),
            t.Unit_Price
        ) AS Unit_Price,


        /* ====================================================
           DISCOUNT RATE
           ==================================================== */

        TRY_CONVERT(
            DECIMAL(4,2),
            t.Discount
        ) AS Discount_Rate,


        /* ====================================================
           QUANTITY

           Nguồn Quantity luôn dương.
           ==================================================== */

        TRY_CONVERT(
            INT,
            t.Quantity
        ) AS Quantity,


        /* ====================================================
           NET QUANTITY
           ==================================================== */

        CASE
            WHEN LTRIM(RTRIM(t.Transaction_Type)) = 'Return'

                THEN
                    -1 * TRY_CONVERT(
                        INT,
                        t.Quantity
                    )

            ELSE
                TRY_CONVERT(
                    INT,
                    t.Quantity
                )
        END AS Net_Quantity,


        /* ====================================================
           GROSS AMOUNT

           Sale   -> dương
           Return -> âm
           ==================================================== */

        CASE
            WHEN LTRIM(RTRIM(t.Transaction_Type)) = 'Return'

                THEN
                    -1
                    * TRY_CONVERT(
                        DECIMAL(18,2),
                        t.Unit_Price
                    )
                    * TRY_CONVERT(
                        INT,
                        t.Quantity
                    )

            ELSE
                TRY_CONVERT(
                    DECIMAL(18,2),
                    t.Unit_Price
                )
                * TRY_CONVERT(
                    INT,
                    t.Quantity
                )
        END AS Gross_Amount,


        /* ====================================================
           NET AMOUNT

           Lấy trực tiếp Net_Amount đã xử lý từ Line Total.
           Không tính lại Return.
           ==================================================== */

        TRY_CONVERT(
            DECIMAL(18,2),
            t.Net_Amount
        ) AS Net_Amount,


        /* ====================================================
           DISCOUNT AMOUNT

           Chỉ tính chính thức cho SALE.

           Return để NULL vì Line Total Return đã được xác định
           là không nên suy ngược từ Unit Price × Quantity × Discount.
           ==================================================== */

        CASE
            WHEN LTRIM(RTRIM(t.Transaction_Type)) = 'Sale'
            THEN
                (
                    TRY_CONVERT(
                        DECIMAL(18,2),
                        t.Unit_Price
                    )
                    *
                    TRY_CONVERT(
                        INT,
                        t.Quantity
                    )
                )
                -
                TRY_CONVERT(
                    DECIMAL(18,2),
                    t.Net_Amount
                )

            ELSE NULL
        END AS Discount_Amount,


        /* ====================================================
           COST AMOUNT

           Tạm thời để NULL.

           Production_Cost đã có trong Dim_Product nhưng tài liệu
           chưa xác nhận chắc chắn đơn vị tiền để so sánh trực tiếp
           với doanh thu đa tiền tệ.

           Khi chốt đơn vị cost có thể bổ sung sau.
           ==================================================== */

        NULL AS Cost_Amount,


        /* ====================================================
           TIỀN GỐC
           ==================================================== */

        TRY_CONVERT(
            DECIMAL(18,2),
            t.Net_Amount_Local
        ) AS Net_Amount_Local,


        /* ====================================================
           TỶ GIÁ USD
           ==================================================== */

        TRY_CONVERT(
            DECIMAL(18,8),
            t.Exchange_Rate_To_USD
        ) AS Exchange_Rate_To_USD,


        TRY_CONVERT(
            DATE,
            t.Exchange_Rate_Date
        ) AS Exchange_Rate_Date,


        NULLIF(
            LTRIM(RTRIM(t.Exchange_Rate_Source)),
            ''
        ) AS Exchange_Rate_Source,


        /* ====================================================
           NET AMOUNT USD

           Lấy trực tiếp kết quả preprocessing.
           Không tính lại tại DW.
           ==================================================== */

        TRY_CONVERT(
            DECIMAL(18,4),
            t.Net_Amount_USD
        ) AS Net_Amount_USD


    FROM Fashion_Staging.stg.transactions AS t


    /* ========================================================
       LOOKUP DATE
       ======================================================== */

    INNER JOIN dbo.Dim_Date AS dd
        ON dd.Full_Date =
           TRY_CONVERT(
               DATE,
               t.Transaction_Date
           )


    /* ========================================================
       LOOKUP PRODUCT
       ======================================================== */

    LEFT JOIN dbo.Dim_Product AS dp
        ON dp.Product_ID =
           TRY_CONVERT(
               INT,
               t.Product_ID
           )


    /* ========================================================
       LOOKUP STORE
       ======================================================== */

    LEFT JOIN dbo.Dim_Store AS ds
        ON ds.Store_ID =
           TRY_CONVERT(
               INT,
               t.Store_ID
           )


    /* ========================================================
       LOOKUP CUSTOMER
       ======================================================== */

    LEFT JOIN dbo.Dim_Customer AS dc
        ON dc.Customer_ID =
           TRY_CONVERT(
               INT,
               t.Customer_ID
           )


    /* ========================================================
       LOOKUP EMPLOYEE
       ======================================================== */

    LEFT JOIN dbo.Dim_Employee AS de
        ON de.Employee_ID =
           TRY_CONVERT(
               INT,
               t.Employee_ID
           )


    /* ========================================================
       LOOKUP PAYMENT
       ======================================================== */

    LEFT JOIN dbo.Dim_Payment AS dpay
        ON dpay.Payment_Method =
           LTRIM(RTRIM(t.Payment_Method))

       AND dpay.Transaction_Type =
           LTRIM(RTRIM(t.Transaction_Type))


    /* ========================================================
       LOOKUP CURRENCY
       ======================================================== */

    LEFT JOIN dbo.Dim_Currency AS dcur
        ON dcur.Currency_Code =
           UPPER(
               LTRIM(RTRIM(t.Currency))
           )


    /* ========================================================
       LOOKUP PROMOTION

       Chỉ áp dụng cho SALE.

       Điều kiện:
           Transaction_Date nằm trong promotion
           Discount phải khớp
           và:
              exact Category/Sub_Category
              HOẶC global NULL/NULL

       TOP 1:
           Exact product group ưu tiên hơn Global.
       ======================================================== */

    OUTER APPLY
    (
        SELECT TOP (1)
            p.Promotion_Key

        FROM dbo.Dim_Promotion AS p

        WHERE

            LTRIM(RTRIM(t.Transaction_Type)) = 'Sale'

            AND p.Promotion_Name NOT IN
            (
                N'Unknown',
                N'No Promotion'
            )

            AND
            TRY_CONVERT(
                DATE,
                t.Transaction_Date
            )
            BETWEEN
                p.Start_Date
                AND
                p.End_Date

            AND p.Discount_Rate =
                TRY_CONVERT(
                    DECIMAL(4,2),
                    t.Discount
                )

            AND
            (
                /* Exact Category + Sub Category */
                (
                    p.Category = dp.Category
                    AND
                    p.Sub_Category = dp.Sub_Category
                )

                OR

                /* Global Promotion */
                (
                    p.Category IS NULL
                    AND
                    p.Sub_Category IS NULL
                )
            )

        ORDER BY

            /* Exact match ưu tiên trước Global */
            CASE
                WHEN p.Category IS NOT NULL
                    THEN 1
                ELSE 2
            END,

            p.Promotion_Key

    ) AS promo


    /* ========================================================
       CHỈ XỬ LÝ BATCH HIỆN TẠI
       ======================================================== */

    WHERE t.Stg_Row_ID
          BETWEEN @StartID AND @EndID;


    /* ========================================================
       THỐNG KÊ BATCH
       ======================================================== */

    PRINT N'Số dòng vừa nạp: '
          + CAST(@@ROWCOUNT AS NVARCHAR(30));


    SET @StartID = @EndID + 1;

END;
GO


/* ============================================================
   8. KIỂM TRA TỔNG DÒNG
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Total_Fact_Sales
FROM dbo.Fact_Sales;
GO


/* ============================================================
   9. ĐỐI SOÁT STG -> FACT
   ============================================================ */

SELECT
    (
        SELECT COUNT_BIG(*)
        FROM Fashion_Staging.stg.transactions
    ) AS STG_Transactions,

    (
        SELECT COUNT_BIG(*)
        FROM dbo.Fact_Sales
    ) AS DW_Fact_Sales;
GO


/* ============================================================
   10. KIỂM TRA SALE / RETURN
   ============================================================ */

SELECT
    Sign_Flag,
    COUNT_BIG(*) AS So_Dong,
    SUM(CAST(Net_Quantity AS BIGINT))
        AS Tong_Net_Quantity,

    SUM(Net_Amount_USD)
        AS Net_Amount_USD

FROM dbo.Fact_Sales

GROUP BY Sign_Flag

ORDER BY Sign_Flag;
GO


/* ============================================================
   11. KIỂM TRA SỐ DÒNG THEO PAYMENT
   ============================================================ */

SELECT
    p.Payment_Method,
    p.Transaction_Type,

    COUNT_BIG(*) AS So_Dong

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
   12. KIỂM TRA CURRENCY
   ============================================================ */

SELECT
    c.Currency_Code,

    COUNT_BIG(*) AS So_Dong,

    SUM(f.Net_Amount_Local)
        AS Tong_Tien_Local,

    SUM(f.Net_Amount_USD)
        AS Tong_Tien_USD

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Currency AS c
    ON f.Currency_Key = c.Currency_Key

GROUP BY c.Currency_Code

ORDER BY c.Currency_Code;
GO


/* ============================================================
   13. KIỂM TRA USD CÓ RATE = 1 KHÔNG

   Mong đợi: 0 dòng
   ============================================================ */

SELECT TOP (100)
    f.Sales_Key,
    c.Currency_Code,
    f.Exchange_Rate_To_USD

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Currency AS c
    ON f.Currency_Key = c.Currency_Key

WHERE c.Currency_Code = 'USD'

AND ABS(
        f.Exchange_Rate_To_USD - 1
    ) > 0.00000001;
GO


/* ============================================================
   14. KIỂM TRA CÔNG THỨC USD

   Net_Amount_USD phải gần bằng:
       Net_Amount_Local × Exchange_Rate_To_USD

   Cho phép sai số 0.01 do rounding.

   Mong đợi: 0 dòng
   ============================================================ */

SELECT TOP (100)
    Sales_Key,
    Net_Amount_Local,
    Exchange_Rate_To_USD,
    Net_Amount_USD,

    Net_Amount_Local
        * Exchange_Rate_To_USD
        AS Recalculated_USD

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
   15. KIỂM TRA DIM KEY UNKNOWN
   ============================================================ */

DECLARE @Check_UnknownCustomerKey INT;
DECLARE @Check_UnknownProductKey INT;
DECLARE @Check_UnknownStoreKey INT;
DECLARE @Check_UnknownEmployeeKey INT;
DECLARE @Check_UnknownPaymentKey INT;
DECLARE @Check_UnknownCurrencyKey INT;


/* Lấy các Unknown Key trước */
SELECT
    @Check_UnknownCustomerKey = Customer_Key
FROM dbo.Dim_Customer
WHERE Customer_ID = -1;


SELECT
    @Check_UnknownProductKey = Product_Key
FROM dbo.Dim_Product
WHERE Product_ID = -1;


SELECT
    @Check_UnknownStoreKey = Store_Key
FROM dbo.Dim_Store
WHERE Store_ID = -1;


SELECT
    @Check_UnknownEmployeeKey = Employee_Key
FROM dbo.Dim_Employee
WHERE Employee_ID = -1;


SELECT
    @Check_UnknownPaymentKey = Payment_Key
FROM dbo.Dim_Payment
WHERE Payment_Method = N'Unknown'
  AND Transaction_Type = N'Unknown';


SELECT
    @Check_UnknownCurrencyKey = Currency_Key
FROM dbo.Dim_Currency
WHERE Currency_Code = 'UNK';


/* Sau đó mới aggregate */
SELECT
    SUM(
        CASE
            WHEN Customer_Key = @Check_UnknownCustomerKey
                THEN 1
            ELSE 0
        END
    ) AS Unknown_Customer,

    SUM(
        CASE
            WHEN Product_Key = @Check_UnknownProductKey
                THEN 1
            ELSE 0
        END
    ) AS Unknown_Product,

    SUM(
        CASE
            WHEN Store_Key = @Check_UnknownStoreKey
                THEN 1
            ELSE 0
        END
    ) AS Unknown_Store,

    SUM(
        CASE
            WHEN Employee_Key = @Check_UnknownEmployeeKey
                THEN 1
            ELSE 0
        END
    ) AS Unknown_Employee,

    SUM(
        CASE
            WHEN Payment_Key = @Check_UnknownPaymentKey
                THEN 1
            ELSE 0
        END
    ) AS Unknown_Payment,

    SUM(
        CASE
            WHEN Currency_Key = @Check_UnknownCurrencyKey
                THEN 1
            ELSE 0
        END
    ) AS Unknown_Currency

FROM dbo.Fact_Sales;
GO

/* ============================================================
   16. KIỂM TRA PROMOTION
   ============================================================ */

SELECT
    p.Promotion_Name,
    COUNT_BIG(*) AS So_Dong

FROM dbo.Fact_Sales AS f

INNER JOIN dbo.Dim_Promotion AS p
    ON f.Promotion_Key = p.Promotion_Key

GROUP BY p.Promotion_Name

ORDER BY So_Dong DESC;
GO


/* ============================================================
   17. KIỂM TRA RETURN PHẢI ĐANG VỀ UNKNOWN PROMOTION
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
   18. KIỂM TRA SALE KHÔNG CÓ PROMOTION
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
   19. KIỂM TRA KEY NULL

   Vì 8 FK đều NOT NULL nên mong đợi = 0.
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
   20. KIỂM TRA QUANTITY
   ============================================================ */

SELECT
    MIN(Quantity) AS Min_Quantity,
    MAX(Quantity) AS Max_Quantity,

    SUM(
        CASE
            WHEN Quantity <= 0
                THEN 1
            ELSE 0
        END
    ) AS Invalid_Quantity

FROM dbo.Fact_Sales;
GO


/* ============================================================
   21. KIỂM TRA SIGN / NET QUANTITY
   ============================================================ */

SELECT
    COUNT_BIG(*) AS Invalid_Net_Quantity

FROM dbo.Fact_Sales

WHERE
    Net_Quantity
    <>
    Sign_Flag * Quantity;
GO


/* ============================================================
   22. KIỂM TRA DẤU NET AMOUNT
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN Sign_Flag = 1
                 AND Net_Amount <= 0
                THEN 1
            ELSE 0
        END
    ) AS Sale_Sai_Dau,

    SUM(
        CASE
            WHEN Sign_Flag = -1
                 AND Net_Amount >= 0
                THEN 1
            ELSE 0
        END
    ) AS Return_Sai_Dau

FROM dbo.Fact_Sales;
GO


/* ============================================================
   23. KIỂM TRA TỶ GIÁ
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN Exchange_Rate_To_USD IS NULL
                THEN 1
            ELSE 0
        END
    ) AS Missing_Exchange_Rate,

    SUM(
        CASE
            WHEN Exchange_Rate_To_USD <= 0
                THEN 1
            ELSE 0
        END
    ) AS Invalid_Exchange_Rate,

    SUM(
        CASE
            WHEN Net_Amount_USD IS NULL
                THEN 1
            ELSE 0
        END
    ) AS Missing_Net_Amount_USD

FROM dbo.Fact_Sales;
GO


/* ============================================================
   24. XEM DỮ LIỆU MẪU
   ============================================================ */

SELECT TOP (50)
    Sales_Key,

    Date_Key,
    Product_Key,
    Store_Key,
    Customer_Key,
    Employee_Key,
    Promotion_Key,
    Payment_Key,
    Currency_Key,

    Invoice_ID,
    Line_Number,

    Size,
    Color,
    SKU,

    Hour_Of_Day,

    Sign_Flag,
    Unit_Price,
    Discount_Rate,

    Quantity,
    Net_Quantity,

    Gross_Amount,
    Net_Amount,
    Discount_Amount,

    Net_Amount_Local,
    Exchange_Rate_To_USD,
    Exchange_Rate_Date,
    Exchange_Rate_Source,
    Net_Amount_USD

FROM dbo.Fact_Sales

ORDER BY Sales_Key;
GO