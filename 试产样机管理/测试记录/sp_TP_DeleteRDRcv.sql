/*
ɾ����������
*/
alter PROC sp_TP_DeleteRDRcv
(
@ID int
)
AS
BEGIN
	--SN����״̬������ɾ��
	IF EXISTS(SELECT * FROM dbo.TP_RDRcv a WHERE a.id=@ID AND a.Status!=0)
	BEGIN
		SELECT '0'MsgType,'���ݲ��ǿ���״̬������ɾ����'Msg
	END 
	ELSE
    BEGIN
		DELETE FROM dbo.TP_RDRcv  WHERE id=@ID
		DELETE FROM dbo.TP_RDRcvDetail WHERE RcvID=@ID
		SELECT '1'MsgType,'ɾ���ɹ�'Msg
	END 
	
END 