/*
ɾ����������
*/
alter PROC sp_TP_DeleteRDRcv
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_RDRcv  WHERE id=@ID
	DELETE FROM dbo.TP_RDRcvDetail WHERE RcvID=@ID
	SELECT '1'MsgType,'ɾ���ɹ�'Msg
END 