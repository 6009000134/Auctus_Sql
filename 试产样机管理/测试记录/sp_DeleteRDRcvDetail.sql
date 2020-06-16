ALTER PROCEDURE [dbo].[sp_DeleteRDRcvDetail]
(
@SNCode VARCHAR(100),
@RcvID INT
)
AS
BEGIN
	--TODO:判断是否已经出库
	IF	ISNULL(@SNCode,'')=''
	BEGIN
		DELETE FROM dbo.TP_RDRcvDetail WHERE RcvID=@RcvID
		SELECT '1'MsgType,'清除成功！'Msg
	END 
	ELSE
    BEGIN
		DELETE FROM dbo.TP_RDRcvDetail WHERE RcvID=@RcvID AND SNCode=@SNCode
		SELECT '1'MsgType,'['+@SNCode+']删除成功！'Msg
	END 

END