--EXEC dbo.sp_Auctus_AllSetCheckByMes @Org = 1001708020135665, -- bigint
--    @DocList = '', -- varchar(max)
--    @DemandList = '', -- varchar(max)
--    @Wh = ''
	
	
alter PROC [dbo].[sp_Auctus_AllSetCheckByMes]
(
@Org BIGINT,
@DocList VARCHAR(max),
@DemandList VARCHAR(MAX),
@Wh VARCHAR(200)
)
AS
BEGIN 

--齐套分析报表，添加需求分类号追料逻辑
--DECLARE @Org BIGINT
--DECLARE @DocList VARCHAR(100)
--DECLARE @DemandList VARCHAR(50)=''
--DECLARE @Wh VARCHAR(100)
--DECLARE @EndDate DATE
--DECLARE @IsIncludeWPO VARCHAR(10)--是否包含WPO
--DECLARE @IsIncludeMo VARCHAR(10)--是否包含MO
--DECLARE @IsWMOOnly VARCHAR(10)--MO是否直选WMO
--DECLARE @Date DATETIME
--SET @Date=GETDATE()
--SET @EndDate=DATEADD(DAY,3,@Date)
--SET @Org=1001708020135665
----SET @Wh='101,102'
--SET @DocList=''

 --料品扩展字段的值集
 IF object_id('tempdb.dbo.#tempDefineValue') is NULL
 CREATE TABLE #tempDefineValue(Code VARCHAR(50),Name NVARCHAR(255),Type VARCHAR(50))
 ELSE
 TRUNCATE TABLE #tempDefineValue
 --MRP分类值集
 INSERT INTO #tempDefineValue
         ( Code, Name, Type )
SELECT T.Code,T.Name,'MRPCategory' FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='MRPCategory') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T WHERE T.rownum>  0 and T.rownum<= 130
   --产品系列ProductLine值集
 INSERT INTO #tempDefineValue
         ( Code, Name, Type )
SELECT T.Code,T.Name,'ProductLine' FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='ProductLine') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T WHERE T.rownum>  0 and T.rownum<= 130



IF OBJECT_ID(N'tempdb.dbo.#tempMes',N'U') is NULL
	 BEGIN
	 CREATE TABLE #tempMes
	 (
	 WorkOrder VARCHAR(50),
	 TotalPlanCount INT
	 )
     END
     ELSE 
	 BEGIN
	 TRUNCATE TABLE #tempMes
     END

 IF OBJECT_ID(N'tempdb.dbo.#tempResult',N'U') is NULL
	 BEGIN
	 CREATE TABLE #tempResult
	 (
	 DocNo VARCHAR(50),
	 DocLineNo INT,
	 PickLineNo INT,
	 ItemMaster BIGINT,
	 Code VARCHAR(50),
	 Name NVARCHAR(255),
	 IssuedQty DECIMAL(18,2),
	 STDReqQty DECIMAL(18,2),
	 ActualReqQty DECIMAL(18,2),
	 ReqQty DECIMAL(18,2),
	 ActualReqDate DATETIME,--实际需求日
	 LackAmount INT,
	 IsLack VARCHAR(4),
	 WhAvailiableAmount INT--库存可用量
	 )
     END
     ELSE 
	 BEGIN
	 TRUNCATE TABLE #tempResult
     END
	 --备料单结果集
	 
	 IF object_id('tempdb.dbo.#tempWP',N'U') is NULL
	 BEGIN
	 CREATE TABLE #tempWP
	 (	 DocNo VARCHAR(50),--委外单
	 DocLineNo VARCHAR(50),	 
	 PickLineNo INT,--备料单行号
	 DocType NVARCHAR(20),
	 ProductID BIGINT,
	 ProductCode VARCHAR(50),
	 ProductName NVARCHAR(255),
	 ProductSPECS NVARCHAR(300),
	 ProductQty DECIMAL(18,0),
	 U9ProductQty DECIMAL(18,0),
	 DemandCode VARCHAR(50),
	 ItemMaster BIGINT,
	 Code VARCHAR(50),--备料
	 Name NVARCHAR(255),
	 SPEC NVARCHAR(600),     
	 IssuedQty DECIMAL(18,2),--已发数量
	 STDReqQty DECIMAL(18,2),
	 ActualReqQty DECIMAL(18,2),--实际需求数量
	 ReqQty DECIMAL(18,2),--实际需求数量-已发数量
	 ActualReqDate DATETIME,--实际需求日
	 RN INT	 )
     END
     ELSE 
	 BEGIN
	 TRUNCATE TABLE #tempWP
     END
	 --库存量结果集
	 IF OBJECT_ID('tempdb.dbo.#tempWHQty',N'U') is NULL
	 BEGIN
	 CREATE TABLE #tempWHQty
	 (	 Code VARCHAR(50),
	 StoreQty DECIMAL(18,2)--仓库库存量
	 	 )
     END
     ELSE 
	 BEGIN
	 TRUNCATE TABLE #tempWHQty
     END

	 --Mes排产工单集合
	 INSERT INTO #tempMes
	         ( WorkOrder, TotalPlanCount )
	 SELECT 
