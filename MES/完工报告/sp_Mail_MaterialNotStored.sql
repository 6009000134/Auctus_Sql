/*
MES完工，但是U9未入库数据
*/
ALTER PROC [dbo].[sp_Mail_MaterialNotStored]
AS
BEGIN

DECLARE @NowDate DATE=GETDATE()

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
,ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum DESC,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')) desc)RN
,a.InternalCode,c.IsPass,c.OrderNum
FROM dbo.opPlanExecutMain a INNER JOIN #TempTable b ON a.AssemblyPlanDetailID=b.ID
INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
WHERE --b.WorkOrder=@WorkOrder AND 
c.ExtendOne=0
AND c.TS<@NowDate
) t WHERE t.RN=1 AND t.IsPass=1
GROUP BY t.WorkOrder


--完工信息
INSERT INTO #TempResult
SELECT t.WorkOrder,COUNT(t.WorkOrder)CompleteQty
FROM 
(
SELECT b.WorkOrder
,ROW_NUMBER()OVER(PARTITION BY a.InternalCode,a.ID ORDER BY c.OrderNum desc,ISNULL(c.PassTime,FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')) desc)RN
,a.InternalCode,c.IsPass,c.OrderNum
FROM dbo.opPlanExecutMainHH a INNER JOIN #TempTable b ON a.AssemblyPlanDetailID=b.ID
INNER JOIN dbo.opPlanExecutDetailHH c ON a.ID=c.PlanExecutMainID
--INNER JOIN dbo.opPlanExecutChild d ON c.ID=d.PlanExecutDetailID
WHERE c.ExtendOne=0
AND c.TS<@NowDate
) t WHERE t.RN=1 AND t.IsPass=1
GROUP BY t.WorkOrder



--没工艺工单，完工数量查完工报告
BEGIN
	INSERT INTO #TempResult
	SELECT t.WorkOrder,SUM(t.CompleteQty)CompleteQty
	FROM  (SELECT a.CompleteQty,a.WorkOrder,a.WorkOrderID
	FROM dbo.mxqh_CompleteRpt a INNER JOIN #TempTable b ON a.WorkOrderID=b.ID	
	WHERE a.CompleteDate<@NowDate
	) t
	GROUP BY t.WorkOrder
END 


END 

SELECT  TOP 1 1 MailNo, 'liufei@auctus.com' AS MailTo, 'U9UnStoredMaterial.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE
--SELECT  TOP 1 1 MailNo, 'mescomplete@auctus.cn' AS MailTo, 'U9UnStoredMaterial.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE
,FORMAT(GETDATE(),'yyyy-MM-dd')NowDate
FROM #TempResult a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrder=b.WorkOrder AND a.CompleteQty>b.U9_TotalCompleteQty
--GROUP BY MailTo

SELECT a.*,b.Quantity,b.MaterialCode,b.MaterialName ,b.U9_TotalCompleteQty,a.CompleteQty-b.U9_TotalCompleteQty UnRcvQty,d.Name LineName
,m.TotalCompleteQty,CONVERT(INT,m.TotalStartQty)TotalStartQty
--,b.TotalStartQty,b.U9_TotalCompleteQty--,m.DocNo,m.DocState
,ROW_NUMBER() OVER(ORDER BY b.WorkOrder)RN
FROM #TempResult a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrder=b.WorkOrder AND a.CompleteQty>b.U9_TotalCompleteQty AND b.Quantity>b.U9_TotalCompleteQty
INNER JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID INNER JOIN dbo.baAssemblyLine d ON c.AssemblyLineID=d.ID
LEFT JOIN [U9DATA].[AuctusERP].[dbo].[MO_MO] m ON b.WorkOrder=m.DocNo
WHERE b.TotalStartQty<>b.U9_TotalCompleteQty AND m.DocState<>3

--SELECT a.*,b.Quantity,b.MaterialCode,b.MaterialName ,b.U9_TotalCompleteQty,a.CompleteQty-b.U9_TotalCompleteQty UnRcvQty,d.Name LineName
--,ROW_NUMBER() OVER(ORDER BY b.WorkOrder)RN
--FROM #TempResult a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrder=b.WorkOrder AND a.CompleteQty>b.U9_TotalCompleteQty AND b.Quantity>b.U9_TotalCompleteQty
--INNER JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID INNER JOIN dbo.baAssemblyLine d ON c.AssemblyLineID=d.ID
--WHERE b.TotalStartQty<b.U9_TotalCompleteQty


