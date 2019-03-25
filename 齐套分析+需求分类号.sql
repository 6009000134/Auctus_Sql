--齐套分析报表，添加需求分类号追料逻辑
DECLARE @DocList VARCHAR(100)
DECLARE @Org BIGINT
DECLARE @StartDate DATETIME
DECLARE @EndDate DATETIME
DECLARE @Wh VARCHAR(100)
DECLARE @IsIncludeMo VARCHAR(100)
SET @StartDate='2016-07-01'
SET @EndDate='2018-12-01'
SET @Org=1001708020135665
--SET @DocList='WPO30180704001,MO-30180614486'
SET @DocList=''
SET @IsIncludeMo='1'
IF ISNULL(@IsIncludeMo,'')=''
SET @IsIncludeMo='0'
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
	 (
	 DocNo VARCHAR(50),--委外单
	 DocLineNo VARCHAR(50),	 
	 PickLineNo INT,--备料单行号
	 ProductID BIGINT,
	 DemandCode VARCHAR(50),
	 ItemMaster BIGINT,
	 Code VARCHAR(50),--备料
	 Name NVARCHAR(255),
	 IssuedQty DECIMAL(18,2),--已发数量
	 STDReqQty DECIMAL(18,2),
	 ActualReqQty DECIMAL(18,2),--实际需求数量
	 ReqQty DECIMAL(18,2),--实际需求数量-已发数量
	 ActualReqDate DATETIME,--实际需求日
	 RN INT
	 )
     END
     ELSE 
	 BEGIN
	 TRUNCATE TABLE #tempWP
     END
	 --库存量结果集
	 IF OBJECT_ID('tempdb.dbo.#tempWHQty',N'U') is NULL
	 BEGIN
	 CREATE TABLE #tempWHQty
	 (
	 Code VARCHAR(50),
	 StoreQty DECIMAL(18,2)--仓库库存量
	 )
     END
     ELSE 
	 BEGIN
	 TRUNCATE TABLE #tempWHQty
     END
--委外备料单
--取已审核的采购单，300组织、交期时间
DECLARE @sql NVARCHAR(4000),@sql2 NVARCHAR(4000),@sql3 NVARCHAR(4000)
SET @sql='INSERT INTO #tempWP select *,ROW_NUMBER()OVER(ORDER BY t.ActualReqDate,t.DocNo,t.ItemInfo_ItemCode)RN from ( '
SET @sql=@sql+ '
SELECT a.DocNo,b.DocLineNo,d.PickLineNo,b.ItemInfo_ItemID ProductID,b.demondcode
,d.ItemInfo_ItemID Item,d.ItemInfo_ItemCode,d.ItemInfo_ItemName
,d.IssuedQty--已发放数量  
,d.STDReqQty--标准用量
,d.ActualReqQty--实际需求数量	
,d.ActualReqQty-d.IssuedQty ReqQty--
,d.ActualReqDate--实际需求日
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
WHERE a.Status in(0,1,2) and b.Status in (0,1,2) AND a.Org=@Org AND d.ActualReqDate BETWEEN @StartDate AND @EndDate
and  exists  (select 1 from PM_POShipLine b1  where e.ID=b1.ID   )
and d.IssueStyle<>2
--and d.IssuedQty<d.ActualReqQty
AND c.ID IS NOT NULL '
IF ISNULL(@DocList,'')<>''
BEGIN
SET @sql=@sql +' AND a.DocNo IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@DocList)) '
END
IF ISNULL(@IsIncludeMo,'')='1'
BEGIN 
SET @sql=@sql+' union all '
SET @sql=@sql+' SELECT a.DocNo,0,b.DocLineNO,a.ItemMaster ProductID,a.DemandCode,b.ItemMaster,c.Code,c.Name,b.IssuedQty,b.STDReqQty,b.ActualReqQty,b.ActualReqQty-b.IssuedQty ReqQty
,b.ActualReqDate
FROM dbo.MO_MO a LEFT JOIN dbo.MO_MOPickList b ON a.ID=b.MO
LEFT JOIN dbo.CBO_ItemMaster c ON b.ItemMaster=c.ID
WHERE a.DocState<>3--非完工订单
AND a.Cancel_Canceled=0 --非作废订单
AND b.ActualReqDate BETWEEN @StartDate AND @EndDate 
and b.ActualReqQty>0
--and b.IssuedQty<b.ActualReqQty
and b.IssueStyle<>4
and a.Org=@Org '
END 
IF ISNULL(@DocList,'')<>''
BEGIN
SET @sql=@sql +' AND a.DocNo IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@DocList)) '
END
SET @sql=@sql+' ) t'

