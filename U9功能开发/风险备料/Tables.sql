--Ԥ�ⶩ��
CREATE TABLE Auctus_Forecast
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreatedOn DATETIME,
CreatedBy NVARCHAR(20),
ModifiedOn DATETIME,
ModifiedBy NVARCHAR(20),
DocNo VARCHAR(50),
Customer BIGINT,
Customer_Name NVARCHAR(255),
BusinessDate DATETIME,
Remark NVARCHAR(400),
DocType NVARCHAR(20)
)
--Ԥ����
CREATE TABLE Auctus_ForecastLine
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreatedOn DATETIME,
CreatedBy NVARCHAR(20),
ModifiedOn DATETIME,
ModifiedBy NVARCHAR(20),
Forecast INT,
DocLineNo INT,
Itemmaster BIGINT,
Code VARCHAR(50),
Name NVARCHAR(300),
SPECS NVARCHAR(600),
Qty INT,
DemandDate VARCHAR(20),--�����·�
DeliveryDate DATETIME,--����
Remark NVARCHAR(500)
)

