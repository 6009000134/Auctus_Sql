/*
工单完工结案
1、更新完工时间
2、同步完工时间到旧表
*/
ALTER PROC sp_MesPlanComplete
(
@ID INT
)
AS
BEGIN
	UPDATE dbo.mxqh_plAssemblyPlanDetail SET CompleteDate=GETDATE(),Status=4 WHERE ID=@ID
	UPDATE dbo.plAssemblyPlanDetail SET ExtendOne=GETDATE() WHERE ID=@ID
END 