--组装线生产日报表
alter PROC sp_Auctus_AssemblyLineDailyReport
(
@LineType INT,@MO_DocNo NVARCHAR(40),@SD DATETIME,@ED datetime
)
AS
BEGIN

--DECLARE @LineType INT=8,@MO_DocNo NVARCHAR(40),@SD DATETIME='2019-01-13',@ED datetime='2019-03-15'
SET @MO_DocNo='%'+ISNULL(@MO_DocNo,'')+'%';
--BSN集合临时表
IF object_id('tempdb.dbo.#tempBSN') is NULL
BEGIN
	CREATE TABLE #tempBSN(
	AssemblyPlanDetailID INT,
	TS DATETIME,
	InternalCode NVARCHAR(40)
	)
END 
ELSE
BEGIN
	TRUNCATE TABLE #tempBSN
END 
--将BSN集合保存到临时表
INSERT INTO #tempBSN SELECT a.AssemblyPlanDetailID,a.TS,a.InternalCode 
FROM dbo.opPlanExecutMain a INNER JOIN dbo.plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID INNER JOIN dbo.plAssemblyPlan c ON b.AssemblyPlanID=c.ID
 WHERE PATINDEX(@MO_DocNo,b.WorOrder)>0 AND @LineType=c.AssemblyLineID

 
SELECT c.WorOrder,c.MaterialCode,c.MaterialName,c.Quantity,a.Name LineName,(SELECT FORMAT(MIN(TS),'yyyy-MM-dd HH:mm:ss') FROM #tempBSN ts WHERE ts.AssemblyPlanDetailID=c.ID  AND ts.TS>=@SD AND ts.TS<@ED)StartDate
,(SELECT FORMAT(MAX(CreateDate),'yyyy-MM-dd HH:mm:ss') FROM dbo.mxqh_baBarcodePrint f,#tempBSN f1 WHERE f1.AssemblyPlanDetailID=c.ID AND  f.InternalCode=f1.InternalCode AND f.CreateDate>=@SD AND f.CreateDate<@ED)EndDate
,(SELECT COUNT(*) FROM #tempBSN t WHERE t.AssemblyPlanDetailID=c.ID AND t.TS >=@SD AND t.TS<@ED)InputQty
,(SELECT COUNT(*) FROM #tempBSN t INNER JOIN dbo.baInternalAndSNCode t1 ON  t.AssemblyPlanDetailID=c.ID AND t.InternalCode=t1.InternalCode AND CONVERT(VARCHAR(100), t1.CreateDate, 120)>=@SD AND CONVERT(VARCHAR(100),t1.CreateDate, 120)<@ED)ResetQty
,(SELECT COUNT(*) FROM dbo.mxqh_baBarcodePrint f,#tempBSN f1 WHERE f1.AssemblyPlanDetailID=c.ID AND f.InternalCode=f1.InternalCode AND f.CreateDate>=@SD AND f.CreateDate<@ED)OutputQty
FROM dbo.baAssemblyLine a INNER JOIN dbo.plAssemblyPlan b ON a.ID=b.AssemblyLineID
INNER JOIN dbo.plAssemblyPlanDetail c ON b.ID=c.AssemblyPlanID
INNER JOIN (SELECT DISTINCT AssemblyPlanDetailID FROM #tempBSN)d ON c.ID=d.AssemblyPlanDetailID 

--;WITH data1 AS
--(
--SELECT c.WorOrder,c.MaterialCode,c.MaterialName,c.Quantity,a.Name LineName,d.TS
--,CASE WHEN ISNULL(d.InternalCode,'')<>'' THEN 1 ELSE 0 END InternalCode1
--,CASE WHEN ISNULL(e.InternalCode,'')<>'' THEN 1 ELSE 0 END InternalCode2
--,CASE WHEN ISNULL(f.InternalCode,'')<>'' THEN 1 ELSE 0 END InternalCode3
--,f.CreateDate FROM dbo.baAssemblyLine a INNER JOIN dbo.plAssemblyPlan b ON a.ID=b.AssemblyLineID
--INNER JOIN dbo.plAssemblyPlanDetail c ON b.ID=c.AssemblyPlanID
--INNER JOIN #tempBSN d ON c.ID=d.AssemblyPlanDetailID--投入数量
--LEFT JOIN dbo.baInternalAndSNCode e ON d.InternalCode=e.InternalCode AND e.TS >=@SD AND e.TS<@ED--复位数量
--LEFT JOIN dbo.mxqh_baBarcodePrint f ON e.InternalCode=f.InternalCode AND e.SNCode=f.SNCode AND f.CreateDate>=@SD AND f.CreateDate<@ED--产出数量
--)
--SELECT a.WorOrder,a.MaterialCode,a.MaterialName,a.LineName,MIN(a.Quantity)Quantity,MIN(a.TS)StartDate,MAX(a.CreateDate) EndDate
--,SUM(a.InternalCode1)InputQty,SUM(a.InternalCode2)ResetQty,SUM(a.InternalCode3)OutputQty
--FROM data1 a 
--GROUP BY a.WorOrder,a.MaterialCode,a.MaterialName,a.LineName

END 
