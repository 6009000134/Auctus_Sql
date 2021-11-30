/*
删除测试数据
*/
alter PROC sp_TP_DeleteRDRcv
(
@ID int
)
AS
BEGIN
	--SN出库状态，不可删除
	IF EXISTS(SELECT * FROM dbo.TP_RDRcv a WHERE a.id=@ID AND a.Status!=0)
	BEGIN
		SELECT '0'MsgType,'单据不是开立状态，不可删除！'Msg
	END 
	ELSE
    BEGIN
		DELETE FROM dbo.TP_RDRcv  WHERE id=@ID
		DELETE FROM dbo.TP_RDRcvDetail WHERE RcvID=@ID
		SELECT '1'MsgType,'删除成功'Msg
	END 
	
END 