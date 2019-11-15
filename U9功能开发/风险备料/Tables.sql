--预测订单
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
--预测行
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
DemandDate VARCHAR(20),--所属月份
DeliveryDate DATETIME,--交期
Remark NVARCHAR(500)
)

