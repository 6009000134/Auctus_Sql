/*
ɾ����������������
*/
CREATE PROC sp_TP_DeleteBCRcv
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_BCRcv  WHERE id=@ID
	DELETE FROM dbo.TP_BCRcvDetail WHERE RcvID=@ID
	SELECT '1'MsgType,'ɾ���ɹ�'Msg
END 