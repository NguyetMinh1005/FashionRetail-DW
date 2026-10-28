USE Fashion_DW;
GO

SELECT TOP 1 * FROM dbo.Dim_Customer;
SELECT TOP 1 * FROM dbo.Dim_Product;
SELECT TOP 1 * FROM dbo.Dim_Store;
SELECT TOP 1 * FROM dbo.Dim_Employee;
SELECT TOP 1 * FROM dbo.Dim_Date;
SELECT TOP 1 * FROM dbo.Fact_Sales;
GO

USE Fashion_DW;
GO

SELECT COUNT(*) AS SoDongFact
FROM dbo.Fact_Sales;
GO


USE Fashion_DW;
GO

DECLARE @BatchSize INT = 50000;
DECLARE @StartID BIGINT = 3000001;
DECLARE @MaxID BIGINT;
DECLARE @EndID BIGINT;

SELECT
    @MaxID = MAX(Stg_Row_ID)
FROM Fashion_Staging.stg.transactions;

WHILE @StartID <= @MaxID
BEGIN

    SET @EndID = @StartID + @BatchSize - 1;

    INSERT INTO dbo.Fact_Sales
    (
        Customer_Key,
        Product_Key,
        Store_Key,
        Employee_Key,
        Date_Key,
        Invoice_ID,
        Line,
        Size,
        Color,
        SKU,
        Transaction_Type,
        Payment_Method,
        Currency,
        Currency_Symbol,
        Unit_Price,
        Quantity,
        Discount,
        Line_Total,
        Invoice_Total,
        Net_Amount,
        Sales_Quantity,
        Return_Quantity,
        Is_Return,
        Net_Amount_Local,
        Exchange_Rate_To_USD,
        Net_Amount_USD,
        Production_Cost
    )
    SELECT
        c.Customer_Key,
        p.Product_Key,
        s.Store_Key,
        e.Employee_Key,
        d.Date_Key,

        t.Invoice_ID,
        t.Line,
        t.Size,
        t.Color,
        t.SKU,
        t.Transaction_Type,
        t.Payment_Method,
        t.Currency,
        t.Currency_Symbol,

        TRY_CONVERT(DECIMAL(18,2), t.Unit_Price),
        TRY_CONVERT(INT, t.Quantity),
        TRY_CONVERT(DECIMAL(18,4), t.Discount),
        TRY_CONVERT(DECIMAL(18,2), t.Line_Total),
        TRY_CONVERT(DECIMAL(18,2), t.Invoice_Total),

        TRY_CONVERT(DECIMAL(18,2), t.Net_Amount),
        TRY_CONVERT(INT, t.Sales_Quantity),
        TRY_CONVERT(INT, t.Return_Quantity),
        TRY_CONVERT(BIT, t.Is_Return),

        TRY_CONVERT(DECIMAL(18,2), t.Net_Amount_Local),
        TRY_CONVERT(DECIMAL(18,8), t.Exchange_Rate_To_USD),
        TRY_CONVERT(DECIMAL(18,2), t.Net_Amount_USD),

        p.Production_Cost

    FROM Fashion_Staging.stg.transactions t

    INNER JOIN dbo.Dim_Product p
        ON t.Product_ID = p.Product_ID

    INNER JOIN dbo.Dim_Store s
        ON t.Store_ID = s.Store_ID

    INNER JOIN dbo.Dim_Employee e
        ON t.Employee_ID = e.Employee_ID

    INNER JOIN dbo.Dim_Customer c
        ON t.Customer_ID = c.Customer_ID

    INNER JOIN dbo.Dim_Date d
        ON d.Full_Date = TRY_CONVERT(DATE, t.Transaction_Date)

    WHERE t.Stg_Row_ID BETWEEN @StartID AND @EndID;

    PRINT
        'Da nap tu Stg_Row_ID '
        + CAST(@StartID AS VARCHAR(30))
        + ' den '
        + CAST(@EndID AS VARCHAR(30));

    CHECKPOINT;

    SET @StartID = @EndID + 1;
END;
GO

---------------------------------
USE Fashion_DW;
GO

SELECT COUNT(*) AS SoDongFact
FROM dbo.Fact_Sales;
GO
----------------------------
SELECT
    (SELECT COUNT(*)
     FROM Fashion_Staging.stg.transactions) AS SoDong_STG,

    (SELECT COUNT(*)
     FROM dbo.Fact_Sales) AS SoDong_FACT,

    CASE
        WHEN
            (SELECT COUNT(*)
             FROM Fashion_Staging.stg.transactions)
            =
            (SELECT COUNT(*)
             FROM dbo.Fact_Sales)
        THEN N'ĐẠT'
        ELSE N'KHÔNG ĐẠT'
    END AS KetQua;
GO