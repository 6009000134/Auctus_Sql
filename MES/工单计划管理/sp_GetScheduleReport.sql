USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetScheduleReport]    Script Date: 2021/7/21 11:00:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_GetScheduleReport]
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

--IF ISNULL(@SD,'')=''
--SET @SD='2000-01-01'
--IF ISNULL(@ED,'')=''
--SET @ED=DATEADD(DAY,7,GETDATE())

--SET @ED=DATEADD(DAY,1,@ED)

	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	;
	WITH PlanData AS
    (
	SELECT a.ID WorkOrderID,a.WorkOrder,b.AssemblyLineID,b.AssemblyLineName	
	FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.mxqh_plAssemblyPlan b ON a.AssemblyPlanID=b.ID 		
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
	SELECT *
	--,CASE WHEN ISNULL(t.TotalStartQty,0)>=ISNULL(t.TotalPlanCount,0)+ISNULL(t.PlanCount,0) THEN '是' ELSE '否'END IsKitting
	 FROM 
	(
	SELECT t.WorkOrder
	--,t.ProductQty,t.TotalStartQty,t.TotalCompleteQty,t.Code,t.Name,t.MRPCategoryName   ,t.MCName
   ,b.PlanDate MESDate,ISNULL(b.FinishSum,0)FinishSum,b.PlanCount,t.AssemblyLineName,b.TotalPlanCount
	,ROW_NUMBER() OVER(ORDER BY b.PlanDate desc,t.AssemblyLineName )RN
	FROM PlanData t INNER JOIN ScheduleData b ON t.WorkOrder=b.WorkOrder --OR t.WorkOrderID=b.AssemblyPlanDetailID
	WHERE (b.PlanDate>=CONVERT(NVARCHAR(10),@SD,120) OR @SD IS null) AND (b.PlanDate<CONVERT(NVARCHAR(10),@ED,120) OR @ED IS NULL)
	) t WHERE t.RN>@beginIndex AND t.RN<@endIndex



	--统计数量
	;
	WITH PlanData AS
    (
	SELECT a.ID WorkOrderID,a.WorkOrder,b.AssemblyLineID,b.AssemblyLineName	
	FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.mxqh_plAssemblyPlan b ON a.AssemblyPlanID=b.ID 	
	WHERE  ISNULL(@LineID,b.AssemblyLineID)=b.AssemblyLineID
	),
	ScheduleData AS
    (
	SELECT a.PlanDate,a.LineId,a.PlanCount,a.WorkOrder,b.FinishSum,b.OpDate,b.AssemblyPlanDetailID 
	FROM dbo.mxqh_MoPlanCount a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail m ON a.WorkOrder=m.WorkOrder
	LEFT JOIN dbo.mx_PlanExBackNumMain b ON a.PlanDate=FORMAT(ISNULL(b.OpDate,''),'yyyy-MM-dd') AND m.WorkOrder=a.WorkOrder AND m.ID=b.AssemblyPlanDetailID --AND ISNULL(b.FinishSum,0)>0 AND ISNULL(a.PlanCount,0)>0
	WHERE ISNULL(@LineID,ISNULL(a.LineId,0))=ISNULL(a.LineId,0)
	AND (a.PlanDate>=CONVERT(NVARCHAR(10),@SD,120) OR @SD IS null) AND (a.PlanDate<CONVERT(NVARCHAR(10),@ED,120) OR @ED IS NULL)
	--AND ISNULL(a.PlanCount,0)>0--排班数和完工数至少有1个大于0
	)
	SELECT COUNT(1) Count
	FROM PlanData t INNER JOIN ScheduleData b ON t.WorkOrder=b.WorkOrder --OR t.WorkOrderID=b.AssemblyPlanDetailID

END
