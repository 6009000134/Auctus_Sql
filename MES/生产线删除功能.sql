CREATE PROC sp_DeleteAssemblyLine
(
@ID INT
)
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.mxqh_plAssemblyPlan a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.ID=b.AssemblyPlanID WHERE a.AssemblyLineID=@ID)
	BEGIN--���������ã�����ɾ��		
		SELECT '�����߱��������ã�����ɾ����'Msg,'0' MsgType
	END
	ELSE
    BEGIN
		--ɾ��������
		DELETE FROM dbo.baAssemblyLine WHERE ID=@ID
		SELECT 'ɾ���ɹ���'Msg,'1' MsgType
	END 
END 