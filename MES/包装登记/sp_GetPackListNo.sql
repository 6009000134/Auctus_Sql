/*
获取包装标签号
当工单A的ERP销售订单=工单B的ERP销售订单，工单A包装信息的PackListNo取工单B包装信息的PackListNo
*/
alter PROC sp_GetPackListNo
(
@MoID int
)
AS
BEGIN
	SELECT TOP 1 a.CustomerOrder,ISNULL(d.PackListNo,'')PackListNo
	FROM dbo.mxqh_plAssemblyPlanDetail a LEFT JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.ERPSO=b.ERPSO AND ISNULL(b.ERPSO,'')<>''
	LEFT JOIN dbo.opPackageMain c ON a.ID=c.AssemblyPlanDetailID LEFT JOIN dbo.opPackageMain d ON b.ID=d.AssemblyPlanDetailID
	WHERE a.ID=@MoID
END 