
--齐套分析（给3天齐套率报表使用的）
ALTER PROC [dbo].[sp_Auctus_GetLackDoc]
(
@Date DATETIME,
@Org BIGINT
)
AS
BEGIN  
--DECLARE @Date DATE
--DECLARE @Org BIGINT
----查询截止到目前为止的不齐套的WPO
--SET @Date=GETDATE()
--SET @Org=(SELECT ID FROM dbo.Base_Organization WHERE code='300')

	 --IF OBJECT_ID('tempdb.dbo.#tempLackDoc') is NULL--若#tempLackDoc表不存在，直接返回
	 --RETURN ;

	 --备料单结果集
	 IF object_id('tempdb.dbo.#tempWP') is NULL
	 BEGIN
	 CREATE TABLE #tempWP
	 (
	 DocNo VARCHAR(50),--委外单
	 PickLineNo INT,--备料单行号
	 Code VARCHAR(50),--备料
	 Name NVARCHAR(255),
	 IssuedQty DECIMAL(18,2),--已发数量
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

;

	 IF object_id('tempdb.dbo.#tempResult') is NULL
	 BEGIN
	 CREATE TABLE #tempResult
	 (
	 DocNo VARCHAR(50),
	 PickLineNo INT,
	 Code VARCHAR(50),
	 Name NVARCHAR(255),
	 IssuedQty DECIMAL(18,2),
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
	; 
WITH WPO AS
(
SELECT a.DocNo,d.PickLineNo,d.ItemInfo_ItemCode,d.ItemInfo_ItemName,d.IssuedQty,d.ActualReqQty,d.ActualReqQty-d.IssuedQty ReqQty
,d.ActualReqDate
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
WHERE a.Status in(0,1,2) and b.Status in (0,1,2)
AND DATEADD(DAY,-3,d.ActualReqDate)<@Date
and  exists  (select 1 from PM_POShipLine b1  where e.ID=b1.ID   )
AND c.ID IS NOT NULL
AND d.IssueStyle<>2
AND d.ActualReqQty>0
AND d.IssuedQty<d.ActualReqQty--只取发料还不齐的
AND a.Org=@Org
),
MOPickList AS--查询目前为止不齐套的MO
(
SELECT a.DocNo,b.DocLineNO,c.Code,c.Name,b.IssuedQty,b.ActualReqQty,b.ActualReqQty-b.IssuedQty ReqQty
,b.ActualReqDate
FROM dbo.MO_MO a LEFT JOIN dbo.MO_MOPickList b ON a.ID=b.MO
LEFT JOIN dbo.CBO_ItemMaster c ON b.ItemMaster=c.ID
WHERE a.DocState<>3--非完工订单
AND a.Cancel_Canceled=0
AND DATEADD(DAY,-3,b.ActualReqDate) <@Date
and b.ActualReqQty>0
and b.IssueStyle<>4
AND b.IssuedQty<b.ActualReqQty--只取发料还不齐的
and a.Org=@Org
),
AllList AS--所有料不齐的料号
(
SELECT * FROM MOPickList 
UNION ALL
SELECT * FROM WPO
)
INSERT INTO #tempWP
SELECT *,ROW_NUMBER()OVER(ORDER BY AllList.ActualReqDate)rn FROM AllList

--SELECT * FROM #tempWP
--SELECT * FROM #tempWP WHERE code LIKE '403%'
;
WITH PickList AS
(
SELECT DISTINCT Code FROM #tempWP
),
WH AS
(
SELECT a.ItemInfo_ItemCode,SUM(a.StoreQty)StoreQty FROM dbo.InvTrans_WhQoh a LEFT JOIN dbo.CBO_Wh b ON a.Wh=b.ID
WHERE b.Org=(SELECT ID FROM dbo.Base_Organization WHERE code='300') AND b.LocationType=0--普通仓
AND b.Effective_IsEffective=1
AND a.StorageType  not  in (5,1,2,0,3,7) --0、1、2、3、5、7 待检、在检、不合格、报废、冻结、待返工
AND a.ItemInfo_ItemCode IN (SELECT DISTINCT  Code FROM #tempWP)
GROUP BY a.ItemInfo_ItemCode
)
INSERT INTO #tempWHQty
SELECT a.Code,ISNULL(b.StoreQty,0)StoreQty FROM PickList a LEFT JOIN WH b ON a.Code=b.ItemInfo_ItemCode



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

INSERT INTO Auctus_SetCheckResult
SELECT  @Date,b.DocNo,b.PickLineNo,a.Code,a.Name,a.IssuedQty,a.ActualReqQty,a.ReqQty,a.ActualReqDate,b.LackAmount,b.IsLack,b.WhAvailiableAmount
--,ROW_NUMBER() OVER(ORDER BY a.ActualReqDate)
FROM #tempWP a INNER JOIN #tempResult b ON a.DocNo=b.DocNo AND a.PickLineNo=b.PickLineNo 
--LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID
WHERE b.LackAmount<0
--SELECT * FROM Auctus_SetCheckResult
----截止目前为止仍缺料的工单
--INSERT INTO #tempLackDoc
--SELECT  a.DocNo,MAX(a.ActualReqDate)ActualReqDate
--FROM #tempWP a INNER JOIN #tempResult b ON a.DocNo=b.DocNo AND a.PickLineNo=b.PickLineNo 
----LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID
--WHERE b.LackAmount<0
--GROUP BY a.DocNo

END