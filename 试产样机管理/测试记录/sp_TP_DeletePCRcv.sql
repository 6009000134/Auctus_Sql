/*
ɾ�����Ʒ��������
*/
CREATE PROC sp_TP_DeletePCRcv
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_PCRcv  WHERE id=@ID
	DELETE FROM dbo.TP_PCRcvDetail WHERE RcvID=@ID
	SELECT '1'MsgType,'ɾ���ɹ�'Msg
END 