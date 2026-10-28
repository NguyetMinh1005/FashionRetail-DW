USE Fashion_DW;
GO

/* ============================================================
   24 - CREATE FOREIGN KEYS
   ============================================================ */

/* Customer */
ALTER TABLE dbo.Fact_Sales
ADD CONSTRAINT FK_FactSales_DimCustomer
FOREIGN KEY (Customer_Key)
REFERENCES dbo.Dim_Customer(Customer_Key);
GO

/* Product */
ALTER TABLE dbo.Fact_Sales
ADD CONSTRAINT FK_FactSales_DimProduct
FOREIGN KEY (Product_Key)
REFERENCES dbo.Dim_Product(Product_Key);
GO

/* Store */
ALTER TABLE dbo.Fact_Sales
ADD CONSTRAINT FK_FactSales_DimStore
FOREIGN KEY (Store_Key)
REFERENCES dbo.Dim_Store(Store_Key);
GO

/* Employee */
ALTER TABLE dbo.Fact_Sales
ADD CONSTRAINT FK_FactSales_DimEmployee
FOREIGN KEY (Employee_Key)
REFERENCES dbo.Dim_Employee(Employee_Key);
GO

/* Date */
ALTER TABLE dbo.Fact_Sales
ADD CONSTRAINT FK_FactSales_DimDate
FOREIGN KEY (Date_Key)
REFERENCES dbo.Dim_Date(Date_Key);
GO


/* ============================================================
   KIỂM TRA FOREIGN KEY
   ============================================================ */

SELECT
    fk.name AS Foreign_Key,
    OBJECT_NAME(fk.parent_object_id) AS Fact_Table,
    COL_NAME(fkc.parent_object_id,
             fkc.parent_column_id) AS Fact_Column,
    OBJECT_NAME(fk.referenced_object_id) AS Dim_Table,
    COL_NAME(fkc.referenced_object_id,
             fkc.referenced_column_id) AS Dim_Column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('dbo.Fact_Sales');
GO