
BEGIN
DECLARE @SupplierIDs VARCHAR(MAX)=''
--SET @SupplierIDs =''
SET NOCOUNT ON 

--8周起始日期天汇总列表
--取8周欠料数据
BEGIN 

 
 
DECLARE @SD1 DATE,@ED1 DATE
DECLARE @Date DATE=GETDATE();
SET @SD1=DATEADD(DAY,2+(-1)*DATEPART(WEEKDAY,GETDATE()),GETDATE())
SET @ED1=DATEADD(DAY,7,@SD1)

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
END--End 取8周数据

--邮件数据处理
BEGIN

--组织号	
DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='300')
--采购未交数据集合
IF OBJECT_ID(N'tempdb.dbo.#tempDeficiency',N'U') IS NULL
CREATE TABLE #tempDeficiency
(
Supplier NVARCHAR(300),
Code VARCHAR(50),
DeficiencyQty DECIMAL(18,4),
IsPurchaseOrder INT,--0在检收货、1采购未交
RN INT
)
ELSE
BEGIN
TRUNCATE TABLE #tempDeficiency
END	


--发送邮件数据
IF OBJECT_ID(N'tempdb.dbo.#tempSend',N'U') IS NULL
BEGIN
	CREATE TABLE #tempSend
	(Supplier NVARCHAR(300)
	,Purchaser NVARCHAR(20)
	,Email NVARCHAR(50)
	,Code VARCHAR(50)
	,Name NVARCHAR(255)
	,SPECS NVARCHAR(300)
	,w0 INT,w1 INT,w2 INT,w3 INT, w4 INT ,w5 INT ,w6 INT,w7 INT ,w8 INT
	,Total INT--8周欠料汇总
	,RN INT--按供应商排序 
	)
END
ELSE
BEGIN
	TRUNCATE TABLE #tempSend
end

--查询所有未交供应商信息
;WITH data1 AS
(
SELECT 
s.ID Supplier,a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,c.SupplierConfirmQtyTU,c.DeficiencyQtyTU,c.PlanArriveDate
,c.DeficiencyQtyCU
,c.DeficiencyQtyPU
,c.DeficiencyQtySU
,c.DeficiencyQtyTBU
,ROW_NUMBER()OVER(ORDER BY c.PlanArriveDate)RN--按计划到货日期排序
--,s.DescFlexField_PrivateDescSeg3
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
INNER JOIN dbo.CBO_ItemMaster m ON c.ItemInfo_ItemID=m.ID
LEFT JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID
WHERE a.Org=@Org AND a.Status=2 AND b.Status=2 AND c.DeficiencyQtyTU>0
--AND s.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
)
INSERT INTO #tempDeficiency
SELECT a.Supplier,a.ItemInfo_ItemCode,a.DeficiencyQtyTU,1,a.RN FROM data1 a WHERE a.ItemInfo_ItemCode='334010085'


INSERT INTO #tempDeficiency
SELECT 
a.Supplier_Supplier,b.ItemInfo_ItemCode,SUM(ISNULL(b.RcvQtyTU,0))RcvQtyTU,0,0
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
WHERE a.Org=@Org
AND a.Status IN (0,3) AND b.Status IN (0,3)
AND a.ReceivementType=0 
AND b.ItemInfo_ItemCode='334010085'
GROUP BY a.Supplier_Supplier,b.ItemInfo_ItemCode



IF OBJECT_ID(N'tempdb.dbo.#tempSupResult',N'U') IS NULL
BEGIN
CREATE TABLE #tempSupResult(Supplier BIGINT,Code VARCHAR(50),IsPurchaseOrder INT,Qty INT,Duration VARCHAR(4))
END
ELSE
BEGIN
TRUNCATE TABLE #tempSupResult
END

