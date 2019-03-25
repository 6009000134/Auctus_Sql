IF OBJECT_ID(N'tempdb.dbo.#SO',N'U') IS NOT NULL
DROP TABLE #SO

IF OBJECT_ID(N'tempdb.dbo.#PO',N'U') IS NOT NULL
DROP TABLE #PO

IF OBJECT_ID(N'tempdb.dbo.#SOList',N'U') IS NOT NULL
DROP TABLE #SOList

CREATE TABLE #SOList(
Remark VARCHAR(50)
,SONO VARCHAR(50)
,SOLineNo VARCHAR(50)
,SCode VARCHAR(50)
,SName NVARCHAR(255)
,SQty decimal(18,2)
,SDate DATETIME
,S VARCHAR(50)
,SLS VARCHAR(50)
,SDC VARCHAR(50)
,PONo VARCHAR(50)
,POLineNo VARCHAR(50)
,PSubLineNo VARCHAR(50)
, PCode VARCHAR(50)
, PName nvarchar(255)
,PDate DATETIME
,PS VARCHAR(50)
,PLS VARCHAR(50)
,PSLS varchar(50)
,WPRNO VARCHAR(50)
,PRLineID BIGINT
, PDC VARCHAR(50)
,PDC2 VARCHAR(50)
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

SELECT a.DocNo,b.DocLineNo,c.SubLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName
,c.DeliveryDate
,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',a.Status,'zh-cn')Status
,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn')Line_Status,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',c.Status,'zh-cn')SubLineStatus
,b.PRNO,b.PRLineID
,b.DemondCode,c.DemondCode DC
INTO #PO
FROM dbo.PM_PurchaseOrder a LEFT JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder LEFT JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE  a.Status IN (0,1,2) AND b.Status IN (0,1,2)
AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
;
WITH SOList AS
(
SELECT a.DocNo SONO,a.DocLineNo SOLineNo,a.ItemInfo_ItemCode SCode,a.ItemInfo_ItemName SName,a.OrderByQtyTU SQty,a.DeliveryDate SDate,a.Status S,a.Line_Status SLS,a.DemandCode SDC
,b.DocNo PONO,b.DocLineNo POLineNo,b.SubLineNo PSubLineNo,b.ItemInfo_ItemCode PCode,b.ItemInfo_ItemName PName,b.DeliveryDate PDate,b.Status PS,b.Line_Status PLS,b.SubLineStatus PSLS
,b.PRNO WPRNO,b.PRLineID,b.DemondCode PDC,b.DC PDC2
FROM #SO a LEFT JOIN #PO b ON a.demandcode=b.DC-- LEFT JOIN #po c ON a.demandcode=c.demondcode LEFT JOIN #pr  d ON a.demandcode=d.DemandCode
WHERE a.demandcode<>-1 AND ISNULL(b.DocNo,'')<>''
)
INSERT INTO #SOList
SELECT 'SO短缺关闭，PO未关闭',*  FROM SOList

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
PONO AS
(
SELECT DISTINCT docno FROM #po EXCEPT SELECT DISTINCT pono FROM #SOList
),
POR AS
(
SELECT b.DocNo SONO,b.DocLineNo SOLineNo,b.ItemInfo_ItemCode SCode,b.ItemInfo_ItemName SName,b.OrderByQtyTU SQty,b.DeliveryDate SDate,b.Status S,b.Line_Status SLS,b.DemandCode SDC
,a.*
FROM #PO a left JOIN SO2 b ON a.DC=b.DemandCode 
WHERE a.DocNo IN (SELECT * FROM PONO) AND a.DC<>-1 AND (b.Line_Status='自然关闭' OR b.DocNo IS NULL)
)
INSERT INTO #SOList
SELECT 'SO自然关闭，PO未关闭',* FROM POR

INSERT INTO #SOList       
  SELECT '手工/期初PO','','','','',null,null,'','','',* FROM #PO WHERE DC=-1
  


SELECT CASE WHEN SONO IS NULL  THEN '' ELSE SONO+'-'+SOLineNo END 需求分类号,* FROM #SOList



