USE Fashion_DW;
GO

/* ============================================================
   21 - LOAD DIM EMPLOYEE
   Dự án: Fashion Retail Data Warehouse

   Nguồn:
       Fashion_Staging.stg.employees

   Đích:
       Fashion_DW.dbo.Dim_Employee

   Business Key:
       Employee_ID

   Surrogate Key:
       Employee_Key
   ============================================================ */


/* ============================================================
   1. KIỂM TRA FACT TRƯỚC KHI RELOAD DIM
   ============================================================ */

IF EXISTS (SELECT 1 FROM dbo.Fact_Sales)
BEGIN
    THROW 50004,
          N'Fact_Sales đã có dữ liệu. Không được reload Dim_Employee trước khi xử lý Fact.',
          1;
END;
GO


/* ============================================================
   2. XÓA DỮ LIỆU DIM EMPLOYEE CŨ
   ============================================================ */

/*
   Không dùng TRUNCATE vì Dim_Employee đang được Fact_Sales
   tham chiếu bằng FOREIGN KEY.
*/

DELETE FROM dbo.Dim_Employee;
GO

DBCC CHECKIDENT ('dbo.Dim_Employee', RESEED, 0);
GO


/* ============================================================
   3. TẠO BẢN GHI UNKNOWN EMPLOYEE
   ============================================================ */

SET IDENTITY_INSERT dbo.Dim_Employee ON;

INSERT INTO dbo.Dim_Employee
(
    Employee_Key,
    Employee_ID,
    Store_ID,
    Employee_Name,
    Position
)
VALUES
(
    -1,
    -1,
    -1,
    N'Unknown Employee',
    N'Unknown'
);

SET IDENTITY_INSERT dbo.Dim_Employee OFF;
GO


/* ============================================================
   4. NẠP DỮ LIỆU TỪ STG.EMPLOYEES
   ============================================================ */

INSERT INTO dbo.Dim_Employee
(
    Employee_ID,
    Store_ID,
    Employee_Name,
    Position
)
SELECT
    TRY_CONVERT(INT, Employee_ID),
    TRY_CONVERT(INT, Store_ID),
    NULLIF(LTRIM(RTRIM(Name)), ''),
    NULLIF(LTRIM(RTRIM(Position)), '')
FROM Fashion_Staging.stg.employees
ORDER BY TRY_CONVERT(INT, Employee_ID);
GO


/* ============================================================
   5. KIỂM TRA TỔNG SỐ DÒNG
   ============================================================ */

SELECT
    COUNT(*) AS Total_Dim_Employee,
    COUNT(CASE WHEN Employee_ID = -1 THEN 1 END) AS Unknown_Employee_Count,
    COUNT(CASE WHEN Employee_ID > 0 THEN 1 END) AS Staging_Employee_Count
FROM dbo.Dim_Employee;
GO


/* ============================================================
   6. XEM DỮ LIỆU MẪU
   ============================================================ */

SELECT TOP 10 *
FROM dbo.Dim_Employee
ORDER BY Employee_Key;
GO