EXEC sp_executesql @sql,N'@Org bigint,@StartDate datetime,@EndDate datetime,@DocList varchar(max)',@Org,@StartDate,@EndDate,@DocList 

--取有效仓库的库存量、普通仓、
--库存
SET @sql2='INSERT INTO #tempWHQty
SELECT a.ItemInfo_ItemCode,SUM(a.StoreQty)StoreQty FROM dbo.InvTrans_WhQoh a LEFT JOIN dbo.CBO_Wh b ON a.Wh=b.ID
WHERE b.Org=@Org AND b.LocationType=0--普通仓
AND b.Effective_IsEffective=1
AND a.StorageType  not  in (5,1,2,0,3,7) --0、1、2、3、5、7 待检、在检、不合格、报废、冻结、待返工
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
WHERE b.Code IS null

DECLARE @DocNo VARCHAR(50),@PickLineNo INT,@Code VARCHAR(50),@ReqQty decimal(18,2),@StoreQty DECIMAL(18,2)
DECLARE whCursor CURSOR
FOR 
SELECT DocNo,PickLineNo,Code,ReqQty FROM #tempWP ORDER BY RN
OPEN whCursor
FETCH NEXT FROM whCursor INTO @DocNo,@PickLineNo,@Code,@ReqQty
WHILE @@FETCH_STATUS=0
BEGIN--While
SELECT @StoreQty=StoreQty FROM #tempWHQty WHERE Code=@Code
IF @StoreQty>=0
--SELECT * FROM #tempWHQty WHERE code='335030045'
BEGIN
	IF @StoreQty-@ReqQty>=0 
	BEGIN
	INSERT INTO #tempResult
        ( DocNo ,PickLineNo ,Code ,ReqQty,LackAmount,IsLack,WhAvailiableAmount)
	VALUES  (    @DocNo,@PickLineNo,@Code,@ReqQty,0,'齐套',@StoreQty-@ReqQty )
	END--End If
	ELSE 
	BEGIN
		INSERT INTO #tempResult
        ( DocNo ,PickLineNo ,Code ,ReqQty,LackAmount,IsLack,WhAvailiableAmount)
	VALUES  (    @DocNo,@PickLineNo,@Code,@ReqQty,@StoreQty-@ReqQty,'缺料',@StoreQty-@ReqQty )
	END --End Else
END 
ELSE
BEGIN
	INSERT INTO #tempResult
        ( DocNo ,PickLineNo ,Code ,ReqQty,LackAmount,IsLack,WhAvailiableAmount)
	VALUES  (    @DocNo,@PickLineNo,@Code,@ReqQty,0-@ReqQty,'缺料',@StoreQty-@ReqQty )
