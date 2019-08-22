/*
��ȡ��װ��ǩ��
������A��ERP���۶���=����B��ERP���۶���������A��װ��Ϣ��PackListNoȡ����B��װ��Ϣ��PackListNo
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