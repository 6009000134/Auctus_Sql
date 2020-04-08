/*
计划排版报表
*/
ALTER PROC [dbo].[sp_GetScheduleReport]
(
@WorkOrder NVARCHAR(MAX)='',--MO-30200213001
@LineID INT,
@pageIndex INT,
@pageSize INT,
@SD DATE='2000-3-20',
@ED DATE='2020-4-2'
)
AS
BEGIN

--DECLARE @WorkOrder NVARCHAR(MAX)='3114',
--@LineID INT,
--@pageIndex INT,
--@pageSize INT,
--@SD DATE='2000-3-20',
--@ED DATE='2020-4-2'

IF ISNULL(@SD,'')=''
SET @SD='2000-01-01'
IF ISNULL(@ED,'')=''
SET @ED=DATEADD(DAY,7,GETDATE())

SET @ED=DATEADD(DAY,1,@ED)


IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
	--SELECT @WorkOrder W,@LineID L,@SD s,@ED e,@pageIndex i,@pageSize Si
	;
	WITH PlanData AS
    (
	SELECT a.ID WorkOrderID,a.WorkOrder,b.AssemblyLineID,b.AssemblyLineName	
	,t.ProductQty,t.TotalStartQty,t.TotalCompleteQty,t.Code,t.Name,t.MRPCategoryName
   ,t.MCName
	FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.mxqh_plAssemblyPlan b ON a.AssemblyPlanID=b.ID 		
	INNER JOIN #TempTable t ON a.WorkOrder=t.DocNo
	WHERE  ISNULL(@LineID,b.AssemblyLineID)=b.AssemblyLineID
	),
	ScheduleData AS
    (	
	SELECT a.PlanDate,a.LineId,a.PlanCount,a.WorkOrder,b.FinishSum,b.OpDate,b.AssemblyPlanDetailID 
	,ISNULL((SELECT SUM(ISNULL(t.PlanCount,0)) FROM dbo.mxqh_MoPlanCount t WHERE t.WorkOrder=a.WorkOrder AND a.PlanDate>t.PlanDate),0)TotalPlanCount
	FROM dbo.mxqh_MoPlanCount a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail m ON a.WorkOrder=m.WorkOrder
	LEFT JOIN dbo.mx_PlanExBackNumMain b ON a.PlanDate=FORMAT(ISNULL(b.OpDate,''),'yyyy-MM-dd') AND m.WorkOrder=a.WorkOrder AND m.ID=b.AssemblyPlanDetailID --AND ISNULL(b.FinishSum,0)>0 AND ISNULL(a.PlanCount,0)>0
	WHERE ISNULL(@LineID,ISNULL(a.LineId,0))=ISNULL(a.LineId,0)
	--AND a.ArrangeDate>=@SD AND a.ArrangeDate<@ED
	--AND ISNULL(a.PlanCount,0)>0--排班数和完工数至少有1个大于0
	)
	SELECT *,CASE WHEN ISNULL(t.TotalStartQty,0)>=ISNULL(t.TotalPlanCount,0)+ISNULL(t.PlanCount,0) THEN '是' ELSE '否'END IsKitting FROM (
	SELECT t.WorkOrder,t.ProductQty,t.TotalStartQty,t.TotalCompleteQty,t.Code,t.Name,t.MRPCategoryName
   ,t.MCName,b.PlanDate MESDate,ISNULL(b.FinishSum,0)FinishSum,b.PlanCount,t.AssemblyLineName,b.TotalPlanCount
	,ROW_NUMBER() OVER(ORDER BY b.PlanDate asc,t.AssemblyLineName )RN
	FROM PlanData t INNER JOIN ScheduleData b ON t.WorkOrder=b.WorkOrder --OR t.WorkOrderID=b.AssemblyPlanDetailID
	WHERE b.PlanDate>=@SD AND b.PlanDate<@ED
	) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

	--统计数量
	;
	WITH PlanData AS
    (
	SELECT a.ID WorkOrderID,a.WorkOrder,b.AssemblyLineID,b.AssemblyLineName	
	,t.ProductQty,t.TotalStartQty,t.TotalCompleteQty,t.Code,t.Name,t.MRPCategoryName
   ,t.MCName
	FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.mxqh_plAssemblyPlan b ON a.AssemblyPlanID=b.ID 		
	INNER JOIN #TempTable t ON a.WorkOrder=t.DocNo
	WHERE  ISNULL(@LineID,b.AssemblyLineID)=b.AssemblyLineID
	),
	ScheduleData AS
    (
	SELECT a.PlanDate,a.LineId,a.PlanCount,a.WorkOrder,b.FinishSum,b.OpDate,b.AssemblyPlanDetailID 
	FROM dbo.mxqh_MoPlanCount a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail m ON a.WorkOrder=m.WorkOrder
	LEFT JOIN dbo.mx_PlanExBackNumMain b ON a.PlanDate=FORMAT(ISNULL(b.OpDate,''),'yyyy-MM-dd') AND m.WorkOrder=a.WorkOrder AND m.ID=b.AssemblyPlanDetailID --AND ISNULL(b.FinishSum,0)>0 AND ISNULL(a.PlanCount,0)>0
	WHERE ISNULL(@LineID,ISNULL(a.LineId,0))=ISNULL(a.LineId,0)
	AND a.PlanDate>=@SD AND a.PlanDate<@ED
	--AND ISNULL(a.PlanCount,0)>0--排班数和完工数至少有1个大于0
	)
	SELECT COUNT(1) Count
	FROM PlanData t INNER JOIN ScheduleData b ON t.WorkOrder=b.WorkOrder --OR t.WorkOrderID=b.AssemblyPlanDetailID
END 
ELSE
BEGIN
	SELECT '0' MsgType,'失败'Msg
END 

END 