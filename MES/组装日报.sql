--组装线生产日报表
ALTER PROC [dbo].[sp_Auctus_AssemblyLineDailyReport]
(
@LineType INT,@MO_DocNo NVARCHAR(40),@SD DATETIME,@ED datetime
)
AS
BEGIN

--DECLARE @LineType INT=8,@MO_DocNo NVARCHAR(40),@SD DATETIME='2019-01-13',@ED datetime='2019-03-15'
SET @MO_DocNo='%'+ISNULL(@MO_DocNo,'')+'%';
IF ISNULL(@SD,'')=''
SET @SD='1990-01-01'
IF ISNULL(@ED,'')=''
SET @ED='9990-01-01'
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
IF	ISNULL(@LineType,0)=0
BEGIN
	--将BSN集合保存到临时表
	INSERT INTO #tempBSN SELECT a.AssemblyPlanDetailID,a.TS,a.InternalCode 
	FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID INNER JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID
	WHERE PATINDEX(@MO_DocNo,b.WorkOrder)>0
END 
ELSE
BEGIN
	--将BSN集合保存到临时表
	INSERT INTO #tempBSN SELECT a.AssemblyPlanDetailID,a.TS,a.InternalCode 
	FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID INNER JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID
	 WHERE PATINDEX(@MO_DocNo,b.WorkOrder)>0 AND @LineType=c.AssemblyLineID
END 

 
SELECT c.WorkOrder WorOrder,c.MaterialCode,c.MaterialName,c.Quantity,a.Name LineName,(SELECT FORMAT(MIN(TS),'yyyy-MM-dd HH:mm:ss') FROM #tempBSN ts WHERE ts.AssemblyPlanDetailID=c.ID  AND ts.TS>=@SD AND ts.TS<@ED)StartDate
,(SELECT FORMAT(MAX(CreateDate),'yyyy-MM-dd HH:mm:ss') FROM dbo.mxqh_baBarcodePrint f,#tempBSN f1 WHERE f1.AssemblyPlanDetailID=c.ID AND  f.InternalCode=f1.InternalCode AND f.CreateDate>=@SD AND f.CreateDate<@ED)EndDate
,(SELECT COUNT(*) FROM #tempBSN t WHERE t.AssemblyPlanDetailID=c.ID AND t.TS >=@SD AND t.TS<@ED)InputQty
,(SELECT COUNT(*) FROM #tempBSN t INNER JOIN dbo.baInternalAndSNCode t1 ON  t.AssemblyPlanDetailID=c.ID AND t.InternalCode=t1.InternalCode AND CONVERT(VARCHAR(100), t1.CreateDate, 120)>=@SD AND CONVERT(VARCHAR(100),t1.CreateDate, 120)<@ED)ResetQty
,(SELECT COUNT(*) FROM dbo.mxqh_baBarcodePrint f,#tempBSN f1 WHERE f1.AssemblyPlanDetailID=c.ID AND f.InternalCode=f1.InternalCode AND f.CreateDate>=@SD AND f.CreateDate<@ED)OutputQty
FROM dbo.baAssemblyLine a INNER JOIN dbo.mxqh_plAssemblyPlan b ON a.ID=b.AssemblyLineID
INNER JOIN dbo.mxqh_plAssemblyPlanDetail c ON b.ID=c.AssemblyPlanID
INNER JOIN (SELECT DISTINCT AssemblyPlanDetailID FROM #tempBSN)d ON c.ID=d.AssemblyPlanDetailID 

END 