--计算供应商交料计划
DECLARE @RN INT
DECLARE @code VARCHAR(50),@w0 int,@w1 int ,@w2 int ,@w3 INT,@w4 INT,@w5 int,@w6 int ,@w7 int ,@w8 int 
DECLARE @Supplier bigint ,@code2 VARCHAR(50),@Qty decimal(18,4),@Duration varchar(4),@IsPurchaserOrder INT 
DECLARE curSup CURSOR
FOR
SELECT Code,w0,w1,w2,w3,w4,w5,w6,w7,w8 FROM #tempW8 WHERE whAvailiableAmount<0 --获取有欠料的料号
OPEN curSup
FETCH NEXT FROM curSup INTO @code,@w0,@w1,@w2,@w3,@w4,@w5,@w6,@w7,@w8
WHILE @@fetch_status=0
BEGIN
	DECLARE @tempLackQty INT=ISNULL(@w0,0)*(-1)--欠料数量
	,@tempWeek VARCHAR(4)='w0'--欠料周
	DECLARE curDeficiency CURSOR
    FOR
	SELECT Supplier,Code,IsPurchaseOrder,DeficiencyQty,RN FROM #tempDeficiency WHERE Code=@code ORDER BY RN	--按计划到货日期排序
	OPEN curDeficiency
	FETCH NEXT FROM curDeficiency INTO @Supplier,@code2,@IsPurchaserOrder,@Qty,@RN
	WHILE	@@FETCH_STATUS=0
	BEGIN
		DECLARE @QtyData INT--交料数量
		--当供应商未交数量能够满足当前欠料，未交数量尾数移到一下周继续计算。
		--例如：第一周欠交100，供应商采购行未交数量为1000，则多出的900未交移到第二周继续计算。
		WHILE @Qty>0
		BEGIN
			WHILE ISNULL(@tempLackQty,0)=0--当本周欠料数量=0，取下周欠料数量
			BEGIN 
				SET @tempWeek= CASE WHEN @tempWeek='w0' THEN  'w1' 
									WHEN @tempWeek='w1' THEN  'w2' 
									WHEN @tempWeek='w2' THEN  'w3' 
									WHEN @tempWeek='w3' THEN  'w4' 
									WHEN @tempWeek='w4' THEN  'w5' 
									WHEN @tempWeek='w5' THEN  'w6' 
									WHEN @tempWeek='w6' THEN  'w7' 
									WHEN @tempWeek='w7' THEN  'w8' 
									ELSE '' END 
				SET @tempLackQty=CASE 	WHEN @tempWeek='w1' THEN  ISNULL(@w1,0)*(-1) 
										WHEN @tempWeek='w2' THEN  ISNULL(@w2,0)*(-1)
										WHEN @tempWeek='w3' THEN  ISNULL(@w3,0)*(-1)
										WHEN @tempWeek='w4' THEN  ISNULL(@w4,0)*(-1)
										WHEN @tempWeek='w5' THEN  ISNULL(@w5,0)*(-1)
										WHEN @tempWeek='w6' THEN  ISNULL(@w6,0)*(-1)
										WHEN @tempWeek='w7' THEN  ISNULL(@w7,0)*(-1)
										WHEN @tempWeek='w8' THEN  ISNULL(@w8,0)*(-1)
										ELSE 0 END 
				IF ISNULL(@tempWeek,'')=''--如果超过8周了，退出循环
				break;
			END 
			 
			IF ISNULL(@tempWeek,'')=''
			break;--如果超过8周了，退出循环
			IF @Qty<=@tempLackQty--供应商未交数量<=当周欠交数量
			BEGIN
				SET @QtyData=@Qty
				SET @tempLackQty=@tempLackQty-@Qty
				SET @Qty=0
			END 
			ELSE--供应商未交数量>当周欠交数量
            BEGIN
				SET @QtyData=@tempLackQty
				SET @Qty=@Qty-@tempLackQty
				SET @tempLackQty=0
			END 
			--插入供应商交货计划
			INSERT INTO #tempSupResult
				        ( Supplier, Code,IsPurchaseOrder, Qty, Duration )
				VALUES  ( @Supplier, -- Supplier - bigint
				          @code2, -- Code - varchar(50)
						  @IsPurchaserOrder,
				          @QtyData, -- Qty - decimal(18, 4)
				          @tempWeek  -- Duration - varchar(4)
				          )
						
		END          		       

		FETCH NEXT FROM curDeficiency INTO @Supplier,@code2,@IsPurchaserOrder,@Qty,@RN
	END 
	CLOSE curDeficiency
	DEALLOCATE curDeficiency--关闭curDeficiency游标    
	FETCH NEXT FROM curSup INTO @code,@w0,@w1,@w2,@w3,@w4,@w5,@w6,@w7,@w8
