USE Fashion_Staging;
GO

USE [Fashion_Staging]
GO

/****** Object:  Table [raw].[customers]    Script Date: 20/10/2026 6:01:46 CH ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [raw].[customers](
	[Customer_ID] [nvarchar](50) NULL,
	[Name] [nvarchar](max) NULL,
	[Email] [nvarchar](max) NULL,
	[Telephone] [nvarchar](max) NULL,
	[City] [nvarchar](max) NULL,
	[Country] [nvarchar](50) NULL,
	[Gender] [nvarchar](50) NULL,
	[Date_Of_Birth] [nvarchar](50) NULL,
	[Job_Title] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

USE [Fashion_Staging]
GO

/****** Object:  Table [raw].[discounts]    Script Date: 20/10/2026 6:04:04 CH ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [raw].[discounts](
	[Start] [nvarchar](50) NULL,
	[End] [nvarchar](50) NULL,
	[Discont] [nvarchar](50) NULL,
	[Description] [nvarchar](max) NULL,
	[Category] [nvarchar](max) NULL,
	[Sub_Category] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

USE [Fashion_Staging]
GO

/****** Object:  Table [raw].[employees]    Script Date: 20/10/2026 6:04:24 CH ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [raw].[employees](
	[Employee_ID] [nvarchar](50) NULL,
	[Store_ID] [nvarchar](50) NULL,
	[Name] [nvarchar](max) NULL,
	[Position] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

USE [Fashion_Staging]
GO

/****** Object:  Table [raw].[products]    Script Date: 20/10/2026 6:05:00 CH ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [raw].[products](
	[Product_ID] [nvarchar](50) NULL,
	[Category] [nvarchar](50) NULL,
	[Sub_Category] [nvarchar](50) NULL,
	[Description_PT] [nvarchar](max) NULL,
	[Description_DE] [nvarchar](max) NULL,
	[Description_FR] [nvarchar](max) NULL,
	[Description_ES] [nvarchar](max) NULL,
	[Description_EN] [nvarchar](max) NULL,
	[Description_ZH] [nvarchar](max) NULL,
	[Color] [nvarchar](max) NULL,
	[Sizes] [nvarchar](max) NULL,
	[Production_Cost] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

USE [Fashion_Staging]
GO

/****** Object:  Table [raw].[stores]    Script Date: 20/10/2026 6:05:28 CH ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [raw].[stores](
	[Store_ID] [nvarchar](50) NULL,
	[Country] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL,
	[Store_Name] [nvarchar](50) NULL,
	[Number_of_Employees] [nvarchar](50) NULL,
	[ZIP_Code] [nvarchar](50) NULL,
	[Latitude] [nvarchar](50) NULL,
	[Longitude] [nvarchar](50) NULL
) ON [PRIMARY]
GO

USE [Fashion_Staging]
GO

/****** Object:  Table [raw].[transactions]    Script Date: 20/10/2026 6:05:54 CH ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [raw].[transactions](
	[Invoice_ID] [nvarchar](100) NULL,
	[Line] [nvarchar](50) NULL,
	[Customer_ID] [nvarchar](50) NULL,
	[Product_ID] [nvarchar](50) NULL,
	[Size] [nvarchar](50) NULL,
	[Color] [nvarchar](100) NULL,
	[Unit_Price] [nvarchar](50) NULL,
	[Quantity] [nvarchar](50) NULL,
	[Date] [nvarchar](50) NULL,
	[Discount] [nvarchar](50) NULL,
	[Line_Total] [nvarchar](50) NULL,
	[Store_ID] [nvarchar](50) NULL,
	[Employee_ID] [nvarchar](50) NULL,
	[Currency] [nvarchar](50) NULL,
	[Currency_Symbol] [nvarchar](50) NULL,
	[SKU] [nvarchar](100) NULL,
	[Transaction_Type] [nvarchar](50) NULL,
	[Payment_Method] [nvarchar](50) NULL,
	[Invoice_Total] [nvarchar](50) NULL
) ON [PRIMARY]
GO











