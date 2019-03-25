CREATE PROC sp_Auctus_SORelateDocCheck
(
@SOID VARCHAR(50),
@DocLineNo VARCHAR(20),
@Result VARCHAR(MAX) OUT 
)
AS
BEGIN 

--DECLARE @DocNo VARCHAR(50)
--DECLARE @DocLineNo VARCHAR(50)
--DECLARE @Result VARCHAR(MAX)
--SET @DocNo='SO30201808082'
--SET @DocLineNo='10'

DECLARE @PRNum INT=0
DECLARE @PONum INT=0
DECLARE @MONum INT=0

IF OBJECT_ID(N'tempdb.dbo.#tempSO',N'U')IS NULL
CREATE TABLE #tempSO(DocNo VARCHAR(50),DocLineNo VARCHAR(50),DocSubLineNo varchar(50),DemandCode VARCHAR(10))
ELSE
TRUNCATE TABLE #tempSO
INSERT INTO #tempSO
SELECT a.DocNo,b.DocLineNo,c.DocSubLineNo,c.DemandType 
FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO INNER JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
WHERE a.ID=@SOID AND b.DocLineNo=@DocLineNo

--下游PR(3\4\5  自然\短缺\超额关闭)
SELECT 
@PRNum=COUNT(*)
--a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,a.Status,b.Status ,dbo.F_GetEnumName('UFIDA.U9.PR.PurchaseRequest.PRStatusEnum',a.Status,'zh-cn')PRStatus
--,dbo.F_GetEnumName('UFIDA.U9.PR.PurchaseRequest.PRStatusEnum',b.Status,'zh-cn')PRLine_Status
FROM dbo.PR_PR a INNER JOIN dbo.PR_PRLine b ON a.ID=b.PR 
WHERE b.DemandCode IN (SELECT DISTINCT DemandCode FROM #tempSO)
AND b.Status NOT IN (3,4,5) 


--下游PO(3\4\5  自然\短缺\超额关闭)
SELECT 
@PONum=COUNT(*)
--a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,a.Status,b.Status,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',a.Status,'zh-cn')POStatus
--,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn')POLine_Status
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE c.DemondCode IN (SELECT DISTINCT DemandCode FROM #tempSO)
AND b.Status NOT IN (3,4,5)

--MO是否关闭（3 完工关闭）
SELECT 
@MONum=COUNT(*)
--a.DocNo,a.DocState
FROM dbo.MO_MO a WHERE a.DemandCode IN (SELECT DISTINCT DemandCode FROM #tempSO)
AND a.DocState<>3


DECLARE @PRList VARCHAR(MAX)
DECLARE @POList VARCHAR(MAX)
DECLARE @MOList VARCHAR(MAX)

IF ISNULL(@PRNum,0)<>0 
SELECT @PRList=(
SELECT 
a.DocNo+'-'+CONVERT(VARCHAR(10),b.DocLineNo)+','
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE c.DemondCode IN (SELECT DISTINCT DemandCode FROM #tempSO)
AND b.Status NOT IN (3,4,5)
FOR XML PATH(''))

IF ISNULL(@PONum,0)<>0 
SELECT @POList=(
SELECT 
a.DocNo+'-'+CONVERT(VARCHAR(10),b.DocLineNo)+','
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE c.DemondCode IN (SELECT DISTINCT DemandCode FROM #tempSO)
AND b.Status NOT IN (3,4,5)
FOR XML PATH(''))

IF ISNULL(@MONum,0)<>0 
SELECT @MOList=(
SELECT 
a.DocNo+','
FROM dbo.MO_MO a WHERE a.DemandCode IN (SELECT DISTINCT DemandCode FROM #tempSO)
AND a.DocState<>3
FOR XML PATH(''))
SET @Result=ISNULL(@PRList,'')+ISNULL(@POList,'')+ISNULL(@MOList,'')
IF ISNULL(@Result,'')=''
SET @Result='0'
ELSE 
SET @Result=left(@Result,LEN(@Result)-1)
--SELECT @PRList
--SELECT @POList
--SELECT @MOList
--SELECT @Result
END
