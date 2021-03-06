USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_WPSetCheck]    Script Date: 2018/8/14 10:15:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--2018.7.13
--委外齐套分析
ALTER PROC [dbo].[sp_Auctus_WPSetCheck]
(
@Org BIGINT,
@DocList VARCHAR(max),
@StartDate DATETIME,
@EndDate DATETIME,
@Wh VARCHAR(100)
)
AS
BEGIN
--DECLARE @DocList VARCHAR(100)
--DECLARE @Org BIGINT
--DECLARE @StartDate datetime
--DECLARE @EndDate Datetime
--DECLARE @Wh VARCHAR(100)
--SET @StartDate='2018-07-01'
--SET @EndDate='2018-08-01'
--SET @Org=1001708020135665
	
 IF object_id('tempdb.dbo.#tempResult') is NULL
	 BEGIN
	 CREATE TABLE #tempResult
	 (
	 DocNo VARCHAR(50),
	 PickLineNo INT,
	 ProductID BIGINT,
	 ProductCode VARCHAR(50),
	 ProductName NVARCHAR(255),
	 ItemMaster BIGINT,
	 Code VARCHAR(50),
	 Name NVARCHAR(255),
	 PurQty DECIMAL(18,2),
	 IssuedQty DECIMAL(18,2),
	 STDReqQty DECIMAL(18,2),
	 ActualReqQty DECIMAL(18,2),
	 ReqQty DECIMAL(18,2),
	 ActualReqDate DATETIME,--实际需求日
	 DeliveryDate DATETIME,
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
	 IF object_id('tempdb.dbo.#tempWP') is NULL
	 BEGIN
	 CREATE TABLE #tempWP
	 (
	 DocNo VARCHAR(50),--委外单
	 PickLineNo INT,--备料单行号
	 ProductID BIGINT,
	 ProductCode VARCHAR(50),--成品
	 ProductName NVARCHAR(255),
	 ItemMaster BIGINT,
	 Code VARCHAR(50),--备料
	 Name NVARCHAR(255),
	 PurQty DECIMAL(18,2),--采购数量
	 IssuedQty DECIMAL(18,2),--已发数量
	 STDReqQty DECIMAL(18,2),
	 ActualReqQty DECIMAL(18,2),--实际需求数量
	 ReqQty DECIMAL(18,2),--实际需求数量-已发数量
	 ActualReqDate DATETIME,--实际需求日
	 DeliveryDate DATETIME,--采购计划行 要求交货日期
	 RN INT
	 )
     END
     ELSE 
	 BEGIN
	 TRUNCATE TABLE #tempWP
     END
	 --库存量结果集
	 IF object_id('tempdb.dbo.#tempWHQty') is NULL
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
SET @sql='INSERT INTO #tempWP
SELECT a.DocNo,d.PickLineNo,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.ItemInfo_ItemName
,d.ItemInfo_ItemID Item,d.ItemInfo_ItemCode,d.ItemInfo_ItemName
,b.PurQtyTU--采购数量1 开工数量
,d.IssuedQty--已发放数量  
,d.STDReqQty--标准用量
,d.ActualReqQty--实际需求数量	
,d.ActualReqQty-d.IssuedQty ReqQty--
,d.ActualReqDate--实际需求日
,e.DeliveryDate
,ROW_NUMBER() OVER(ORDER BY d.ActualReqDate) RN 
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
WHERE a.Status in(0,1,2) and b.Status in (0,1,2) AND a.Org=@Org AND d.ActualReqDate BETWEEN @StartDate AND @EndDate
and  exists  (select 1 from PM_POShipLine b1  where e.ID=b1.ID   )
AND c.ID IS NOT NULL '
IF ISNULL(@DocList,'')<>''
BEGIN
SET @sql=@sql +' AND a.DocNo IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@DocList)) '
END

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
IF @StoreQty>0
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
SELECT a.*,b.LackAmount,b.IsLack,b.WhAvailiableAmount,c.SPECS
FROM #tempWP a INNER JOIN #tempResult b ON a.DocNo=b.DocNo AND a.PickLineNo=b.PickLineNo 
LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID
ORDER BY a.RN,a.DocNo,a.PickLineNo


END