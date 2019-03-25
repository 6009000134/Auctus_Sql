IF OBJECT_ID(N'tempdb.dbo.#SO',N'U') IS NOT NULL
DROP TABLE #SO

IF OBJECT_ID(N'tempdb.dbo.#MO',N'U') IS NOT NULL
DROP TABLE #MO

IF OBJECT_ID(N'tempdb.dbo.#PO',N'U') IS NOT NULL
DROP TABLE #PO

IF OBJECT_ID(N'tempdb.dbo.#PR',N'U') IS NOT NULL
DROP TABLE #PR

IF OBJECT_ID(N'tempdb.dbo.#SOList',N'U') IS NOT NULL
DROP TABLE #SOList

CREATE TABLE #SOList(
SONO VARCHAR(50)
,SOLineNo VARCHAR(50)
,SCode VARCHAR(50)
,SName VARCHAR(50)
,SQty decimal(18,2)
,SDate DATETIME
,S VARCHAR(50)
,SLS VARCHAR(50)
,SDC VARCHAR(50)
,MONo VARCHAR(50)
,ProductQty decimal(18,2)
,TotalCompleteQty decimal(18,2)
,IsHoldRelease VARCHAR(50)
, MCode VARCHAR(50)
, MName VARCHAR(50)
, MDC VARCHAR(50)
,MState VARCHAR(50)
)

SELECT a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName
,b.OrderByQtyTU,c.DeliveryDate
,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',a.Status,'zh-cn')Status,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',b.Status,'zh-cn')Line_Status
,a.DemandType ,c.DemandType DemandCode 
INTO #SO
FROM dbo.SM_SO a LEFT JOIN SM_SOLine b ON a.ID=b.SO LEFT JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
WHERE (b.Status=5 --OR a.Status=5
) 
AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')



SELECT a.DocNo,a.ProductQty,a.TotalCompleteQty
,CASE WHEN a.IsHoldRelease=0 THEN NULL ELSE '挂起' END IsHoldRelease
,c.Code,c.Name,a.DemandCode 
,dbo.F_GetEnumName('UFIDA.U9.MO.Enums.MOStateEnum',a.DocState,'zh-cn')DocState
INTO #MO
FROM dbo.MO_MO a LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID
WHERE a.Cancel_Canceled=0 AND a.DocState<>3 

SELECT a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,c.SubLineNo
,c.ItemInfo_ItemCode code2,c.ItemInfo_ItemName name2,c.DeliveryDate
,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',a.Status,'zh-cn')Status
,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn')Line_Status,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',c.Status,'zh-cn')SubLineStatus
,b.PRNO,b.PRLineID
,b.DemondCode,c.DemondCode DC
INTO #PO
FROM dbo.PM_PurchaseOrder a LEFT JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder LEFT JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE  a.Status IN (0,1,2) AND b.Status IN (0,1,2)

--SELECT a.DocNo,b.DocLineNo
--,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,b.ReqQtyTU 需求数量1,b.ApprovedQtyTU 核准数量1
--,b.DeliveryDate
--,dbo.F_GetEnumName('UFIDA.U9.PR.PurchaseRequest.PRStatusEnum',a.Status,'zh-cn')Status,dbo.F_GetEnumName('UFIDA.U9.PR.PurchaseRequest.PRStatusEnum',b.Status,'zh-cn')Line_Status
--,b.DemandCode
--INTO #PR
--FROM dbo.PR_PR a LEFT JOIN dbo.PR_PRLine b ON a.ID=b.PR
--WHERE a.Status IN (0,1,2) AND b.Status IN (0,1,2)



--SELECT *
--FROM #SO a LEFT JOIN #MO b ON a.demandcode=b.demandcode LEFT JOIN #po c ON a.demandcode=c.demondcode LEFT JOIN #pr  d ON a.demandcode=d.DemandCode
--WHERE a.demandcode<>-1

;
WITH SOList AS
(
SELECT a.DocNo SONO,a.DocLineNo SOLineNo,a.ItemInfo_ItemCode SCode,a.ItemInfo_ItemName SName,a.OrderByQtyTU SQty,a.DeliveryDate SDate,a.Status S,a.Line_Status SLS,a.DemandCode SDC
,b.DocNo MONo,b.ProductQty,b.TotalCompleteQty,b.IsHoldRelease,b.Code MCode,b.Name MName,b.DemandCode MDC,b.DocState MState
--,c.DocNo PONO,c.DocLineNo POLineNo,c.SubLineNo PSubLineNo,c.ItemInfo_ItemCode PCode,c.ItemInfo_ItemName PName,c.DeliveryDate PDate,c.Status PS,c.Line_Status PLS,c.SubLineStatus PSLS
--,c.PRNO WPRNO,c.PRLineID,c.DemondCode PDC,c.DC PDC2
--,d.DocNo PRNO,d.DocLineNo PRLineNo,d.ItemInfo_ItemCode PRCode,d.ItemInfo_ItemName PRName,d.需求数量1,d.核准数量1,d.DeliveryDate PRDate,d.Status PRS,d.Line_Status PRLS,d.DemandCode PRDC
FROM #SO a LEFT JOIN #MO b ON a.demandcode=b.demandcode-- LEFT JOIN #po c ON a.demandcode=c.demondcode LEFT JOIN #pr  d ON a.demandcode=d.DemandCode
WHERE a.demandcode<>-1
)
INSERT INTO #SOList
SELECT *  FROM SOList

;
WITH SO2 AS
(
SELECT a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName
,b.OrderByQtyTU,c.DeliveryDate
,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',a.Status,'zh-cn')Status,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',b.Status,'zh-cn')Line_Status
,a.DemandType ,c.DemandType DemandCode 
FROM dbo.SM_SO a LEFT JOIN SM_SOLine b ON a.ID=b.SO LEFT JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
WHERE (b.Status<>5 --OR a.Status=5
) 
AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
),
MONO AS
(
SELECT DISTINCT docno FROM #mo EXCEPT SELECT DISTINCT mono FROM #SOList
),
MOR AS
(
SELECT b.DocNo SONO,b.DocLineNo SOLineNo,b.ItemInfo_ItemCode SCode,b.ItemInfo_ItemName SName,b.OrderByQtyTU SQty,b.DeliveryDate SDate,b.Status S,b.Line_Status SLS,b.DemandCode SDC
,a.*
FROM #MO a left JOIN SO2 b ON a.DemandCode=b.DemandCode 
WHERE a.DocNo IN (SELECT * FROM MONO) AND a.DemandCode<>-1 AND (b.Line_Status='自然关闭' OR b.DocNo IS NULL)
)
INSERT INTO #SOList
SELECT * FROM MOR

SELECT CASE WHEN SONO IS NULL  THEN '' ELSE SONO+'-'+SOLineNo END 需求分类号,* FROM #SOList



