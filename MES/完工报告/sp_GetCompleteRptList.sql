/*
获取完工报告列表
*/
ALTER PROC sp_GetCompleteRptList
(
@WorkOrder VARCHAR(30),
@pageIndex INT=1,
@pageSize INT =10,
@StartDate DATETIME='2000-01-01',
@EndDate DATETIME='9999-01-01'
)
as
BEGIN
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT=@pageSize*@pageIndex+1
SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
IF	ISNULL(@StartDate,'')=''
SET @StartDate='2000-01-01'
IF	ISNULL(@EndDate,'')=''
SET @EndDate='9999-01-01'
SELECT * FROM (
SELECT a.ID,a.CreateBy,a.CreateDate,a.ModifyBy,a.ModifyDate,a.DocNo,a.MaterialID,a.MaterialCode,a.MaterialName 
,a.WorkOrderID,a.WorkOrder,a.CompleteDate,a.CompleteQty,a.ActualRcvQty,b.Quantity
,c.AssemblyLineID,d.Name,m.UPPH,b.TotalStartQty
,ROW_NUMBER()OVER(ORDER BY a.CreateDate desc) RN
FROM dbo.mxqh_CompleteRpt a  LEFT JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
LEFT JOIN dbo.mxqh_plAssemblyPlan c ON b.AssemblyPlanID=c.ID LEFT JOIN dbo.baAssemblyLine d ON c.AssemblyLineID=d.ID
LEFT JOIN dbo.mxqh_Material m ON a.MaterialID=m.Id
WHERE  PATINDEX(@WorkOrder,a.WorkOrder)>0 AND a.CompleteDate BETWEEN @StartDate AND @EndDate
)t WHERE t.RN>@beginIndex AND t.RN<@endIndex
SELECT COUNT(1)Count
FROM dbo.mxqh_CompleteRpt a 
WHERE  PATINDEX(@WorkOrder,a.WorkOrder)>0 AND a.CompleteDate BETWEEN @StartDate AND @EndDate

END 