/*
ɾ���������༰�½׷���
*/
ALTER  PROC sp_DeleteSyQPoor
(
@ID INT
)
AS
BEGIN
	DELETE FROM dbo.syQPoor WHERE ID=@ID
	DELETE FROM dbo.syQPoor WHERE PID=@ID
	SELECT '1'MsgType,'ɾ���ɹ���' Msg							
END 
