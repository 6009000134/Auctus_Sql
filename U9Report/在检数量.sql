
BEGIN
DECLARE @pageSize INT=100,
@pageIndex INT=1,
@SupplierID BIGINT
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT=@pageSize*@pageIndex+1
--DECLARE @QuerySupplier BIGINT=NULL
SET NOCOUNT ON 
--8周起始日期天汇总列表
DECLARE @SD1 DATE,@ED1 DATE
DECLARE @Date DATE=GETDATE();
SET @Date='2019-9-9'

SET @SD1=DATEADD(DAY,2+(-1)*DATEPART(WEEKDAY,GETDATE()),GETDATE())
SET @ED1=DATEADD(DAY,7,@SD1)
--组织号	
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')

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
BEGIN
	TRUNCATE TABLE #tempTable
END 

--取每天7点备份的8周齐套数据
INSERT INTO #tempTable 
SELECT
DocNo ,
DocLineNo ,
PickLineNo ,
DocType ,
ProductID ,
ProductCode ,
ProductName ,
ProductSPECS ,
ProductQty ,
DemandCode ,
ItemMaster ,
Code ,
Name ,
SPEC ,
SafetyStockQty ,
IssuedQty ,
STDReqQty ,
ActualReqQty ,
ReqQty ,
ActualReqDate ,
RN ,
DemandCode2 ,
LackAmount ,
IsLack ,
WhavailiableAmount ,
PRList ,
PRApprovedQty ,
PRFlag ,
POList ,
POReqQtyTu ,
RCVList ,
ArriveQtyTU ,
RcvQtyTU ,
RcvFlag ,
ResultFlag ,
DescFlexField_PrivateDescSeg19 ,--客户产品名称
DescFlexField_PrivateDescSeg20 ,--项目编码
DescFlexField_PrivateDescSeg21 ,--项目代号
DescFlexField_PrivateDescSeg23 ,--执行采购员
MRPCode ,--MRP分类
MRPCategory ,--MRP分类
Buyer ,--执行采购分类
MCCode,--MC负责人编码
MCName,--MC负责人
FixedLT ,--固定提前期
ProductLine --产品系列
FROM dbo.Auctus_FullSetCheckResult8 
WHERE CONVERT(DATE,CopyDate)=@Date

--在检收货单集合
IF OBJECT_ID(N'tempdb.dbo.#tempRCV',N'U') IS NULL
BEGIN
	CREATE TABLE #tempRCV(Code VARCHAR(50),DocNo VARCHAR(50),DocLineNo INT,RcvQty INT,PODocNo VARCHAR(50),PODocLineNo INT,POSubLineNo INT)
END 
ELSE
BEGIN
	TRUNCATE TABLE #tempRCV
END 

--工单的实际需求时间=实际需求时间-原材料采购后处理期
--委外WPO实际需求时间=实际需求时间-采购组件采购前处理提前期-原材料采购后处理期
UPDATE #tempTable 
SET ActualReqDate=CASE WHEN #tempTable.DocNo LIKE'WPO%' THEN  DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0)+ISNULL(b.PurForwardProcessLT,0))*(-1),ActualReqDate)
ELSE DATEADD(DAY,(ISNULL(a.PurBackwardProcessLT,0))*(-1),ActualReqDate) END 
FROM CBO_MrpInfo a,dbo.CBO_MrpInfo b WHERE a.ItemMaster=#tempTable.ItemMaster AND b.ItemMaster=#tempTable.ProductID

IF EXISTS(select * from tempdb..sysobjects where id=object_id('tempdb.dbo.#tempW8'))
BEGIN
	DROP TABLE #tempW8
END 


