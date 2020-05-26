/*
删除测产品中心数据
*/
CREATE PROC sp_TP_DeletePCShip
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_PCShip  WHERE id=@ID
	DELETE FROM dbo.TP_PCShipDetail WHERE ShipID=@ID
	SELECT '1'MsgType,'删除成功'Msg
END 