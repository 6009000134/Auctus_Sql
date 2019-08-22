CREATE PROC sp_DeleteAssemblyLine
(
@ID INT
)
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlan a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.ID=b.AssemblyPlanID WHERE a.AssemblyLineID=@ID)
	BEGIN--被工单引用，不可删除		
		SELECT '生产线被工单引用，不可删除！'Msg,'0' MsgType
	END
	ELSE
    BEGIN
		--删除生产线
		DELETE FROM dbo.baAssemblyLine WHERE ID=@ID
		SELECT '删除成功！'Msg,'1' MsgType
	END 
END 