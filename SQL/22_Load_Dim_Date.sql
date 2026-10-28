USE Fashion_DW;
GO

/* ============================================================
   22 - LOAD DIM DATE
   Dự án: Fashion Retail Data Warehouse

   Nguồn:
       Fashion_Staging.stg.transactions

   Đích:
       Fashion_DW.dbo.Dim_Date

   Business Key:
       Full_Date

   Surrogate/Date Key:
       Date_Key dạng YYYYMMDD

   Phạm vi dữ liệu dự kiến:
       2023-01-01 -> 2025-03-18
   ============================================================ */


/* ============================================================
   1. KIỂM TRA FACT TRƯỚC KHI RELOAD DIM
   ============================================================ */

IF EXISTS (SELECT 1 FROM dbo.Fact_Sales)
BEGIN
    THROW 50005,
          N'Fact_Sales đã có dữ liệu. Không được reload Dim_Date trước khi xử lý Fact.',
          1;
END;
GO


/* ============================================================
   2. XÓA DỮ LIỆU DIM DATE CŨ
   ============================================================ */

/*
   Không dùng TRUNCATE vì Dim_Date đang được Fact_Sales
   tham chiếu bằng FOREIGN KEY.
*/

DELETE FROM dbo.Dim_Date;
GO


/* ============================================================
   3. XÁC ĐỊNH KHOẢNG NGÀY TỪ STAGING
   ============================================================ */

DECLARE @StartDate DATE;
DECLARE @EndDate DATE;

SELECT
    @StartDate = MIN(TRY_CONVERT(DATE, Transaction_Date)),
    @EndDate   = MAX(TRY_CONVERT(DATE, Transaction_Date))
FROM Fashion_Staging.stg.transactions;


/* Kiểm tra dữ liệu nguồn có ngày hợp lệ hay không */
IF @StartDate IS NULL OR @EndDate IS NULL
BEGIN
    THROW 50006,
          N'Không xác định được khoảng ngày từ stg.transactions.',
          1;
END;


/* ============================================================
   4. SINH DẢI NGÀY LIÊN TỤC
   ============================================================ */

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
    Day_Of_Week,
    Week_Number,
    Month_Number,
    Month_Name,
    Quarter_Number,
    Year_Number,
    Is_Weekend,
    Season
)

SELECT
    /* Date_Key dạng YYYYMMDD */
    YEAR(Full_Date) * 10000
        + MONTH(Full_Date) * 100
        + DAY(Full_Date) AS Date_Key,

    Full_Date,

    DAY(Full_Date) AS Day_Number,

    DATENAME(WEEKDAY, Full_Date) AS Day_Name,

    /*
       Day_Of_Week cố định:
       Monday = 1
       Tuesday = 2
       ...
       Sunday = 7

       Không phụ thuộc SET DATEFIRST.
    */
    ((DATEDIFF(DAY, '19000101', Full_Date) % 7) + 1)
        AS Day_Of_Week,

    DATEPART(ISO_WEEK, Full_Date) AS Week_Number,

    MONTH(Full_Date) AS Month_Number,

    DATENAME(MONTH, Full_Date) AS Month_Name,

    DATEPART(QUARTER, Full_Date) AS Quarter_Number,

    YEAR(Full_Date) AS Year_Number,

    /*
       Weekend:
       Saturday = 6
       Sunday = 7
    */
    CASE
        WHEN ((DATEDIFF(DAY, '19000101', Full_Date) % 7) + 1)
             IN (6, 7)
            THEN 1
        ELSE 0
    END AS Is_Weekend,

    /*
       Season theo quy ước bán cầu Bắc:

       Spring : Mar-May
       Summer : Jun-Aug
       Autumn : Sep-Nov
       Winter : Dec-Feb
    */
    CASE
        WHEN MONTH(Full_Date) IN (3,4,5)
            THEN N'Spring'

        WHEN MONTH(Full_Date) IN (6,7,8)
            THEN N'Summer'

        WHEN MONTH(Full_Date) IN (9,10,11)
            THEN N'Autumn'

        ELSE N'Winter'
    END AS Season

