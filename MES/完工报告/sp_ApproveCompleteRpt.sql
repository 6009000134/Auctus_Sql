/*
审核完工报告
*/
ALTER PROCEDURE [dbo].[sp_ApproveCompleteRpt]
(
@DocNo VARCHAR(30),
@Status VARCHAR(10)
)
AS
BEGIN
	DECLARE @docState INT=(SELECT Status FROM dbo.mxqh_CompleteRpt WHERE DocNo=@DocNo)
	IF @Status='提交'--提交
	BEGIN
		IF @docState=0
		BEGIN 
			UPDATE dbo.mxqh_CompleteRpt SET Status=4 WHERE DocNo=@DocNo
			SELECT '1' MsgType,'提交成功！'Msg
		END 
		ELSE
        BEGIN
			SELECT '0' MsgType,'只有[开立]的单据才可以提交！'Msg	
		END 
	END 
	ELSE IF @Status='审批通过'
	BEGIN
		IF @docState=4
		BEGIN
			UPDATE dbo.mxqh_CompleteRpt SET Status=1 WHERE DocNo=@DocNo
			SELECT '1' MsgType,'审核成功！'Msg
		END 
		ELSE
        BEGIN
			SELECT '0' MsgType,'只有[开立]的单据才可以提交！'Msg	
		END 

	END 
	ELSE IF @Status='弃审'--弃审
	BEGIN
		IF @docState IN (1,3)
		BEGIN
			UPDATE dbo.mxqh_CompleteRpt SET Status=0 WHERE DocNo=@DocNo
			SELECT '1' MsgType,'弃审成功！'Msg
		END 
		ELSE
        BEGIN
			SELECT '0' MsgType,'只有[已核准\关闭]的单据才可以弃审！'Msg			
		END 
	END 
	ELSE
    BEGIN
		SELECT '0' MsgType,'不存在的操作，请联系管理员！'Msg    
	END 	
END