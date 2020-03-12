/*
获取工单累计完工数量
*/
ALTER PROC sp_GetTotalCompleteQty
(
@WorkOrderID int
)
AS
BEGIN
	--DECLARE @WorkOrderID INT

	--判断料品、工单是否有工艺
	IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.AssemblyPlanDetailID=@WorkOrderID)--有工艺工单，完工数量查最后一个工序数据
	BEGIN	
			--完工信息
		SELECT ISNULL(COUNT(t.IsPass),0)CompleteQty FROM 
		(
		SELECT c.IsPass,ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY c.OrderNum desc)RN
		FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.opPlanExecutDetail c ON a.ID=c.PlanExecutMainID
		WHERE b.ID=@WorkOrderID AND c.ExtendOne=0
		) t WHERE t.RN=1 AND t.IsPass=1	
	END 
	ELSE--没工艺工单，完工数量查完工报告
	BEGIN
		SELECT ISNULL(SUM(a.CompleteQty),0)CompleteQty FROM dbo.mxqh_CompleteRpt a WHERE a.WorkOrderID=@WorkOrderID
	END 
END 