--8周汇总列表
;
WITH data1 AS
(
SELECT 
CASE WHEN a.ActualReqDate <@SD1  THEN 'w0'
WHEN a.ActualReqDate>=@SD1 AND a.ActualReqDate<@ED1 THEN 'w1'
WHEN a.ActualReqDate>=DATEADD(DAY,7,@SD1) AND a.ActualReqDate<DATEADD(DAY,7,@ED1) 
THEN 'w2'
WHEN a.ActualReqDate>=DATEADD(DAY,14,@SD1) AND a.ActualReqDate<DATEADD(DAY,14,@ED1) 
THEN 'w3'
WHEN a.ActualReqDate>=DATEADD(DAY,21,@SD1) AND a.ActualReqDate<DATEADD(DAY,21,@ED1) 
THEN 'w4'
WHEN a.ActualReqDate>=DATEADD(DAY,28,@SD1) AND a.ActualReqDate<DATEADD(DAY,28,@ED1) 
THEN 'w5'
WHEN a.ActualReqDate>=DATEADD(DAY,35,@SD1) AND a.ActualReqDate<DATEADD(DAY,35,@ED1) 
THEN 'w6'
WHEN a.ActualReqDate>=DATEADD(DAY,42,@SD1) AND a.ActualReqDate<DATEADD(DAY,42,@ED1) 
THEN 'w7'
WHEN a.ActualReqDate>=DATEADD(DAY,49,@SD1) AND a.ActualReqDate<DATEADD(DAY,49,@ED1) 
THEN 'w8'
ELSE '' END Duration
,a.MRPCategory,a.Buyer,a.MCName,a.Code,a.Name,a.SPEC,ISNULL(a.LackAmount,0)LackAmount
FROM #tempTable a 
),
data2 AS--行专列 汇总每周的欠料数量
(
SELECT * 
FROM data1 a  
PIVOT(SUM(a.LackAmount) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
),
data3 AS
(
SELECT code,MAX(a.WhavailiableAmount+a.ReqQty)WhQty,min(a.WhAvailiableAmount)WhAvailiableAmount--,MIN(a.SafetyStockQty)SafetyStockQty
FROM #tempTable a  
GROUP BY a.Code 
)
SELECT a.*,b.WhQty,b.WhAvailiableAmount--,b.SafetyStockQty 
INTO #tempW8 
FROM data2  a LEFT JOIN data3 b ON a.Code=b.Code


BEGIN


--采购未交数据集合
IF OBJECT_ID(N'tempdb.dbo.#tempDeficiency',N'U') IS NULL
CREATE TABLE #tempDeficiency
(
Supplier NVARCHAR(300),
DocNo VARCHAR(50),
DocLineNo INT,
SubLineNo INT,
Code VARCHAR(50),
PlanArriveDate DATETIME,
DeficiencyQty DECIMAL(18,4),
RN INT
)
ELSE
BEGIN
TRUNCATE TABLE #tempDeficiency
END	

IF ISNULL(@SupplierID,'')=''
BEGIN
	;
	WITH data1 AS
	(
	SELECT 
	s.ID Supplier,a.DocNo,b.DocLineNo,c.SubLineNo,b.ItemInfo_ItemCode,c.SupplierConfirmQtyTU,c.DeficiencyQtyTU,c.PlanArriveDate
	,ROW_NUMBER()OVER(ORDER BY c.PlanArriveDate)RN--按计划到货日期排序
	--,s.DescFlexField_PrivateDescSeg3
	FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
	INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
	INNER JOIN dbo.CBO_ItemMaster m ON c.ItemInfo_ItemID=m.ID
	LEFT JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID
	WHERE a.Org=@Org AND a.Status=2 AND b.Status=2 AND c.DeficiencyQtyTU>0
	--AND s.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
	--AND m.DescFlexField_PrivateDescSeg22 IN ('MRP104','MRP105','MRP106','MRP113','MRP100','MRP101','MRP102','MRP103','MRP107')
	)
	INSERT INTO #tempDeficiency
	SELECT a.Supplier,a.DocNo,a.DocLineNo,a.SubLineNo,a.ItemInfo_ItemCode,a.PlanArriveDate,a.DeficiencyQtyTU,a.RN FROM data1 a
END 
ELSE
BEGIN
	;
	WITH data1 AS
	(
	SELECT 
	s.ID Supplier,a.DocNo,b.DocLineNo,c.SubLineNo,b.ItemInfo_ItemCode,c.SupplierConfirmQtyTU,c.DeficiencyQtyTU,c.PlanArriveDate
	,ROW_NUMBER()OVER(ORDER BY c.PlanArriveDate)RN--按计划到货日期排序
	--,s.DescFlexField_PrivateDescSeg3
	FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
	INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
	INNER JOIN dbo.CBO_ItemMaster m ON c.ItemInfo_ItemID=m.ID
	LEFT JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID
	WHERE a.Org=@Org AND a.Status=2 AND b.Status=2 AND c.DeficiencyQtyTU>0
	AND s.ID=@SupplierID
	--AND s.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
	--AND m.DescFlexField_PrivateDescSeg22 IN ('MRP104','MRP105','MRP106','MRP113','MRP100','MRP101','MRP102','MRP103','MRP107')
	)
	INSERT INTO #tempDeficiency
	SELECT a.Supplier,a.DocNo,a.DocLineNo,a.SubLineNo,a.ItemInfo_ItemCode,a.PlanArriveDate,a.DeficiencyQtyTU,a.RN FROM data1 a
END 


INSERT INTO #tempRCV
SELECT 
b.ItemInfo_ItemCode,a.DocNo,b.DocLineNo,b.RcvQtyTU
,b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
WHERE a.Org=@Org
AND a.Status IN (0,3) AND b.Status IN (0,3)
AND a.ReceivementType=0
END 

;WITH RCV AS 
(
SELECT 
MIN(b.Code)ItemInfo_ItemCode,SUM(b.RcvQty)RcvQty
,b.PODocNo,b.PODocLineNo,b.POSubLineNo
,(SELECT a.DocNo+'-'+CONVERT(VARCHAR(10),a.DocLineNo)+',' FROM #tempRCV a WHERE a.PODocNo=b.PODocNo AND a.PODocLineNo=b.PODocLineNo AND a.POSubLineNo=b.POSubLineNo FOR XML PATH(''))RCVList
FROM #tempRCV b
GROUP BY b.PODocNo,b.PODocLineNo,b.POSubLineNo
)
--SELECT * FROM RCV
SELECT * FROM (
SELECT s1.Name SupName,a.MRPCategory,a.Buyer,a.MCName,a.Code,a.Name,a.SPEC,b.DocNo,b.DocLineNo,b.SubLineNo,FORMAT(b.PlanArriveDate,'yyyy-MM-dd HH:mm:ss')PlanArriveDate,CONVERT(INT,b.DeficiencyQty)DeficiencyQty--,b.Code
,rcv.RcvQty
,rcv.RCVList
--,rcv.*
,ROW_NUMBER() OVER(ORDER BY a.Name,a.Code,b.RN)RN
FROM #tempW8 a  INNER JOIN #tempDeficiency b ON a.Code=b.Code
LEFT JOIN RCV rcv ON b.DocNo=rcv.PODocNo AND b.DocLineNo=rcv.PODocLineNo AND b.SubLineNo=rcv.POSubLineNo
LEFT JOIN dbo.CBO_Supplier s ON b.Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.id  AND ISNULL(s1.SysMLFlag,'zh-cn')='zh-cn'
WHERE ISNULL(rcv.RcvQty,0)<>0 --AND rcv.PODocNo='PO30190723015'
) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

SELECT COUNT(1)Count
FROM #tempW8 a  INNER JOIN #tempDeficiency b ON a.Code=b.Code

END 
