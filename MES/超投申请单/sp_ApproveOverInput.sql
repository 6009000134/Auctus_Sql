/*
审批超投单
*/
ALTER  PROC sp_ApproveOverInput
(
@DocNo VARCHAR(100),
@OAFlowID VARCHAR(100),
@ModifyBy varchar(100),
@Status VARCHAR(100),
@Remark VARCHAR(2000)
)
AS
BEGIN
--	declare @error_mes varchar(1000)  
--set @error_mes='这里是错误描述的示例'  
--raiserror(@error_mes,16,1)  
	SET @Status=LTRIM(@Status)
	SET @Status=RTRIM(@Status)
	--注：StatusCode 0为成功,1为失败
	IF EXISTS(SELECT 1 FROM dbo.mxqh_OverInput a WHERE a.DocNo=@DocNo)
	BEGIN
		IF ISNULL(@Status,'')='审批通过'
		BEGIN
			UPDATE dbo.mxqh_OverInput SET Status=2,ModifyBy=@ModifyBy,ModifyDate=GETDATE() WHERE DocNo=@DocNo
			SELECT '0'StatusCode,'审批成功！'ErrorMsg		 	
		END 
		ELSE IF ISNULL(@Status,'')='驳回'
		BEGIN
			UPDATE dbo.mxqh_OverInput SET Status=0,ModifyBy=@ModifyBy,ModifyDate=GETDATE() WHERE DocNo=@DocNo
			SELECT '0'StatusCode,@DocNo+'驳回成功！'ErrorMsg
		END 
		ELSE IF ISNULL(@Status,'')='提交'
		BEGIN
			UPDATE dbo.mxqh_OverInput SET Status=1,ModifyBy=@ModifyBy,Submiter=@ModifyBy,ModifyDate=GETDATE() WHERE DocNo=@DocNo
			SELECT '0'StatusCode,@DocNo+'已提交到OA审批！'ErrorMsg
		END 
		ELSE
        BEGIN
			SELECT '1'StatusCode,'OA传过来的单据状态为空，无法更新mes单据状态'ErrorMsg
		END 
	END 
	ELSE
    BEGIN
		SELECT '1'StatusCode,'MES系统中找不到单号：'+ISNULL(@DocNo,'')+'的工单' ErrorMsg
	END 
END

