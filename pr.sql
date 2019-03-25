IF OBJECT_ID(N'tempdb.dbo.#SO',N'U') IS NOT NULL
DROP TABLE #SO

IF OBJECT_ID(N'tempdb.dbo.#PR',N'U') IS NOT NULL
DROP TABLE #PR

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

,PRNO VARCHAR(50)
,PRLineNo varchar(20)
,PRCode VARCHAR(50)
,PRName NVARCHAR(255)
,ReqQtyTU DECIMAL(18,2)
,ApprovedQtyTU DECIMAL(18,2)
,PRDate DATETIME
,PRS VARCHAR(20)
,PRLS VARCHAR(20)
,PRDC VARCHAR(20)
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





SELECT a.DocNo,b.DocLineNo
,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,b.ReqQtyTU,b.ApprovedQtyTU
,b.DeliveryDate
,dbo.F_GetEnumName('UFIDA.U9.PR.PurchaseRequest.PRStatusEnum',a.Status,'zh-cn')Status,dbo.F_GetEnumName('UFIDA.U9.PR.PurchaseRequest.PRStatusEnum',b.Status,'zh-cn')Line_Status
,b.DemandCode
INTO #PR
FROM dbo.PR_PR a LEFT JOIN dbo.PR_PRLine b ON a.ID=b.PR LEFT JOIN dbo.PM_POLine c ON b.ID=c.PRLineID
WHERE a.Status IN (0,1,2) AND b.Status IN (0,1,2) AND c.DocLineNo IS NULL
AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')

;
WITH SOList AS
(
SELECT a.DocNo SONO,a.DocLineNo SOLineNo,a.ItemInfo_ItemCode SCode,a.ItemInfo_ItemName SName,a.OrderByQtyTU SQty,a.DeliveryDate SDate,a.Status S,a.Line_Status SLS,a.DemandCode SDC
,b.DocNo PRNO,b.DocLineNo PRLineNo,b.ItemInfo_ItemCode PRCode,b.ItemInfo_ItemName PRName,b.ReqQtyTU,b.ApprovedQtyTU,b.DeliveryDate PRDate,b.Status PRS,b.Line_Status PRLS,b.DemandCode PRDC
FROM #SO a LEFT JOIN #PR b ON a.demandcode=b.DemandCode-- LEFT JOIN #po c ON a.demandcode=c.demondcode LEFT JOIN #pr  d ON a.demandcode=d.DemandCode
WHERE a.demandcode<>-1
)
INSERT INTO #SOList
SELECT 'SO��ȱ�رգ�PRδ�ر�',*  FROM SOList

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
PRNo AS
(
SELECT DISTINCT docno FROM #PR EXCEPT SELECT DISTINCT PRNO FROM #SOList
),
PRR AS
(
SELECT b.DocNo SONO,b.DocLineNo SOLineNo,b.ItemInfo_ItemCode SCode,b.ItemInfo_ItemName SName,b.OrderByQtyTU SQty,b.DeliveryDate SDate,b.Status S,b.Line_Status SLS,b.DemandCode SDC
,a.*
FROM #PR a left JOIN SO2 b ON a.DemandCode=b.DemandCode 
WHERE a.DocNo IN (SELECT * FROM PRNo) AND a.DemandCode<>-1 AND (b.Line_Status='��Ȼ�ر�' OR b.DocNo IS NULL)
)
INSERT INTO #SOList
SELECT 'SO��Ȼ�رգ�PRδ�ر�',* FROM PRR

INSERT INTO #SOList       
  SELECT '�ֹ�PR','','','','',null,null,'','','',* FROM #PR WHERE DemandCode=-1

SELECT CASE WHEN SONO IS NULL  THEN '' ELSE SONO+'-'+SOLineNo END ��������,* FROM #SOList



