/*
ɾ������
1��ȷ��û��Ͷ����������opPackageChild��װ�ӱ�������
2��ɾ���������ݣ�ͬʱɾ��opPackageMain��opPackageDetail
3��ɾ���ɱ�plAssemblyPlanDetail����
*/
CREATE PROC sp_DeleteMesPlanDetail
(
@ID INT
)
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID 
	WHERE a.AssemblyPlanDetailID=@ID)
	BEGIN--�Ѿ�Ͷ��������ɾ��
		SELECT '�Ѿ�Ͷ��������ɾ����'Msg,'0' MsgType
	END
	ELSE
    BEGIN
		--ɾ����װ����
		DELETE FROM dbo.opPackageDetail WHERE PackMainID IN (SELECT ID FROM dbo.opPackageMain WHERE AssemblyPlanDetailID=@ID)
		--ɾ����װ����
		DELETE FROM dbo.opPackageMain WHERE AssemblyPlanDetailID=@ID
		--ɾ������
		DELETE FROM dbo.mxqh_plAssemblyPlanDetail WHERE ID=@ID
		SELECT 'ɾ���ɹ���'Msg,'1' MsgType
	END 


END 