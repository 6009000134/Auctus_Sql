/*
ɾ����������������
*/
ALTER PROC sp_TP_DeleteBCRcv
(
@ID int
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.TP_RDRcv a WHERE a.ID=@ID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'���ݲ��ǿ���״̬������ɾ����'Msg		
	END 
	ELSE 
		DELETE FROM dbo.TP_BCRcv  WHERE id=@ID
		DELETE FROM dbo.TP_BCRcvDetail WHERE RcvID=@ID
		SELECT '1'MsgType,'ɾ���ɹ�'Msg
	END 
END 