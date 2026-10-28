import os
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

# Paths
BASE_DIR = Path(r"E:\FashionRetail-DW")
SSIS_DIR = BASE_DIR / "SSIS" / "FashionRetail_ETL"
TEMPLATE_PATH = SSIS_DIR / "01_Load_Customers_STG.dtsx"
DTPROJ_PATH = SSIS_DIR / "FashionRetail_ETL.dtproj"

PACKAGES_CONFIG = [
    {
        "num": "02",
        "name": "02_Load_Products_STG",
        "csv_file": "cleaned_products.csv",
        "cm_name": "FF_cleaned_products",
        "table_name": "[stg].[products]",
        "task_name": "Load_Products_STG",
        "mappings": [
            ("Product ID", "Product_ID"),
            ("Category", "Category"),
            ("Sub Category", "Sub_Category"),
            ("Description PT", "Description_PT"),
            ("Description DE", "Description_DE"),
            ("Description FR", "Description_FR"),
            ("Description ES", "Description_ES"),
            ("Description EN", "Description_EN"),
            ("Description ZH", "Description_ZH"),
            ("Color", "Color"),
            ("Sizes", "Sizes"),
            ("Production Cost", "Production_Cost"),
        ]
    },
    {
        "num": "03",
        "name": "03_Load_Stores_STG",
        "csv_file": "cleaned_stores.csv",
        "cm_name": "FF_cleaned_stores",
        "table_name": "[stg].[stores]",
        "task_name": "Load_Stores_STG",
        "csv_columns": [
            "Store ID", "Country", "City", "Store Name", "Number of Employees",
            "ZIP Code", "Latitude", "Longitude", "Country_Original",
            "Country_Code", "Country_Name_EN", "Country_Name_VI", "Expected_Currency"
        ],
        "mappings": [
            ("Store ID", "Store_ID"),
            ("Country", "Country"),
            ("City", "City"),
            ("Store Name", "Store_Name"),
            ("Number of Employees", "Number_of_Employees"),
            ("ZIP Code", "ZIP_Code"),
            ("Latitude", "Latitude"),
            ("Longitude", "Longitude"),
            ("Country_Code", "Country_Code"),
            ("Country_Name_EN", "Country_Name_EN"),
            ("Country_Name_VI", "Country_Name_VI"),
            ("Expected_Currency", "Expected_Currency"),
        ]
    },
    {
        "num": "04",
        "name": "04_Load_Employees_STG",
        "csv_file": "cleaned_employees.csv",
        "cm_name": "FF_cleaned_employees",
        "table_name": "[stg].[employees]",
        "task_name": "Load_Employees_STG",
        "mappings": [
            ("Employee ID", "Employee_ID"),
            ("Store ID", "Store_ID"),
            ("Name", "Name"),
            ("Position", "Position"),
        ]
    },
    {
        "num": "05",
        "name": "05_Load_Discounts_STG",
        "csv_file": "cleaned_discounts.csv",
        "cm_name": "FF_cleaned_discounts",
        "table_name": "[stg].[discounts]",
        "task_name": "Load_Discounts_STG",
        "mappings": [
            ("Start", "Start"),
            ("End", "End"),
            ("Discount", "Discount"),
            ("Description", "Description"),
            ("Category", "Category"),
            ("Sub Category", "Sub_Category"),
        ]
    },
    {
        "num": "06",
        "name": "06_Load_Transactions_STG",
        "csv_file": "cleaned_transactions.csv",
        "cm_name": "FF_cleaned_transactions",
        "table_name": "[stg].[transactions]",
        "task_name": "Load_Transactions_STG",
        "mappings": [
            ("Invoice ID", "Invoice_ID"),
            ("Line", "Line"),
            ("Customer ID", "Customer_ID"),
            ("Product ID", "Product_ID"),
            ("Size", "Size"),
            ("Color", "Color"),
            ("Unit Price", "Unit_Price"),
            ("Quantity", "Quantity"),
            ("Date", "Date"),
            ("Discount", "Discount"),
            ("Line Total", "Line_Total"),
            ("Store ID", "Store_ID"),
            ("Employee ID", "Employee_ID"),
            ("Currency", "Currency"),
            ("Currency Symbol", "Currency_Symbol"),
            ("SKU", "SKU"),
            ("Transaction Type", "Transaction_Type"),
            ("Payment Method", "Payment_Method"),
            ("Invoice Total", "Invoice_Total"),
            ("Country_Code", "Country_Code"),
            ("Expected_Currency", "Expected_Currency"),
            ("Currency_Match", "Currency_Match"),
            ("Transaction_Date", "Transaction_Date"),
            ("Transaction_Time", "Transaction_Time"),
            ("Is_Return", "Is_Return"),
            ("Net_Amount", "Net_Amount"),
            ("Sales_Quantity", "Sales_Quantity"),
            ("Return_Quantity", "Return_Quantity"),
            ("Exchange_Rate_To_USD", "Exchange_Rate_To_USD"),
            ("Exchange_Rate_Date", "Exchange_Rate_Date"),
            ("Exchange_Rate_Source", "Exchange_Rate_Source"),
            ("Net_Amount_Local", "Net_Amount_Local"),
            ("Net_Amount_USD", "Net_Amount_USD"),
        ]
    }
]

