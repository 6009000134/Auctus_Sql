/*
获取工单包装信息
*/
ALTER PROC sp_GetPackInfo
(
@AssemblyPlanDetailID INT
)
AS
BEGIN

	SELECT 
	a.*,b.WorkOrder,(SELECT MIN(BoxNumber) FROM dbo.opPackageDetail t WHERE t.PackMainID=a.ID)StartNo
	,(SELECT MAX(BoxNumber) FROM dbo.opPackageDetail t WHERE t.PackMainID=a.ID)EndNo
	FROM dbo.opPackageMain a  INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
	WHERE a.AssemblyPlanDetailID=@AssemblyPlanDetailID
END 
	