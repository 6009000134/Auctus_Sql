/*
ɾ����������������
*/
CREATE PROC sp_TP_DeleteBCShip
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_BCShip  WHERE id=@ID
	DELETE FROM dbo.TP_BCShipDetail WHERE ShipID=@ID
	SELECT '1'MsgType,'ɾ���ɹ�'Msg
END 