--SELECT * FROM dbo.qz_SaleAgent
--SELECT * FROM dbo.qz_SaleDeliver
--SELECT * FROM dbo.qz_SaleDeliverDtl

/*
泉州销售代理商
*/
CREATE TABLE qz_SOAgent
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(50),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy NVARCHAR(50),
ModifyDate DATETIME,
Code NVARCHAR(50),--编码
Name NVARCHAR(300),--名称
Contact NVARCHAR(50),--联系人
ContactNumber NVARCHAR(200),--电话/手机号码
Remark NVARCHAR(500)
)
/*
泉州销售表
*/
CREATE TABLE qz_SO
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(50),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy NVARCHAR(50),
ModifyDate DATETIME,
DocNo VARCHAR(100),--单号
SOAgentID INT,--代理商
SOAgentCode NVARCHAR(50),
SOAgentName NVARCHAR(300),
MaterialID INT,--料号
MaterialCode NVARCHAR(50),
MaterialName NVARCHAR(300),
Quantity INT,--销售数量
Status INT--订单状态
)
/*
泉州销售明细表
*/
CREATE TABLE qz_SODetail
(
ID INT PRIMARY KEY IDENTITY(1,1),
CreateBy NVARCHAR(50),
CreateDate DATETIME DEFAULT(GETDATE()),
ModifyBy NVARCHAR(50),
ModifyDate DATETIME,
SOID INT,
PackageNO VARCHAR(50),--箱号
BSN NVARCHAR(100)--内控码
)