a.WorkOrder,SUM(a.PlanCount)TotalPlanCount
FROM MESDATA.au_mes.dbo.mxqh_MoPlanCount a
WHERE a.PlanDate<DATEADD(DAY,2,GETDATE())
GROUP BY a.WorkOrder
--委外备料单
--取已审核的采购单，300组织、交期时间
DECLARE @sql NVARCHAR(4000),@sql2 NVARCHAR(4000),@sql3 NVARCHAR(4000)
SET @sql='INSERT INTO #tempWP select *,ROW_NUMBER()OVER(ORDER BY t.ActualReqDate,t.DocNo,t.ItemInfo_ItemCode)RN from ( '


SET @sql=@sql+' SELECT a.DocNo,0 DocLineNo,b.DocLineNo PickLineNo,dt1.Name DocType,a.ItemMaster ProductID
,d.Code ProductCode,d.Name ProductName,d.SPECS ProductSPECS,mes.TotalPlanCount ProductQty,a.ProductQty U9ProductQty
,a.DemandCode,b.ItemMaster,c.Code ItemInfo_ItemCode,c.Name ItemInfo_ItemName,c.SPECS
,b.IssuedQty,b.STDReqQty,b.ActualReqQty*CONVERT(DECIMAL(18,2),mes.TotalPlanCount)/CONVERT(DECIMAL(18,2),a.ProductQty) ActualReqQty
,b.ActualReqQty*CONVERT(DECIMAL(18,2),mes.TotalPlanCount)/CONVERT(DECIMAL(18,2),a.ProductQty)-b.IssuedQty ReqQty
,a.StartDate ActualReqDate
FROM dbo.MO_MO a INNER JOIN #tempMes mes ON a.DocNo=mes.WorkOrder
LEFT JOIN dbo.MO_MOPickList b ON a.ID=b.MO
LEFT JOIN dbo.CBO_ItemMaster c ON b.ItemMaster=c.ID
Left Join CBO_ItemMaster d on a.ItemMaster=d.ID
LEFT JOIN dbo.MO_MODocType dt ON a.MODocType=dt.ID LEFT JOIN dbo.MO_MODocType_Trl dt1 ON dt.ID=dt1.ID AND ISNULL(dt1.SysMLFlag,''zh-cn'')=''zh-cn''
LEFT JOIN dbo.CBO_MrpInfo mrp ON  c.ID=mrp.ItemMaster
WHERE a.DocState<>3--非完工订单
AND a.Cancel_Canceled=0 --非作废订单
AND a.IsHoldRelease=0--非挂起
and b.ActualReqQty>0
and c.DescFlexField_PrivateDescSeg17 in (''10'','''')--是否齐套考核
--and b.IssuedQty<b.ActualReqQty
and b.IssueStyle<>4
and a.Org=@Org ) t'



EXEC sp_executesql @sql,N'@Org bigint,@DocList varchar(max)',@Org,@DocList 

--取有效仓库的库存量、普通仓、存储类型：可MRP
--库存 
---库存考虑备品仓“203” ADD BY DANIEL  2018-12-31  
--按需对物料齐套考核报表、邮件推送功能不考虑“来料不良品仓”代码126 2019-5-6
SET @sql2='INSERT INTO #tempWHQty
SELECT a.ItemInfo_ItemCode,SUM(a.StoreQty)StoreQty FROM dbo.InvTrans_WhQoh a LEFT JOIN dbo.CBO_Wh b ON a.Wh=b.ID
LEFT JOIN dbo.CBO_WhStorageType c ON a.StorageType=c.StorageType AND a.Wh=c.Warehouse
WHERE b.Org=@Org AND b.LocationType=0--普通仓
AND b.Effective_IsEffective=1
AND (c.IsCanMRP=1 or  b.code=''231'') 
and b.code<>''125''  
and b.code<>''126''
AND a.ItemInfo_ItemCode IN (SELECT DISTINCT  Code FROM #tempWP)'
IF ISNULL(@Wh,'')<>''
BEGIN 
SET @sql2=@sql2+' AND b.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Wh))  ' 
END 
SET @sql2=@sql2 +' Group By a.ItemInfo_ItemCode '
EXEC sp_executesql @sql2,N'@Org bigint,@Wh varchar(100)',@Org,@Wh
--若备料单中物料在仓库中没有记录，则补齐记录
INSERT INTO #tempWHQty
SELECT DISTINCT a.Code,ISNULL(b.StoreQty,0)StoreQty FROM #tempWP a LEFT JOIN #tempWHQty b ON a.Code=b.Code
WHERE b.Code IS NULL


DECLARE @DocNo VARCHAR(50),@DocLineNo INT,@PickLineNo INT,@Code VARCHAR(50),@ReqQty decimal(18,2),@StoreQty DECIMAL(18,2)
DECLARE whCursor CURSOR
FOR 
SELECT DocNo,DocLineNo,PickLineNo,Code,ReqQty FROM #tempWP ORDER BY RN
OPEN whCursor
FETCH NEXT FROM whCursor INTO @DocNo,@DocLineNo,@PickLineNo,@Code,@ReqQty
WHILE @@FETCH_STATUS=0
BEGIN--While
SELECT @StoreQty=StoreQty FROM #tempWHQty WHERE Code=@Code
IF ISNULL(@ReqQty,0)=0--料已发齐，不缺料
BEGIN
INSERT INTO #tempResult
        ( DocNo,DocLineNo ,PickLineNo ,Code ,ReqQty,LackAmount,IsLack,WhAvailiableAmount)
	VALUES  (    @DocNo,@DocLineNo,@PickLineNo,@Code,@ReqQty,0,'齐套',@StoreQty )
END
ELSE 
BEGIN--料未发齐
IF @StoreQty>=0
--SELECT * FROM #tempWHQty WHERE code='335030045'
BEGIN
	IF @StoreQty-@ReqQty>=0 
	BEGIN
	INSERT INTO #tempResult
        ( DocNo,DocLineNo ,PickLineNo ,Code ,ReqQty,LackAmount,IsLack,WhAvailiableAmount)
	VALUES  (    @DocNo,@DocLineNo,@PickLineNo,@Code,@ReqQty,0,'齐套',@StoreQty-@ReqQty )
	END--End If
	ELSE 
	BEGIN
		INSERT INTO #tempResult
        ( DocNo,DocLineNo ,PickLineNo ,Code ,ReqQty,LackAmount,IsLack,WhAvailiableAmount)
	VALUES  (    @DocNo,@DocLineNo,@PickLineNo,@Code,@ReqQty,@StoreQty-@ReqQty,'缺料',@StoreQty-@ReqQty )
	END --End Else
END 
ELSE
BEGIN
	INSERT INTO #tempResult
        ( DocNo,DocLineNo ,PickLineNo ,Code ,ReqQty,LackAmount,IsLack,WhAvailiableAmount)
	VALUES  (    @DocNo,@DocLineNo,@PickLineNo,@Code,@ReqQty,0-@ReqQty,'缺料',@StoreQty-@ReqQty )
END
UPDATE #tempWHQty SET StoreQty=@StoreQty-@ReqQty WHERE Code=@Code
END --End 料未发齐
FETCH NEXT FROM whCursor INTO @DocNo,@DocLineNo,@PickLineNo,@Code,@ReqQty
END--End While
CLOSE whCursor
DEALLOCATE whCursor
--SELECT a.*,b.LackAmount,b.IsLack,b.WhAvailiableAmount,c.SPECS
--FROM #tempWP a INNER JOIN #tempResult b ON a.DocNo=b.DocNo AND a.PickLineNo=b.PickLineNo 
--LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID
--ORDER BY a.RN,a.DocNo,a.PickLineNo

DECLARE @Org2 BIGINT
SELECT @Org2=ID FROM dbo.Base_Organization WHERE code='300'


--58 450
--SELECT DISTINCT DocNo FROM #tempWP WHERE DocNo LIKE 'WPO%'
IF OBJECT_ID(N'tempdb.dbo.#tempDoc',N'U') IS NULL 
CREATE TABLE #tempDoc
(
DocNo VARCHAR(50),
DemandCode VARCHAR(50),
ItemMaster BIGINT,
ProductCode VARCHAR(50),
ProductName NVARCHAR(255)
)
ELSE 
TRUNCATE TABLE #tempDoc

INSERT INTO #tempDoc
SELECT a.DocNo,a.DemandCode,a.ProductID,ISNULL(e.Code,d.ItemInfo_ItemCode)Code,ISNULL(e.Name,d.ItemInfo_ItemName)Name 
FROM (SELECT DISTINCT docno,DocLineNo,ProductID,DemandCode FROM #tempWP WHERE DemandCode<>-1) a LEFT JOIN dbo.MO_MO b ON a.DocNo=b.DocNo 
LEFT JOIN dbo.PM_PurchaseOrder c ON a.DocNo=c.DocNo LEFT JOIN dbo.PM_POLine d ON c.ID=d.PurchaseOrder AND a.DocLineNo=d.DocLineNo
LEFT JOIN dbo.CBO_ItemMaster e ON b.ItemMaster=e.ID

--SELECT * FROM #tempWP
--PR结果集
IF OBJECT_ID(N'tempdb.dbo.#tempPR',N'U') IS NULL
CREATE TABLE #tempPR(Company nvarchar(20),PRCode varchar(12),PRName nvarchar(255),PRDemandCode varchar(8),PRApprovedQty decimal(18,0),PRList varchar(MAX),PRFlag VARCHAR(10))
ELSE 
TRUNCATE TABLE #tempPR

--PO结果集
IF OBJECT_ID(N'tempdb.dbo.#tempPO',N'U') IS NULL
CREATE TABLE #tempPO(POCode varchar(12),POName nvarchar(255),PODemandCode varchar(8),POReqQtyTU decimal(18,0),POList varchar(MAX))
ELSE 
TRUNCATE TABLE #tempPO

--RCV结果集
IF OBJECT_ID(N'tempdb.dbo.#tempRCV',N'U') IS NULL
CREATE TABLE #tempRCV(RCVCode varchar(12),RCVDemandCode varchar(8),POReqQtyTU DECIMAL(18,0),POList VARCHAR(MAX),ArriveQtyTU DECIMAL(18,0),RcvQtyTU decimal(18,0),RCVList varchar(MAX))
ELSE 
TRUNCATE TABLE #tempRCV


--PR未转PO单据
;
WITH PR AS
(
SELECT o1.Name Company,a.DocNo PrNo,b.DocLineNo PrDocLineNo,b.DemandCode,b.ItemInfo_ItemName,b.ItemInfo_ItemCode,b.ApprovedQtyTU
,c.ReqQtyTU,b.ID,c.ID cid,c.DemondCode,e.DocNo PONo,d.DocLineNo PoLineNo,c.ItemInfo_ItemCode code2
,c.SrcDocInfo_SrcDocNo c1,c.SrcDocInfo_SrcDocLineNo n2,c.SrcDocInfo_SrcDocSubLineNo s2
,CASE WHEN ISNULL(c.ReqQtyTU,0)=0 THEN '未转PO' ELSE '1' END  flag
FROM dbo.PR_PR a INNER JOIN dbo.PR_PRLine b ON a.ID=b.PR  INNER JOIN dbo.CBO_MrpInfo m ON b.ItemInfo_ItemID=m.ItemMaster
LEFT JOIN dbo.PM_POShipLine c ON c.DemondCode=b.DemandCode AND c.SrcDocInfo_SrcDocNo=a.DocNo AND  c.SrcDocInfo_SrcDocLineNo=b.DocLineNo   
LEFT JOIN dbo.PM_POLine d ON c.POLine=d.ID LEFT JOIN dbo.PM_PurchaseOrder e ON d.PurchaseOrder=e.ID
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
WHERE ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
AND b.DemandCode IN (SELECT DISTINCT demandcode FROM #tempDoc) 
--AND b.DemandCode<>-1
AND b.status IN (0,1,2)
AND c.ID IS NULL--PR未转PO
AND m.DemandRule=0
AND a.Org=1001708020135665
)
INSERT INTO #tempPR
SELECT a.Company,a.ItemInfo_ItemCode,a.ItemInfo_ItemName,a.DemandCode,SUM(ISNULL(a.ApprovedQtyTU,0))ApprovedQty
,(SELECT b.prno+'-'+CONVERT(VARCHAR(50),b.PrDocLineNo)+',' FROM PR b WHERE b.DemandCode=a.demandcode AND b.ItemInfo_ItemCode=a.ItemInfo_ItemCode FOR XML PATH(''))
,'未转PO' PRFlag
FROM PR a
GROUP BY a.Company,a.ItemInfo_ItemCode,a.ItemInfo_ItemName,a.DemandCode
--ORDER BY a.DemandCode

--PO单据按料号、需求分类号汇总
;
WITH PO2 AS
(
SELECT a.DocNo PoNo,b.DocLineNo PoLineNo,c.SubLineNo PoSubLineNo,c.DemondCode PO_DemandCode,c.ReqQtyTU
,c.ItemInfo_ItemCode,c.ItemInfo_ItemName ,c.SrcDocInfo_SrcDocNo,c.SrcDocInfo_SrcDocLineNo
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
INNER JOIN dbo.CBO_MrpInfo m ON c.ItemInfo_ItemID=m.ItemMaster
WHERE b.Status IN(0,1,2)
AND c.DemondCode IN (SELECT DISTINCT DemandCode FROM #tempDoc)
--AND c.DemondCode<>-1
AND a.Org=1001708020135665
AND m.DemandRule=0
--AND a.DocNo LIKE 'WPO%'
AND NOT EXISTS(SELECT DISTINCT a1.docno,a1.DocLineNo FROM #tempWP a1 WHERE a1.DocNo LIKE 'WPO%' AND a1.DocNo=a.DocNo AND a1.DocLineNo=b.DocLineNo)
)
INSERT INTO #tempPO
SELECT a.ItemInfo_ItemCode,a.ItemInfo_ItemName,a.PO_DemandCode,SUM(ISNULL(a.ReqQtyTU,0))ReqQtyTU
,(SELECT b.PoNo+'-'+CONVERT(VARCHAR(10),b.PoLineNo)+'-'+CONVERT(VARCHAR(10),b.PoSubLineNo) FROM PO2 b WHERE b.PO_DemandCode=a.PO_DemandCode AND b.ItemInfo_ItemCode=a.ItemInfo_ItemCode  FOR XML PATH('')) POList 
FROM PO2 a
GROUP BY a.PO_DemandCode,a.ItemInfo_ItemCode,a.ItemInfo_ItemName




--采购单收货情况
;
WITH RCV AS
(
SELECT a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo ,b.ArriveQtyTU,b.RcvQtyTU
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement  INNER JOIN dbo.CBO_MrpInfo m ON b.ItemInfo_ItemID=m.ItemMaster
WHERE a.Org=1001708020135665
AND m.DemandRule=0
),
PO3 AS
(
SELECT * FROM #tempPO a LEFT JOIN RCV b ON PATINDEX('%'+b.SrcDoc_SrcDocNo+'-'+CONVERT(VARCHAR(20),b.SrcDoc_SrcDocLineNo)+'-'+CONVERT(VARCHAR(20),b.SrcDoc_SrcDocSubLineNo)+'%',a.POList)>0 AND b.ItemInfo_ItemCode=a.POCode
)
INSERT INTO #tempRCV
SELECT a.POCode,a.PODemandCode,MIN(a.POReqQtyTU)POReqQtyTU,MIN(a.POList)POList,SUM(ISNULL(a.ArriveQtyTU,0))ArriveQtyTU,SUM(ISNULL(a.RcvQtyTU,0))RcvQtyTU
,(SELECT b.DocNo+'-'+CONVERT(VARCHAR(5),b.DocLineNo) FROM PO3 b WHERE b.PODemandCode=a.PODemandCode AND b.POCode=a.POCode FOR XML PATH(''))RCVList FROM PO3 a
--WHERE SUM(RcvQtyTU)<MIN(a.POReqQtyTU)
GROUP BY a.POCode,a.PODemandCode
HAVING SUM(ISNULL(a.RcvQtyTU,0))<MIN(a.POReqQtyTU)
ORDER BY a.PODemandCode,a.POCode

--结果集
SELECT a.DocNo,a.DocLineNo,a.PickLineNo,a.DocType,a.ProductID,a.ProductCode,a.ProductName,a.ProductSPECS,a.ProductQty,a.U9ProductQty
,a.DemandCode,a.ItemMaster,m.Code,m.Name,m.SPECS SPEC,ISNULL(m2.SafetyStockQty,0)SafetyStockQty
,a.IssuedQty,a.STDReqQty,a.ActualReqQty,a.ReqQty,CONVERT(DATE,a.ActualReqDate)ActualReqDate,a.RN
,ISNULL((select Code from UBF_Sys_ExtEnumValue where  ExtEnumType=1001101157664810 AND EValue=a.DemandCode),'安全库存')需求分类号,b.LackAmount,b.IsLack,b.WhAvailiableAmount
,c.PRList,c.PRApprovedQty,c.PRFlag,e.POList,e.POReqQtyTU,e.RCVList,e.ArriveQtyTU,e.RcvQtyTU,CASE WHEN ISNULL(e.RcvQtyTU,0)=0 THEN '' ELSE '收货数量<采购数量' END RcvFlag
,b.IsLack+CASE WHEN ISNULL(c.PRList,'')<>'' THEN '_'+c.PRFlag
WHEN ISNULL(e.POList,'')<>'' AND ISNULL(e.RCVList,'')<>'' THEN '_'+'收货数量<采购数量'
WHEN ISNULL(e.POList,'')<>'' AND ISNULL(e.RCVList,'')='' THEN '_'+'PO未收货'
ELSE '' END ResultFlag
,m.DescFlexField_PrivateDescSeg19 客户产品名称,m.DescFlexField_PrivateDescSeg20 项目编码
,m.DescFlexField_PrivateDescSeg21 项目代号
,m.DescFlexField_PrivateDescSeg23 执行采购员--执行采购员编码
,m1.Code MRPCode--MRP分类编码
,m1.Name MRPCategory--MRP分类
,op1.Name Buyer--执行采购员
,m.DescFlexField_PrivateDescSeg24 MCCode--MC负责人编码
,op21.Name MCName--MC负责人
,mrp.FixedLT--固定提前期
,ISNULL(pl.Name,'')ProductLine--产品系列
FROM #tempWP a INNER JOIN #tempResult b ON a.DocNo=b.DocNo AND ISNULL(a.DocLineNo,0)=ISNULL(b.DocLineNo,0) AND a.PickLineNo=b.PickLineNo 
LEFT JOIN #tempPR c ON a.DemandCode=c.PRDemandCode AND a.Code=c.PRCode 
LEFT JOIN #tempRCV e ON a.DemandCode=e.RCVDemandCode AND a.Code=e.RCVCode
LEFT JOIN dbo.CBO_ItemMaster m ON a.ItemMaster=m.ID 
LEFT JOIN #tempDefineValue m1 ON m.DescFlexField_PrivateDescSeg22=m1.Code AND m1.Type='MRPCategory'
LEFT JOIN dbo.CBO_InventoryInfo m2 ON a.ItemMaster=m2.ItemMaster
LEFT JOIN dbo.CBO_Operators op ON m.DescFlexField_PrivateDescSeg23=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON m.DescFlexField_PrivateDescSeg24=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.ID AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_MrpInfo mrp ON m.ID=mrp.ItemMaster
LEFT JOIN dbo.CBO_ItemMaster plm ON a.ProductID=plm.ID
LEFT JOIN #tempDefineValue pl ON plm.DescFlexField_PrivateDescSeg27=pl.Code AND pl.Type='ProductLine'
--LEFT JOIN dbo.CBO_ItemMaster f ON a.ItemMaster=f.ID
--WHERE c.PRCode IS NOT NULL OR e.POList IS NOT NULL OR e.RCVCode IS NOT NULL OR b.IsLack='缺料'
ORDER BY a.RN,a.DocNo,a.PickLineNo


END 
