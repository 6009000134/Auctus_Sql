/*
������Ͷ��
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
--set @error_mes='�����Ǵ���������ʾ��'  
--raiserror(@error_mes,16,1)  
	SET @Status=LTRIM(@Status)
	SET @Status=RTRIM(@Status)
	--ע��StatusCode 0Ϊ�ɹ�,1Ϊʧ��
	IF EXISTS(SELECT 1 FROM dbo.mxqh_OverInput a WHERE a.DocNo=@DocNo)
	BEGIN
		IF ISNULL(@Status,'')='����ͨ��'
		BEGIN
			UPDATE dbo.mxqh_OverInput SET Status=2,ModifyBy=@ModifyBy,ModifyDate=GETDATE() WHERE DocNo=@DocNo
			SELECT '0'StatusCode,'�����ɹ���'ErrorMsg		 	
		END 
		ELSE IF ISNULL(@Status,'')='����'
		BEGIN
			UPDATE dbo.mxqh_OverInput SET Status=0,ModifyBy=@ModifyBy,ModifyDate=GETDATE() WHERE DocNo=@DocNo
			SELECT '0'StatusCode,@DocNo+'���سɹ���'ErrorMsg
		END 
		ELSE IF ISNULL(@Status,'')='�ύ'
		BEGIN
			UPDATE dbo.mxqh_OverInput SET Status=1,ModifyBy=@ModifyBy,Submiter=@ModifyBy,ModifyDate=GETDATE() WHERE DocNo=@DocNo
			SELECT '0'StatusCode,@DocNo+'���ύ��OA������'ErrorMsg
		END 
		ELSE
        BEGIN
			SELECT '1'StatusCode,'OA�������ĵ���״̬Ϊ�գ��޷�����mes����״̬'ErrorMsg
		END 
	END 
	ELSE
    BEGIN
		SELECT '1'StatusCode,'MESϵͳ���Ҳ������ţ�'+ISNULL(@DocNo,'')+'�Ĺ���' ErrorMsg
	END 
END

