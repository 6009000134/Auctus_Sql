/*
mes完工U9未入库查询
*/
CREATE PROCEDURE [dbo].[sp_GetMaterialNotStored]
(
@NowDate DATE,
@WorkOrder VARCHAR(50),
@LineID VARCHAR(50)
)
AS
BEGIN
set @NowDate=DATEADD(DAY,1,GETDATE())

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN 
	TRUNCATE TABLE #TempTable
END 
ELSE
	CREATE TABLE #TempTable (ID INT,WorkOrder VARCHAR(40),CompleteType INT)
--工单集合
INSERT INTO #TempTable
SELECT a.ID,a.WorkOrder,a.CompleteType FROM dbo.mxqh_plAssemblyPlanDetail a 
INNER JOIN dbo.mxqh_plAssemblyPlan b ON a.AssemblyPlanID=b.ID
INNER JOIN dbo.baAssemblyLine c ON b.AssemblyLineID=c.ID
WHERE (a.Status IN (1,2,3,5,6)
OR (a.Status=4 AND DATEDIFF(DAY,a.CompleteDate,GETDATE())<30))
AND ISNULL(@WorkOrder,a.WorkOrder)=a.WorkOrder AND ISNULL(@LineID,c.ID)=c.ID
--mes完工数
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempResult') AND TYPE='U')
BEGIN 
	TRUNCATE TABLE #TempResult
END 
ELSE
	CREATE TABLE #TempResult (WorkOrder VARCHAR(40),CompleteQty INT)

;
WITH FinishData AS
(
SELECT a.AssemblyPlanDetailID,a.OpDate,SUM(a.FinishSum)FinishSum FROM dbo.mx_PlanExBackNumMain a
GROUP BY a.AssemblyPlanDetailID,a.OpDate
)
INSERT INTO #TempResult
	        ( WorkOrder, CompleteQty )
	SELECT b.WorkOrder,SUM(ISNULL(a.FinishSum,0))FinishSum FROM FinishData a RIGHT JOIN #TempTable b ON a.AssemblyPlanDetailID=b.ID 
	WHERE  ISNULL(b.CompleteType,0)=0
	GROUP BY b.ID,b.WorkOrder

	INSERT INTO #TempResult
	SELECT t.WorkOrder,SUM(ISNULL(t.CompleteQty,0))CompleteQty
	FROM  (SELECT a.CompleteQty,b.WorkOrder,b.ID
	FROM dbo.mxqh_CompleteRpt a right JOIN #TempTable b ON a.WorkOrderID=b.ID 
	WHERE a.CompleteDate<@NowDate AND 	ISNULL(b.CompleteType,0)=1
	) t
	GROUP BY t.WorkOrder
	

;
WITH data1 AS--组装
(
SELECT a.AssemblyPlanDetailID,FORMAT(CONVERT(DATETIME,MIN(a.CreateDate)),'yyyy-MM-dd HH:mm')ActualStartDate
FROM dbo.opPlanExecutMain a 
GROUP BY a.AssemblyPlanDetailID
),
data2 AS--包装
(
SELECT a.AssemblyPlanDetailID,FORMAT(CONVERT(DATETIME,MIN(a.CreateDate)),'yyyy-MM-dd HH:mm')ActualStartDate
FROM dbo.opPlanExecutMainPK a 
GROUP BY a.AssemblyPlanDetailID
),
data3 AS--后焊
(
SELECT a.AssemblyPlanDetailID,FORMAT(CONVERT(DATETIME,MIN(a.CreateDate)),'yyyy-MM-dd HH:mm')ActualStartDate
FROM dbo.opPlanExecutMainHH a
GROUP BY a.AssemblyPlanDetailID
),
MOArrange AS
(
SELECT a.ArrangeDate,a.WorkOrder,b.HrUserName FROM dbo.mxqh_MoLineArrange a INNER JOIN dbo.mxqh_MoLineArrangeDtl b ON a.Id=b.ArrangeId
WHERE a.ArrangeDate=FORMAT(DATEADD(DAY,-1,@NowDate),'yyyy-MM-dd')
AND b.EmpType='L'
),
MOData AS
(
SELECT b.DocNo,b.DocState,SUM(ISNULL(c.CompleteQty,0))TotalCompleteQty,MIN(b.TotalStartQty)TotalStartQty FROM #TempResult a INNER JOIN [U9DATA].[AuctusERP].[dbo].[MO_MO] b ON a.WorkOrder=b.DocNo
LEFT JOIN  [U9DATA].[AuctusERP].[dbo].[MO_CompleteRpt] c ON b.ID=c.MO
GROUP BY b.ID,b.DocNo,b.DocState
)
SELECT a.*,b.Quantity,b.MaterialCode,b.MaterialName ,CONVERT(INT,ISNULL(m.TotalCompleteQty,0)) U9_TotalCompleteQty,CONVERT(INT,a.CompleteQty-ISNULL(m.TotalCompleteQty,0)) UnRcvQty,d.Name LineName,ISNULL(ar.HrUserName,hr.Name) HeadMan
,m.TotalCompleteQty,CONVERT(INT,m.TotalStartQty)TotalStartQty
,ISNULL(hh.ActualStartDate,ISNULL(assemb.ActualStartDate,pack.ActualStartDate))ActualStartDate
,ROW_NUMBER() OVER(ORDER BY b.WorkOrder)RN 
FROM #TempResult a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrder=b.WorkOrder 
INNER JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID INNER JOIN dbo.baAssemblyLine d ON c.AssemblyLineID=d.ID
LEFT JOIN dbo.hr_User hr ON d.UserID=hr.Id
LEFT JOIN MOArrange ar ON b.WorkOrder=ar.WorkOrder
LEFT JOIN MOData m ON b.WorkOrder=m.DocNo
LEFT JOIN data3 hh ON b.ID=hh.AssemblyPlanDetailID LEFT JOIN data1 assemb ON b.ID=assemb.AssemblyPlanDetailID LEFT JOIN data2 pack ON b.ID=pack.AssemblyPlanDetailID
WHERE ISNULL(m.TotalStartQty,0)<>ISNULL(m.TotalCompleteQty,0) AND m.DocState<>3
AND a.CompleteQty>ISNULL(m.TotalCompleteQty,0) AND b.Quantity>ISNULL(m.TotalCompleteQty,0)







END
