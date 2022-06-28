USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_DeleteRDRcvDetail]    Script Date: 2022/6/13 10:02:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_DeleteRDRcvDetail]
(
@SNCode VARCHAR(100),
@RcvID INT
)
AS
BEGIN
	--TODO:判断是否已经出库
	IF EXISTS (SELECT 1 FROM dbo.TP_RDRcv a WHERE a.ID=@RcvID AND a.Status!='0')
	BEGIN 
		SELECT '0'MsgType,'单据不是开立状态，不可删除！'Msg		
	END 
	ELSE 
	BEGIN
		IF	ISNULL(@SNCode,'')=''--只传ID，说明是清空说有明细
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
END