FROM DateSeries

OPTION (MAXRECURSION 0);
GO


/* ============================================================
   5. KIỂM TRA TỔNG SỐ DÒNG
   ============================================================ */

SELECT
    COUNT(*) AS Total_Dim_Date
FROM dbo.Dim_Date;
GO


/* ============================================================
   6. KIỂM TRA NGÀY ĐẦU / NGÀY CUỐI
   ============================================================ */

SELECT
    MIN(Full_Date) AS Ngay_Dau,
    MAX(Full_Date) AS Ngay_Cuoi
FROM dbo.Dim_Date;
GO


/* ============================================================
   7. KIỂM TRA SỐ NGÀY MONG ĐỢI

   Expected_Days =
   DATEDIFF(DAY, StartDate, EndDate) + 1
   ============================================================ */

SELECT
    DATEDIFF
    (
        DAY,
        MIN(Full_Date),
        MAX(Full_Date)
    ) + 1 AS Expected_Days,

    COUNT(*) AS Actual_Days

FROM dbo.Dim_Date;
GO


/* ============================================================
   8. KIỂM TRA DATE_KEY TRÙNG
   Kết quả mong đợi: 0 dòng
   ============================================================ */

SELECT
    Date_Key,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Date
GROUP BY Date_Key
HAVING COUNT(*) > 1;
GO


/* ============================================================
   9. KIỂM TRA FULL_DATE TRÙNG
   Kết quả mong đợi: 0 dòng
   ============================================================ */

SELECT
    Full_Date,
    COUNT(*) AS SoLanXuatHien
FROM dbo.Dim_Date
GROUP BY Full_Date
HAVING COUNT(*) > 1;
GO


/* ============================================================
   10. KIỂM TRA DATE_KEY CÓ ĐÚNG YYYYMMDD
   Kết quả mong đợi: 0 dòng
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
   11. KIỂM TRA DAY_OF_WEEK
   ============================================================ */

SELECT
    Day_Of_Week,
    Day_Name,
    COUNT(*) AS So_Ngay
FROM dbo.Dim_Date
GROUP BY
    Day_Of_Week,
    Day_Name
ORDER BY Day_Of_Week;
GO


/* ============================================================
   12. KIỂM TRA WEEKEND
   ============================================================ */

SELECT
    Is_Weekend,
    COUNT(*) AS So_Ngay
FROM dbo.Dim_Date
GROUP BY Is_Weekend
ORDER BY Is_Weekend;
GO


/* ============================================================
   13. KIỂM TRA SEASON
   ============================================================ */

SELECT
    Season,
    COUNT(*) AS So_Ngay
FROM dbo.Dim_Date
GROUP BY Season
ORDER BY Season;
GO


/* ============================================================
   14. KIỂM TRA NĂM / QUÝ
   ============================================================ */

SELECT
    Year_Number,
    Quarter_Number,
    COUNT(*) AS So_Ngay
FROM dbo.Dim_Date
GROUP BY
    Year_Number,
    Quarter_Number
ORDER BY
    Year_Number,
    Quarter_Number;
GO


/* ============================================================
   15. XEM DỮ LIỆU MẪU
   ============================================================ */

SELECT TOP (20)
    Date_Key,
    Full_Date,
    Day_Number,
    Day_Name,
    Day_Of_Week,
    Week_Number,
    Month_Number,
    Month_Name,
    Quarter_Number,
    Year_Number,
    Is_Weekend,
    Season
FROM dbo.Dim_Date
ORDER BY Full_Date;
GO


/* ============================================================
   16. KIỂM TRA CUỐI
   ============================================================ */

SELECT
    COUNT(*) AS Total_Days,
    MIN(Date_Key) AS Min_Date_Key,
    MAX(Date_Key) AS Max_Date_Key,
    MIN(Full_Date) AS Min_Full_Date,
    MAX(Full_Date) AS Max_Full_Date
FROM dbo.Dim_Date;
GO