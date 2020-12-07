
/*
备份mes3天齐套数据
*/
EXEC sp_Auctus_BackUp_FullSetResult3_Mes
create PROC [dbo].[sp_Auctus_BackUp_FullSetResult3_Mes]
AS
BEGIN
DECLARE @Date DATE
SET @Date=GETDATE()

IF OBJECT_ID(N'tempdb.dbo.#tempTable',N'U') IS NULL
CREATE TABLE #tempTable
(
DocNo VARCHAR(50),
DocLineNo VARCHAR(10),
PickLineNo VARCHAR(10),
DocType NVARCHAR(20),
ProductID BIGINT,
ProductCode VARCHAR(50),
ProductName NVARCHAR(255),
ProductSPECS NVARCHAR(300),
ProductQty DECIMAL(18,0),
U9ProductQty DECIMAL(18,0),
DemandCode VARCHAR(20),
ItemMaster BIGINT,
Code VARCHAR(30),
Name NVARCHAR(255),
SPEC NVARCHAR(600),
SafetyStockQty DECIMAL(18,0),
IssuedQty DECIMAL(18,0),
STDReqQty DECIMAL(18,0),
ActualReqQty DECIMAL(18,0),
ReqQty DECIMAL(18,0),
ActualReqDate DATE,
RN INT,
DemandCode2 VARCHAR(50),
LackAmount INT,
IsLack NVARCHAR(20),
WhavailiableAmount INT,
PRList VARCHAR(MAX),
PRApprovedQty DECIMAL(18,0),
PRFlag NVARCHAR(10),
POList VARCHAR(MAX),
POReqQtyTu DECIMAL(18,0),
RCVList VARCHAR(MAX),
ArriveQtyTU DECIMAL(18,0),
RcvQtyTU DECIMAL(18,0),
RcvFlag NVARCHAR(10),
ResultFlag NVARCHAR(30),
DescFlexField_PrivateDescSeg19 NVARCHAR(300),--客户产品名称
DescFlexField_PrivateDescSeg20 NVARCHAR(300),--项目编码
DescFlexField_PrivateDescSeg21 NVARCHAR(300),--项目代号
DescFlexField_PrivateDescSeg23 NVARCHAR(300),--执行采购员
MRPCode VARCHAR(50),--MRP分类
MRPCategory NVARCHAR(300),--MRP分类
Buyer NVARCHAR(20),--执行采购分类
MCCode VARCHAR(20),--MC负责人编码
MCName NVARCHAR(20),--MC负责人
FixedLT DECIMAL(18,0),--固定提前期
ProductLine NVARCHAR(255)--产品系列
)
ELSE
TRUNCATE TABLE #tempTable
INSERT INTO #tempTable EXEC sp_Auctus_AllSetCheckByMes 1001708020135665,'','',''

--备份8周齐套数据
INSERT INTO Auctus_Mes_FullSetCheckResult3 SELECT *,DATEPART(YEAR,@Date),DATEPART(MONTH,@Date),GETDATE() FROM #tempTable

END 
