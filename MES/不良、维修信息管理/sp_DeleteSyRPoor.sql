/*
ɾ��ά�޷��༰�½׷���
*/
create  PROC sp_DeleteSyRPoor
(
@ID INT
)
AS
BEGIN
	DELETE FROM dbo.syRPoor WHERE ID=@ID
	DELETE FROM dbo.syRPoor WHERE PID=@ID
	SELECT '1'MsgType,'ɾ���ɹ���' Msg							
END 
