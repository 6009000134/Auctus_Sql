/*
ɾ����������
*/
ALTER PROC sp_TP_DeleteRDShip
(
@ID int
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.TP_RDShip a WHERE a.ID=@ID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'���ݲ��ǿ���״̬������ɾ����'Msg		
	END 
	ELSE 
	BEGIN
		DELETE FROM dbo.TP_RDShip  WHERE id=@ID
		DELETE FROM dbo.TP_RDShipDetail WHERE ShipID=@ID
		SELECT '1'MsgType,'ɾ���ɹ�'Msg
	END 
END 