END
UPDATE #tempWHQty SET StoreQty=@StoreQty-@ReqQty WHERE Code=@Code
FETCH NEXT FROM whCursor INTO @DocNo,@PickLineNo,@Code,@ReqQty
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
FROM (SELECT DISTINCT docno,DocLineNo,ProductID,DemandCode FROM #tempWP WHERE DemandCode<>-1) a LEFT JOIN dbo.MO_MO b ON a.DocNo=b.DocNo LEFT JOIN dbo.PM_PurchaseOrder c ON a.DocNo=c.DocNo LEFT JOIN dbo.PM_POLine d
ON c.ID=d.PurchaseOrder AND a.DocLineNo=d.DocLineNo
LEFT JOIN dbo.CBO_ItemMaster e ON b.ItemMaster=e.ID

--SELECT * FROM #tempWP
--PR结果集
IF OBJECT_ID(N'tempdb.dbo.#tempPR',N'U') IS NULL
CREATE TABLE #tempPR(Company nvarchar(20),PRCode varchar(12),PRName nvarchar(255),PRDemandCode varchar(8),PRApprovedQty decimal(18,0),PRList varchar(1000),PRFlag VARCHAR(10))
ELSE 
TRUNCATE TABLE #tempPR

--PO结果集
IF OBJECT_ID(N'tempdb.dbo.#tempPO',N'U') IS NULL
CREATE TABLE #tempPO(POCode varchar(12),POName nvarchar(255),PODemandCode varchar(8),POReqQtyTU decimal(18,0),POList varchar(2000))
ELSE 
TRUNCATE TABLE #tempPO

--RCV结果集
IF OBJECT_ID(N'tempdb.dbo.#tempRCV',N'U') IS NULL
CREATE TABLE #tempRCV(RCVCode varchar(12),RCVDemandCode varchar(8),POReqQtyTU DECIMAL(18,0),ArriveQtyTU DECIMAL(18,0),RcvQtyTU decimal(18,0),RCVList varchar(2000))
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
FROM dbo.PR_PR a INNER JOIN dbo.PR_PRLine b ON a.ID=b.PR  
LEFT JOIN dbo.PM_POShipLine c ON c.DemondCode=b.DemandCode AND c.SrcDocInfo_SrcDocNo=a.DocNo AND  c.SrcDocInfo_SrcDocLineNo=b.DocLineNo   
LEFT JOIN dbo.PM_POLine d ON c.POLine=d.ID LEFT JOIN dbo.PM_PurchaseOrder e ON d.PurchaseOrder=e.ID
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
WHERE ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
AND b.DemandCode IN (SELECT DISTINCT demandcode FROM #tempDoc) 
--AND b.DemandCode<>-1
AND b.status IN (0,1,2)
AND c.ID IS NULL--PR未转PO
AND a.Org=1001708020135665
)
INSERT INTO #tempPR
SELECT a.Company,a.ItemInfo_ItemCode,a.ItemInfo_ItemName,a.DemandCode,SUM(a.ApprovedQtyTU)ApprovedQty
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
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder LEFT JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE b.Status IN(0,1,2)
AND c.DemondCode IN (SELECT DISTINCT DemandCode FROM #tempDoc)
--AND c.DemondCode<>-1
AND a.Org=1001708020135665
--AND a.DocNo LIKE 'WPO%'
AND NOT EXISTS(SELECT DISTINCT a1.docno,a1.DocLineNo FROM #tempWP a1 WHERE a1.DocNo LIKE 'WPO%' AND a1.DocNo=a.DocNo AND a1.DocLineNo=b.DocLineNo)
)
INSERT INTO #tempPO
SELECT a.ItemInfo_ItemCode,a.ItemInfo_ItemName,a.PO_DemandCode,SUM(a.ReqQtyTU)ReqQtyTU
,(SELECT b.PoNo+'-'+CONVERT(VARCHAR(10),b.PoLineNo)+'-'+CONVERT(VARCHAR(10),b.PoSubLineNo) FROM PO2 b WHERE b.PO_DemandCode=a.PO_DemandCode AND b.ItemInfo_ItemCode=a.ItemInfo_ItemCode  FOR XML PATH('')) POList 
FROM PO2 a
GROUP BY a.PO_DemandCode,a.ItemInfo_ItemCode,a.ItemInfo_ItemName



;
WITH RCV2 AS 
(
SELECT a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo ,b.ArriveQtyTU,b.RcvQtyTU
,c.POReqQtyTU,c.POCode,c.PODemandCode,c.POList
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement 
INNER JOIN #tempPO c ON PATINDEX('%'+b.SrcDoc_SrcDocNo+'-'+CONVERT(VARCHAR(20),b.SrcDoc_SrcDocLineNo)+'-'+CONVERT(VARCHAR(20),b.SrcDoc_SrcDocSubLineNo)+'%',c.POList)>0 AND b.ItemInfo_ItemCode=c.POCode
WHERE a.Org=1001708020135665
--WHERE b.SrcDoc_SrcDocNo+'-'+CONVERT(VARCHAR(20),b.SrcDoc_SrcDocLineNo)+'-'+CONVERT(VARCHAR(20),b.SrcDoc_SrcDocSubLineNo) 
)
INSERT INTO #tempRCV
SELECT a.POCode,a.PODemandCode,MIN(a.POReqQtyTU)POReqQtyTU,SUM(a.ArriveQtyTU)ArriveQtyTU,SUM(a.RcvQtyTU)RcvQtyTU
,(SELECT b.DocNo+'-'+CONVERT(VARCHAR(5),b.DocLineNo) FROM RCV2 b WHERE b.PODemandCode=a.PODemandCode AND b.POCode=a.POCode FOR XML PATH(''))RCVList
FROM RCV2 a
--WHERE SUM(RcvQtyTU)<MIN(a.POReqQtyTU)
GROUP BY a.POCode,a.PODemandCode
ORDER BY a.PODemandCode,a.POCode

--SELECT b.Code ProductCode,b.Name ProductName,a.DocNo,a.PickLineNo,a.Code,a.Name,a.IssuedQty,a.ActualReqQty,a.ActualReqDate 
--,c.PRList,c.PRApprovedQty,d.POList,d.POReqQtyTU,e.RCVList,e.ArriveQtyTU,e.RcvQtyTU
--FROM #tempWP a INNER JOIN dbo.CBO_ItemMaster b ON a.ProductID=b.ID
--LEFT JOIN #tempPR c ON a.DemandCode=c.PRDemandCode AND a.Code=c.PRCode 
--LEFT JOIN  #tempPO d ON a.DemandCode=d.PODemandCode AND a.Code=d.POCode
--LEFT JOIN #tempRCV e ON a.DemandCode=e.RCVDemandCode AND a.Code=e.RCVCode
--WHERE c.PRCode IS NOT NULL OR d.POList IS NOT NULL OR e.RCVCode IS NOT NULL
--ORDER BY a.DemandCode,a.Code

SELECT a.*,b.LackAmount,(select Code from UBF_Sys_ExtEnumValue where  ExtEnumType=1001101157664810 AND EValue=a.DemandCode)需求分类号,b.IsLack,b.WhAvailiableAmount
,c.PRList,c.PRApprovedQty,c.PRFlag,d.POList,d.POReqQtyTU,e.RCVList,e.ArriveQtyTU,e.RcvQtyTU,CASE WHEN ISNULL(e.RcvQtyTU,0)=0 THEN '' ELSE '收货数量<采购数量' END RcvFlag
FROM #tempWP a INNER JOIN #tempResult b ON a.DocNo=b.DocNo AND a.PickLineNo=b.PickLineNo 
LEFT JOIN #tempPR c ON a.DemandCode=c.PRDemandCode AND a.Code=c.PRCode 
LEFT JOIN  #tempPO d ON a.DemandCode=d.PODemandCode AND a.Code=d.POCode
LEFT JOIN #tempRCV e ON a.DemandCode=e.RCVDemandCode AND a.Code=e.RCVCode
WHERE c.PRCode IS NOT NULL OR d.POList IS NOT NULL OR e.RCVCode IS NOT NULL
ORDER BY a.RN,a.DocNo,a.PickLineNo

