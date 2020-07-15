/*
超投单列表
*/
ALTER  PROC sp_GetOverInputList
(
@WorkOrder VARCHAR(100),
@Status VARCHAR(100),
@pageSize INT,
@pageIndex INT
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
	SELECT * FROM (
	SELECT a.*,b.MaterialCode,b.MaterialName,b.Quantity
	,(SELECT SUM(t.OverInputedQty) FROM dbo.mxqh_OverInput t WHERE t.WorkOrderID=a.WorkOrderID)TotalOverInputedQty
	,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RowNum
	FROM dbo.mxqh_OverInput  a LEFT JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
	WHERE PATINDEX(@WorkOrder,b.WorkOrder)>0
	AND ISNULL(@Status,a.Status)=a.Status
	) t WHERE t.RowNum>@beginIndex AND t.RowNum<@endIndex

	SELECT COUNT(1)Count
	FROM dbo.mxqh_OverInput  a LEFT JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.WorkOrderID=b.ID
	WHERE PATINDEX(@WorkOrder,b.WorkOrder)>0
	AND ISNULL(@Status,a.Status)=a.Status
END 

