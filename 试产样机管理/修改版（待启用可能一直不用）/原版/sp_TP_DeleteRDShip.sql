USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_TP_DeleteRDShip]    Script Date: 2022/6/13 10:04:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
删除测试数据
*/
ALTER PROC [dbo].[sp_TP_DeleteRDShip]
(
@ID int
)
AS
BEGIN
	DELETE FROM dbo.TP_RDShip  WHERE id=@ID
	DELETE FROM dbo.TP_RDShipDetail WHERE ShipID=@ID
	SELECT '1'MsgType,'删除成功'Msg
END 