def make_guid():
    return "{" + str(uuid.uuid4()).upper() + "}"

def generate_package(pkg_config):
    pkg_name = pkg_config["name"]
    csv_file = pkg_config["csv_file"]
    cm_name = pkg_config["cm_name"]
    table_name = pkg_config["table_name"]
    task_name = pkg_config["task_name"]
    mappings = pkg_config["mappings"] # list of (csv_col, db_col)
    
    # If custom csv_columns list is given (e.g. stores has Country_Original which isn't mapped to db)
    csv_cols = pkg_config.get("csv_columns", [m[0] for m in mappings])
    
    file_path = f"E:\\FashionRetail-DW\\data\\cleaned\\{csv_file}"
    
    pkg_dtsid = make_guid()
    version_guid = make_guid()
    flatfile_cm_id = make_guid()
    oledb_cm_id = make_guid()
    task_dtsid = make_guid()
    
    # Build FlatFileColumns XML
    flat_file_columns_xml = []
    for i, col in enumerate(csv_cols):
        is_last = (i == len(csv_cols) - 1)
        delimiter = "_x000D__x000A_" if is_last else "_x002C_"
        col_guid = make_guid()
        flat_file_columns_xml.append(f"""            <DTS:FlatFileColumn
              DTS:ColumnType="Delimited"
              DTS:ColumnDelimiter="{delimiter}"
              DTS:MaximumWidth="150"
              DTS:DataType="130"
              DTS:TextQualified="True"
              DTS:ObjectName="{col}"
              DTS:DTSID="{col_guid}"
              DTS:CreationName="" />""")
    flat_file_columns_str = "\n".join(flat_file_columns_xml)

    # In Data Flow:
    # Flat File Source output columns & externalMetadataColumns
    source_out_cols = []
    source_ext_cols = []
    
    col_lineage_map = {}
    current_lineage = 100
    
    for col in csv_cols:
        current_lineage += 1
        col_lineage_map[col] = current_lineage
        source_out_cols.append(f"""                    <outputColumn
                      refId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Output].Columns[{col}]"
                      dataType="wstr"
                      errorOrTruncationOperation="Conversion"
                      errorRowDisposition="FailComponent"
                      externalMetadataColumnId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Output].ExternalColumns[{col}]"
                      length="150"
                      lineageId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Output].Columns[{col}]"
                      name="{col}"
                      truncationRowDisposition="FailComponent">
                      <properties>
                        <property
                          dataType="System.Boolean"
                          description="Indicates whether the column uses the faster, locale-neutral parsing routines."
                          name="FastParse">false</property>
                        <property
                          dataType="System.Boolean"
                          description="Indicates whether the data is in binary format."
                          name="UseBinaryFormat">false</property>
                      </properties>
                    </outputColumn>""")
        source_ext_cols.append(f"""                    <externalMetadataColumn
                      refId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Output].ExternalColumns[{col}]"
                      dataType="wstr"
                      length="150"
                      name="{col}" />""")
    
    source_out_cols_str = "\n".join(source_out_cols)
    source_ext_cols_str = "\n".join(source_ext_cols)
    
    # OLE DB Destination inputColumns & externalMetadataColumns (based on mapped columns)
    dest_in_cols = []
    dest_ext_cols = []
    
    for csv_col, db_col in mappings:
        dest_in_cols.append(f"""                    <inputColumn
                      refId="Package\\{task_name}\\OLE DB Destination.Inputs[OLE DB Destination Input].Columns[{csv_col}]"
                      cachedDataType="wstr"
                      cachedLength="150"
                      cachedName="{csv_col}"
                      externalMetadataColumnId="Package\\{task_name}\\OLE DB Destination.Inputs[OLE DB Destination Input].ExternalColumns[{db_col}]"
                      lineageId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Output].Columns[{csv_col}]" />""")
        dest_ext_cols.append(f"""                    <externalMetadataColumn
                      refId="Package\\{task_name}\\OLE DB Destination.Inputs[OLE DB Destination Input].ExternalColumns[{db_col}]"
                      dataType="wstr"
                      length="150"
                      name="{db_col}" />""")
        
    dest_in_cols_str = "\n".join(dest_in_cols)
    dest_ext_cols_str = "\n".join(dest_ext_cols)

    content = f"""<?xml version="1.0"?>
<DTS:Executable xmlns:DTS="www.microsoft.com/SqlServer/Dts"
  DTS:refId="Package"
  DTS:CreationDate="10/28/2026 10:30:00 AM"
  DTS:CreationName="Microsoft.Package"
  DTS:CreatorComputerName="DEVELOPER"
  DTS:CreatorName="DEVELOPER\\Admin"
  DTS:DTSID="{pkg_dtsid}"
  DTS:ExecutableType="Microsoft.Package"
  DTS:LastModifiedProductVersion="17.0.1016.0"
  DTS:LocaleID="1066"
  DTS:ObjectName="{pkg_name}"
  DTS:PackageType="5"
  DTS:VersionBuild="1"
  DTS:VersionGUID="{version_guid}">
  <DTS:Property
    DTS:Name="PackageFormatVersion">8</DTS:Property>
  <DTS:ConnectionManagers>
    <DTS:ConnectionManager
      DTS:refId="Package.ConnectionManagers[{cm_name}]"
      DTS:CreationName="FLATFILE"
      DTS:DTSID="{flatfile_cm_id}"
      DTS:ObjectName="{cm_name}">
      <DTS:ObjectData>
        <DTS:ConnectionManager
          DTS:Format="Delimited"
          DTS:LocaleID="1066"
          DTS:HeaderRowDelimiter="_x000D__x000A_"
          DTS:ColumnNamesInFirstDataRow="True"
          DTS:RowDelimiter=""
          DTS:TextQualifier="_x0022_"
          DTS:CodePage="65001"
          DTS:ConnectionString="{file_path}">
          <DTS:FlatFileColumns>
{flat_file_columns_str}
          </DTS:FlatFileColumns>
        </DTS:ConnectionManager>
      </DTS:ObjectData>
    </DTS:ConnectionManager>
    <DTS:ConnectionManager
      DTS:refId="Package.ConnectionManagers[localhost.Fashion_Staging]"
      DTS:CreationName="OLEDB"
      DTS:DTSID="{oledb_cm_id}"
      DTS:ObjectName="localhost.Fashion_Staging">
      <DTS:ObjectData>
        <DTS:ConnectionManager
          DTS:ConnectRetryCount="1"
          DTS:ConnectRetryInterval="5"
          DTS:ConnectionString="Data Source=localhost;Initial Catalog=Fashion_Staging;Provider=MSOLEDBSQL.1;Integrated Security=SSPI;Auto Translate=False;Application Name=SSIS-{pkg_name}-{oledb_cm_id}localhost.Fashion_Staging;" />
      </DTS:ObjectData>
    </DTS:ConnectionManager>
  </DTS:ConnectionManagers>
  <DTS:Variables />
  <DTS:Executables>
    <DTS:Executable
      DTS:refId="Package\\{task_name}"
      DTS:CreationName="Microsoft.Pipeline"
      DTS:Description="Data Flow Task"
      DTS:DTSID="{task_dtsid}"
      DTS:ExecutableType="Microsoft.Pipeline"
      DTS:LocaleID="-1"
      DTS:ObjectName="{task_name}"
      DTS:TaskContact="Performs high-performance data extraction, transformation and loading;Microsoft Corporation; Microsoft SQL Server; (C) Microsoft Corporation; All Rights Reserved;http://www.microsoft.com/sql/support/default.asp;1">
      <DTS:Variables />
      <DTS:ObjectData>
        <pipeline
          version="1">
          <components>
            <component
              refId="Package\\{task_name}\\Flat File Source"
              componentClassID="Microsoft.FlatFileSource"
              contactInfo="Flat File Source;Microsoft Corporation; Microsoft SQL Server; (C) Microsoft Corporation; All Rights Reserved; http://www.microsoft.com/sql/support;1"
              description="Flat File Source"
              localeId="1066"
              name="Flat File Source"
              usesDispositions="true"
              version="1">
              <properties>
                <property
                  dataType="System.Boolean"
                  description="Specifies whether zero-length columns are treated as null."
                  name="RetainNulls">false</property>
                <property
                  dataType="System.String"
                  description="Specifies the name of an output column containing the file name. If no name is specified, no output column containing the file name will be generated."
                  name="FileNameColumnName"></property>
              </properties>
              <connections>
                <connection
                  refId="Package\\{task_name}\\Flat File Source.Connections[FlatFileConnection]"
                  connectionManagerID="Package.ConnectionManagers[{cm_name}]"
                  connectionManagerRefId="Package.ConnectionManagers[{cm_name}]"
                  name="FlatFileConnection" />
              </connections>
              <outputs>
                <output
                  refId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Output]"
                  name="Flat File Source Output">
                  <outputColumns>
{source_out_cols_str}
                  </outputColumns>
                  <externalMetadataColumns
                    isUsed="True">
{source_ext_cols_str}
                  </externalMetadataColumns>
                </output>
                <output
                  refId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Error Output]"
                  isErrorOut="true"
                  name="Flat File Source Error Output">
                  <outputColumns>
                    <outputColumn
                      refId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Error Output].Columns[Flat File Source Error Output Column]"
                      codePage="65001"
                      dataType="text"
                      description="Flat File Source Error Output Column"
                      lineageId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Error Output].Columns[Flat File Source Error Output Column]"
                      name="Flat File Source Error Output Column" />
                    <outputColumn
                      refId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Error Output].Columns[ErrorCode]"
                      dataType="i4"
                      lineageId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Error Output].Columns[ErrorCode]"
                      name="ErrorCode"
                      specialFlags="1" />
                    <outputColumn
                      refId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Error Output].Columns[ErrorColumn]"
                      dataType="i4"
                      lineageId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Error Output].Columns[ErrorColumn]"
                      name="ErrorColumn"
                      specialFlags="2" />
                  </outputColumns>
                  <externalMetadataColumns />
                </output>
              </outputs>
            </component>
            <component
              refId="Package\\{task_name}\\OLE DB Destination"
              componentClassID="Microsoft.OLEDBDestination"
              contactInfo="OLE DB Destination;Microsoft Corporation; Microsoft SQL Server; (C) Microsoft Corporation; All Rights Reserved; http://www.microsoft.com/sql/support;4"
              description="OLE DB Destination"
              name="OLE DB Destination"
              usesDispositions="true"
              version="4">
              <properties>
                <property
                  dataType="System.Int32"
                  description="The number of seconds before a command times out.  A value of 0 indicates an infinite time-out."
                  name="CommandTimeout">0</property>
                <property
                  dataType="System.String"
                  description="Specifies the name of the database object used to open a rowset."
                  name="OpenRowset">{table_name}</property>
                <property
                  dataType="System.String"
                  description="Specifies the variable that contains the name of the database object used to open a rowset."
                  name="OpenRowsetVariable"></property>
                <property
                  dataType="System.String"
                  description="The SQL command to be executed."
                  name="SqlCommand"
                  UITypeEditor="Microsoft.DataTransformationServices.Controls.ModalMultilineStringEditor"></property>
                <property
                  dataType="System.Int32"
                  description="Specifies the column code page to use when code page information is unavailable from the data source."
                  name="DefaultCodePage">1258</property>
                <property
                  dataType="System.Boolean"
                  description="Forces the use of the DefaultCodePage property value when describing character data."
                  name="AlwaysUseDefaultCodePage">false</property>
                <property
                  dataType="System.Int32"
                  description="Specifies the mode used to access the database."
                  name="AccessMode"
                  typeConverter="AccessMode">3</property>
                <property
                  dataType="System.Boolean"
                  description="Indicates whether the values supplied for identity columns will be copied to the destination. If false, values for identity columns will be auto-generated at the destination. Applies only if fast load is turned on."
                  name="FastLoadKeepIdentity">false</property>
                <property
                  dataType="System.Boolean"
                  description="Indicates whether the columns containing null will have null inserted in the destination. If false, columns containing null will have their default values inserted at the destination. Applies only if fast load is turned on."
                  name="FastLoadKeepNulls">false</property>
                <property
                  dataType="System.String"
                  description="Specifies options to be used with fast load.  Applies only if fast load is turned on."
                  name="FastLoadOptions">TABLOCK,CHECK_CONSTRAINTS</property>
                <property
                  dataType="System.Int32"
                  description="Specifies when commits are issued during data insertion.  A value of 0 specifies that one commit will be issued at the end of data insertion.  Applies only if fast load is turned on."
                  name="FastLoadMaxInsertCommitSize">2147483647</property>
              </properties>
              <connections>
                <connection
                  refId="Package\\{task_name}\\OLE DB Destination.Connections[OleDbConnection]"
                  connectionManagerID="Package.ConnectionManagers[localhost.Fashion_Staging]"
                  connectionManagerRefId="Package.ConnectionManagers[localhost.Fashion_Staging]"
                  description="The OLE DB runtime connection used to access the database."
                  name="OleDbConnection" />
              </connections>
              <inputs>
                <input
                  refId="Package\\{task_name}\\OLE DB Destination.Inputs[OLE DB Destination Input]"
                  errorOrTruncationOperation="Insert"
                  errorRowDisposition="FailComponent"
                  hasSideEffects="true"
                  name="OLE DB Destination Input">
                  <inputColumns>
{dest_in_cols_str}
                  </inputColumns>
                  <externalMetadataColumns
                    isUsed="True">
{dest_ext_cols_str}
                  </externalMetadataColumns>
                </input>
              </inputs>
              <outputs>
                <output
                  refId="Package\\{task_name}\\OLE DB Destination.Outputs[OLE DB Destination Error Output]"
                  exclusionGroup="1"
                  isErrorOut="true"
                  name="OLE DB Destination Error Output"
                  synchronousInputId="Package\\{task_name}\\OLE DB Destination.Inputs[OLE DB Destination Input]">
                  <outputColumns>
                    <outputColumn
                      refId="Package\\{task_name}\\OLE DB Destination.Outputs[OLE DB Destination Error Output].Columns[ErrorCode]"
                      dataType="i4"
                      lineageId="Package\\{task_name}\\OLE DB Destination.Outputs[OLE DB Destination Error Output].Columns[ErrorCode]"
                      name="ErrorCode"
                      specialFlags="1" />
                    <outputColumn
                      refId="Package\\{task_name}\\OLE DB Destination.Outputs[OLE DB Destination Error Output].Columns[ErrorColumn]"
                      dataType="i4"
                      lineageId="Package\\{task_name}\\OLE DB Destination.Outputs[OLE DB Destination Error Output].Columns[ErrorColumn]"
                      name="ErrorColumn"
                      specialFlags="2" />
                  </outputColumns>
                  <externalMetadataColumns />
                </output>
              </outputs>
            </component>
          </components>
          <paths>
            <path
              refId="Package\\{task_name}.Paths[Flat File Source Output]"
              endId="Package\\{task_name}\\OLE DB Destination.Inputs[OLE DB Destination Input]"
              name="Flat File Source Output"
              startId="Package\\{task_name}\\Flat File Source.Outputs[Flat File Source Output]" />
          </paths>
        </pipeline>
      </DTS:ObjectData>
    </DTS:Executable>
  </DTS:Executables>
</DTS:Executable>"""
    out_file = SSIS_DIR / f"{pkg_name}.dtsx"
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Generated {out_file.name}")

for cfg in PACKAGES_CONFIG:
    generate_package(cfg)

print("All 5 SSIS packages generated successfully.")
