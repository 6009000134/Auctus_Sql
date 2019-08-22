/*
删除变更单
*/
ALTER PROC sp_DeleteMouldModify
(
@DocNo VARCHAR(50)
)
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.MouldModify WHERE Status=0 AND DocNo=@DocNo)
	BEGIN
		DELETE FROM dbo.MouldModifySeg WHERE ModifyID IN (SELECT ID FROM dbo.MouldModify WHERE DocNo=@DocNo)
		DELETE FROM dbo.MouldModify WHERE DocNo=@DocNo
		SELECT '1'MsgType,'删除成功！'	Msg
	END 
	ELSE IF EXISTS(SELECT 1 FROM dbo.MouldModify WHERE Status=1 AND DocNo=@DocNo)
    BEGIN
		SELECT '0'MsgType,'订单已审核，不可删除！'	Msg
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'不存在此订单！'	Msg
	END 
	
END 