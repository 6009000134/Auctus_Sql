/*
ɾ����������������
*/
ALTER  PROC sp_TP_DeleteBCShip
(
@ID INT
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.TP_RDRcv a WHERE a.ID=@ID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'���ݲ��ǿ���״̬������ɾ����'Msg		
	END 
	ELSE 
		DELETE FROM dbo.TP_BCShip  WHERE id=@ID
		DELETE FROM dbo.TP_BCShipDetail WHERE ShipID=@ID
		SELECT '1'MsgType,'ɾ���ɹ�'Msg
	END 
END 