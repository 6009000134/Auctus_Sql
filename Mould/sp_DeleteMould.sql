/*
ɾ��ģ���Ϻţ�Deleted=1���ʾ��ɾ��
*/
Alter PROC sp_DeleteMould
(
@ID INT
)
AS
BEGIN
	UPDATE dbo.Mould SET Deleted=1 WHERE ID=@ID
	SELECT '1'MsgType,'ɾ���ɹ���'Msg
END 