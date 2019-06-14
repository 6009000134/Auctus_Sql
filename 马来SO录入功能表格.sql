--SELECT * FROM dbo.SM_SO
--SO��ͷ
CREATE TABLE Auctus_SO 
(
ID INT PRIMARY KEY IDENTITY(1,1),
DocNo VARCHAR(100),
Customer_Code VARCHAR(100),
Customer_Name NVARCHAR(255),
BusinessDate DATETIME,
Operator NVARCHAR(20),
CreateBy NVARCHAR(255),
CreateOn DATETIME,
ModifyBy NVARCHAR(255),
ModifyOn DATETIME,
Remark NVARCHAR(4000),
Itemmaster BIGINT,
Code VARCHAR(50),
Name NVARCHAR(300),
SPECS NVARCHAR(600),
Qty int
)

--SO��
CREATE TABLE Auctus_SOLine
(
ID INT PRIMARY KEY IDENTITY(1,1),
DocLineNo INT,
Itemmaster BIGINT,
Code VARCHAR(100),
Name NVARCHAR(300),
SPECS NVARCHAR(300),
Qty INT,
RequireDate DATETIME,
U9_DocNo VARCHAR(100),
Customer_DocNo VARCHAR(100),
HK_DocNo VARCHAR(100),
Remark NVARCHAR(4000),
SO INT,--Auctus_SO ID
CreateBy NVARCHAR(255),
CreateOn DATETIME,
ModifyBy NVARCHAR(255),
ModifyOn DATETIME
)


