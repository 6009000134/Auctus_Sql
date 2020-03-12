/*
MES完工，但是U9未入库数据
*/
alter PROC sp_Mail_MaterialNotStored
AS
BEGIN

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN 
	TRUNCATE TABLE #TempTable
END 
ELSE
	CREATE TABLE #TempTable (ID INT,WorkOrder VARCHAR(40))
--工单集合
INSERT INTO #TempTable
SELECT a.ID,a.WorkOrder FROM dbo.mxqh_plAssemblyPlanDetail a WHERE a.Status IN (1,2,3,5,6)
OR (a.Status=4 AND DATEDIFF(DAY,a.CompleteDate,GETDATE())<30)

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempResult') AND TYPE='U')
BEGIN 
	TRUNCATE TABLE #TempResult
END 
ELSE
	CREATE TABLE #TempResult (WorkOrder VARCHAR(40),CompleteQty INT)

--包装工单
INSERT INTO #TempResult
SELECT d.WorkOrder,COUNT(1)CompleteQty
FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID
INNER JOIN #TempTable d ON a.AssemblyPlanDetailID=d.ID
GROUP BY d.ID,d.WorkOrder

INSERT INTO #TempResult
SELECT t.WorkOrder,COUNT(1)CompleteQty FROM 
(
SELECT b.WorkOrder
,ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY c.OrderNum desc)RN
,a.InternalCode,c.IsPass,c.OrderNum
FROM dbo.opPlanExecutMain a INNER JOIN #TempTable b ON a.AssemblyPlanDetailID=b.ID
INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
WHERE --b.WorkOrder=@WorkOrder AND 
c.ExtendOne=0
) t WHERE t.RN=1 AND t.IsPass=1
GROUP BY t.WorkOrder


--完工信息
INSERT INTO #TempResult
SELECT t.WorkOrder,COUNT(t.WorkOrder)CompleteQty
FROM 
(
SELECT b.WorkOrder
,ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY c.OrderNum desc)RN
,a.InternalCode,c.IsPass,c.OrderNum
FROM dbo.opPlanExecutMainHH a INNER JOIN #TempTable b ON a.AssemblyPlanDetailID=b.ID
INNER JOIN dbo.opPlanExecutDetailHH c ON a.ID=c.PlanExecutMainID
--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
WHERE c.ExtendOne=0
) t WHERE t.RN=1 AND t.IsPass=1
GROUP BY t.WorkOrder



--没工艺工单，完工数量查完工报告
BEGIN
	INSERT INTO #TempResult
	SELECT t.WorkOrder,SUM(t.CompleteQty)CompleteQty
	FROM  (SELECT a.CompleteQty,a.WorkOrder,a.WorkOrderID
	FROM dbo.mxqh_CompleteRpt a INNER JOIN #TempTable b ON a.WorkOrderID=b.ID	
	) t
	GROUP BY t.WorkOrder
END 


END 

SELECT  TOP 1 1 MailNo, 'liufei@auctus.com' AS MailTo, 'U9UnStoredMaterial.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE
FROM #TempResult a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrder=b.WorkOrder AND a.CompleteQty>b.U9_TotalCompleteQty
--GROUP BY MailTo

SELECT a.*,b.MaterialCode,b.MaterialName ,b.U9_TotalCompleteQty
FROM #TempResult a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrder=b.WorkOrder AND a.CompleteQty>b.U9_TotalCompleteQty



--;WITH data1 AS
--    (
--		SELECT b.WorkOrder,'包装'T FROM dbo.opPackageMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID 
--		WHERE b.WorkOrder IN (
--		SELECT a.WorkOrder FROM #TempResult a
--		GROUP BY WorkOrder HAVING COUNT(1)>1)
--	),
--	data2 AS
--    (
--		SELECT b.WorkOrder,'组装'T FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID 
--		WHERE b.WorkOrder IN (
--		SELECT a.WorkOrder FROM #TempResult a
--		GROUP BY WorkOrder HAVING COUNT(1)>1)
--	),
--	data3 AS
--    (
--		SELECT b.WorkOrder,'后焊'T FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID 
--		WHERE b.WorkOrder IN (
--		SELECT a.WorkOrder FROM #TempResult a
--		GROUP BY WorkOrder HAVING COUNT(1)>1)
--	)
--	SELECT DISTINCT * FROM data1 a INNER JOIN data2 b ON a.workorder=b.workorder 
--	--SELECT * FROM data1 a INNER JOIN data3 b ON a.workorder=b.workorder 

