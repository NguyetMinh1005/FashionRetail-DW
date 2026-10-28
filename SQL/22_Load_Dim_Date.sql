USE Fashion_DW;
GO

/* ============================================================
   22 - LOAD DIM DATE
   ============================================================ */

TRUNCATE TABLE dbo.Dim_Date;

DECLARE @StartDate DATE;
DECLARE @EndDate DATE;

SELECT
    @StartDate = MIN(TRY_CONVERT(DATE, Transaction_Date)),
    @EndDate   = MAX(TRY_CONVERT(DATE, Transaction_Date))
FROM Fashion_Staging.stg.transactions;

;WITH DateSeries AS
(
    SELECT @StartDate AS Full_Date

    UNION ALL

    SELECT DATEADD(DAY, 1, Full_Date)
    FROM DateSeries
    WHERE Full_Date < @EndDate
)
INSERT INTO dbo.Dim_Date
(
    Date_Key,
    Full_Date,
    Day_Number,
    Day_Name,
    Month_Number,
    Month_Name,
    Quarter_Number,
    Year_Number,
    Week_Number,
    Is_Weekend
)
SELECT
    YEAR(Full_Date) * 10000
        + MONTH(Full_Date) * 100
        + DAY(Full_Date) AS Date_Key,

    Full_Date,
    DAY(Full_Date),
    DATENAME(WEEKDAY, Full_Date),
    MONTH(Full_Date),
    DATENAME(MONTH, Full_Date),
    DATEPART(QUARTER, Full_Date),
    YEAR(Full_Date),
    DATEPART(WEEK, Full_Date),

    CASE
        WHEN DATENAME(WEEKDAY, Full_Date) IN ('Saturday', 'Sunday')
            THEN 1
        ELSE 0
    END

FROM DateSeries
OPTION (MAXRECURSION 0);
GO


/* ============================================================
   KIỂM TRA
   ============================================================ */

SELECT COUNT(*) AS SoDong
FROM dbo.Dim_Date;
GO

SELECT
    MIN(Full_Date) AS NgayDau,
    MAX(Full_Date) AS NgayCuoi
FROM dbo.Dim_Date;
GO

SELECT TOP 10 *
FROM dbo.Dim_Date
ORDER BY Date_Key;
GO