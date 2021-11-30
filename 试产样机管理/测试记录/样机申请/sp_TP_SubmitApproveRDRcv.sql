/*
���������������|����
*/
ALTER  PROC sp_TP_SubmitApproveRDRcv
(
@ID INT,
@Status VARCHAR(10),
@ModifyBy VARCHAR(10),
@OAFlowID VARCHAR(20)
)
AS 
DECLARE @curState VARCHAR(10),@DocType VARCHAR(20),@ApplicantID VARCHAR(100)
SELECT @DocType=doctype,@ApplicantID=ApplicantID FROM dbo.TP_RDRcv WHERE ID=@ID

SELECT @curState=Status FROM dbo.TP_RDRcv a WHERE a.ID=@ID
IF @Status=1
BEGIN
	IF @curState='0'
	BEGIN 
		UPDATE dbo.TP_RDRcv SET Status=@Status,ModifyBy=@ModifyBy,ModifyDate=GETDATE(),OAFlowID=ISNULL(@OAFlowID,'') WHERE ID=@ID
		SELECT '0'StatusCode,'�ύ�ɹ���'ErrorMsg
	END 
	ELSE
	BEGIN 
		SELECT '1'StatusCode,'���ݲ��ǿ���״̬�������ύ��'ErrorMsg	
	END
    
END 
ELSE IF @Status=2
BEGIN
	IF @curState='1'
	BEGIN 
		UPDATE dbo.TP_RDRcv SET Status=@Status,ModifyBy=@ModifyBy,ModifyDate=GETDATE() WHERE ID=@ID
		IF @DocType='���������黹'--�������뵥�Ĺ黹����
		BEGIN
			UPDATE dbo.TP_SampleApplication SET ReturnQuantity=ReturnQuantity+(SELECT COUNT(1) FROM dbo.TP_RDRcvDetail WHERE RcvID=@ID) WHERE OAFlowID=@ApplicantID
		END 
		SELECT '0'StatusCode,'�����ɹ���'ErrorMsg
	END 
	ELSE
	BEGIN 
		SELECT '1'StatusCode,'���ݲ��������״̬��������ˣ�'ErrorMsg	
	END
END 
ELSE IF @Status=0
BEGIN
	IF @curState='2'
	BEGIN 
		UPDATE dbo.TP_RDRcv SET Status=@Status,ModifyBy=@ModifyBy,ModifyDate=GETDATE(),OAFlowID='' WHERE ID=@ID
		IF @DocType='���������黹'--�������뵥�Ĺ黹����
		BEGIN
			UPDATE dbo.TP_SampleApplication SET ReturnQuantity=ReturnQuantity-(SELECT COUNT(1) FROM dbo.TP_RDRcvDetail WHERE RcvID=@ID) WHERE OAFlowID=@ApplicantID
		END 
		SELECT '0'StatusCode,'����ɹ���'ErrorMsg
	END 
	ELSE
	BEGIN 
		SELECT '1'StatusCode,'���ݲ��������״̬����������'ErrorMsg	
	END
END 
ELSE 
BEGIN
	SELECT '1'StatusCode,'δ֪�ĵ���״̬'+@curState ErrorMsg
END 



		
		



