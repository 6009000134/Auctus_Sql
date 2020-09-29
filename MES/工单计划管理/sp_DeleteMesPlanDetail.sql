/*
删除工单
1、确保没有投入生产，即opPackageChild包装子表无数据
2、删除工单数据，同时删除opPackageMain，opPackageDetail
3、删除旧表plAssemblyPlanDetail数据
*/
CREATE PROC sp_DeleteMesPlanDetail
(
@ID INT
)
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID 
	WHERE a.AssemblyPlanDetailID=@ID)
	BEGIN--已经投产，不可删除
		SELECT '已经投产，不可删除！'Msg,'0' MsgType
	END
	ELSE
    BEGIN
		--删除包装详情
		DELETE FROM dbo.opPackageDetail WHERE PackMainID IN (SELECT ID FROM dbo.opPackageMain WHERE AssemblyPlanDetailID=@ID)
		--删除包装主表
		DELETE FROM dbo.opPackageMain WHERE AssemblyPlanDetailID=@ID
		--删除工单
		DELETE FROM dbo.mxqh_plAssemblyPlanDetail WHERE ID=@ID
		SELECT '删除成功！'Msg,'1' MsgType
	END 


END 