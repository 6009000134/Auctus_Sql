/*
ɾ����������
*/
ALTER  PROC sp_TP_DeleteTestRecord
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_TestRecord  WHERE id=@ID
	DELETE FROM dbo.TP_TestDetail WHERE TestRecordID=@ID
	SELECT '1'MsgType,'ɾ���ɹ�'Msg
END 