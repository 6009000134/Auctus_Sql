/*
完工报告审核
*/
ALTER  PROC sp_ApproveCompleteRpt
(
@DocNo VARCHAR(30)
)
AS
BEGIN
	--TODO:校验逻辑
	UPDATE dbo.mxqh_CompleteRpt SET Status=2 WHERE DocNo=@DocNo
	SELECT '1' MsgType,'审核通过！'Msg
END 