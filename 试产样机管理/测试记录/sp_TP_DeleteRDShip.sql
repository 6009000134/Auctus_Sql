/*
删除测试数据
*/
CREATE PROC sp_TP_DeleteRDShip
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_RDShip  WHERE id=@ID
	DELETE FROM dbo.TP_RDShipDetail WHERE ShipID=@ID
	SELECT '1'MsgType,'删除成功'Msg
END 