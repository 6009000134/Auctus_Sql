/*
�����깤�᰸
1�������깤ʱ��
2��ͬ���깤ʱ�䵽�ɱ�
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