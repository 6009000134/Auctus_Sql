/*
删除测商务中心数据
*/
CREATE PROC sp_TP_DeleteBCShip
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_BCShip  WHERE id=@ID
	DELETE FROM dbo.TP_BCShipDetail WHERE ShipID=@ID
	SELECT '1'MsgType,'删除成功'Msg
END 