END 
CLOSE curSup
DEALLOCATE curSup--关闭curSup游标 
--SELECT * FROM #tempRcv
DELETE FROM #tempSupResult WHERE IsPurchaseOrder=0
--保存待发送邮件数据
IF ISNULL(@SupplierIDs,'')=''
BEGIN 
	;
	WITH data1 AS--根据供应商交货计划，“周”行专列，按周汇总
	(
	SELECT * FROM #tempSupResult  a 
	PIVOT(SUM(a.Qty) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
	),
	data2 AS--按料号汇总每家供应商8周欠料数量
	(
	SELECT a.Supplier,a.Code,sum(a.Qty)Total FROM #tempSupResult a GROUP BY a.Supplier,a.Code
	)
	INSERT INTO #tempSend
	SELECT a1.Name,op1.Name--,c1.Name,b.IsDefault
	,c.DefaultEmail,m.Code,m.Name,m.SPECS,r.w0,r.w1,r.w2,r.w3,r.w4,r.w5,r.w6,r.w7,r.w8,r2.Total,DENSE_RANK()OVER(ORDER BY a1.Name)RN 
	FROM data1 r INNER JOIN data2 r2 ON r.Supplier=r2.Supplier AND r.Code=r2.Code  LEFT JOIN  dbo.CBO_Supplier a ON r.Supplier=a.ID LEFT JOIN dbo.CBO_Supplier_Trl a1 ON a.ID=a1.ID
	LEFT JOIN dbo.CBO_Operators_Trl op1 ON a.Purchaser=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
	LEFT JOIN dbo.CBO_SupplierContact b ON a.ID=b.Supplier AND b.IsDefault=1
	LEFT JOIN dbo.Base_Contact c ON b.Contact=c.ID LEFT JOIN dbo.Base_Contact_Trl c1 ON c.ID=c1.ID
	LEFT JOIN dbo.CBO_ItemMaster m ON r.Code=m.Code AND m.Org=@Org
	WHERE  a.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
END 
ELSE
BEGIN
	;
	WITH data1 AS--根据供应商交货计划，“周”行专列，按周汇总
	(
	SELECT * FROM #tempSupResult  a 
	PIVOT(SUM(a.Qty) FOR duration IN ([w0],[w1],[w2],[w3],[w4],[w5],[w6],[w7],[w8])) AS t
	),
	data2 AS--按料号汇总每家供应商8周欠料数量
	(
	SELECT a.Supplier,a.Code,sum(a.Qty)Total FROM #tempSupResult a GROUP BY a.Supplier,a.Code
	)
	INSERT INTO #tempSend
	SELECT a1.Name,ISNULL(op1.Name,'')--,c1.Name,b.IsDefault
	,ISNULL(c.DefaultEmail,'')DefaultEmail,m.Code,m.Name,m.SPECS,ISNULL(r.w0,0)w0,ISNULL(r.w1,0)w1,ISNULL(r.w2,0)w2,ISNULL(r.w3,0)w3
	,ISNULL(r.w4,0)w4,ISNULL(r.w5,0)w5,ISNULL(r.w6,0)w6,ISNULL(r.w7,0)w7,ISNULL(r.w8,0)w8,ISNULL(r2.Total,0)Total,DENSE_RANK()OVER(ORDER BY a1.Name)RN 
	FROM data1 r INNER JOIN data2 r2 ON r.Supplier=r2.Supplier AND r.Code=r2.Code  LEFT JOIN  dbo.CBO_Supplier a ON r.Supplier=a.ID LEFT JOIN dbo.CBO_Supplier_Trl a1 ON a.ID=a1.ID
	LEFT JOIN dbo.CBO_Operators_Trl op1 ON a.Purchaser=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
	LEFT JOIN dbo.CBO_SupplierContact b ON a.ID=b.Supplier AND b.IsDefault=1
	LEFT JOIN dbo.Base_Contact c ON b.Contact=c.ID LEFT JOIN dbo.Base_Contact_Trl c1 ON c.ID=c1.ID
	LEFT JOIN dbo.CBO_ItemMaster m ON r.Code=m.Code AND m.Org=@Org
	WHERE r.Supplier IN (SELECT strid FROM dbo.fun_Cust_StrToTable(@SupplierIDs))
	AND  a.DescFlexField_PrivateDescSeg3 NOT IN('NEI01','OT01')
END 
--无邮箱供应商数据去重
SELECT DISTINCT a.Supplier
--,a.Email
--,'liufei@auctus.com' Email
,'chenll@auctus.cn;buyerpm01@auctus.cn;yangm@auctus.cn;hudz@auctus.cn;liufei@auctus.com;' Email
--,'491675469@qq.com'Email
--,'liufei@auctus.com' Email
,a.Purchaser
--,(SELECT c.DefaultEmail+';' FROM dbo.CBO_ItemMaster m 
--LEFT JOIN dbo.CBO_Operators op ON op.Code=m.DescFlexField_PrivateDescSeg23
--LEFT JOIN dbo.Base_Contact c ON op.Contact=c.ID
--WHERE m.Org=1001708020135665 AND m.Code=a.Code FOR XML PATH(''))CC
,DENSE_RANK()OVER(ORDER BY RN)OrderNo
FROM #tempSend a 
WHERE ISNULL(a.Email,'')=''
--供应商邮件推送信息
SELECT  
--s.Supplier,
a.Supplier,a.Purchaser
,a.Code,a.Name,a.SPECS,a.w0,a.w1,a.w2,a.w3,a.w4,a.w5,a.w6,a.w7,a.w8,a.Total
,a.Email
,(SELECT c.DefaultEmail+';' FROM dbo.CBO_ItemMaster m 
LEFT JOIN dbo.CBO_Operators op ON op.Code=m.DescFlexField_PrivateDescSeg23
LEFT JOIN dbo.Base_Contact c ON op.Contact=c.ID
WHERE m.Org=1001708020135665 AND m.Code=a.Code FOR XML PATH(''))CC 
--,'hudz@auctus.cn;liufei@auctus.com;' Email
--,'heqh@aucuts.cn;' Email
--,'liufei@auctus.com;' CC
,DENSE_RANK()OVER(ORDER BY RN)OrderNo
FROM #tempSend a 
INNER JOIN 
(SELECT t1.Name FROM (SELECT DISTINCT Supplier FROM #tempDeficiency WHERE IsPurchaseOrder=0)t INNER JOIN dbo.CBO_Supplier_Trl t1 ON t.Supplier=t1.ID)b ON a.Supplier=b.Name
WHERE ISNULL(a.Email,'')<>'' AND a.Supplier='东莞市国米电子科技有限公司' AND a.Code='334010085'
--WHERE ISNULL(a.Email,'')='111231231232131'
END 

END 
SELECT * FROM #tempDeficiency WHERE Code='334010085'
SELECT * FROM #tempW8 WHERE code='334010085'
