/*
����������������|����
*/
ALTER  PROC sp_TP_SubmitApproveRDShip
(
@ID INT,
@Status VARCHAR(10),
@ModifyBy VARCHAR(10)
)
AS 
DECLARE @curState VARCHAR(10)
		DECLARE @ApplicantID VARCHAR(100)
SELECT @curState=Status FROM dbo.TP_RDShip a WHERE a.ID=@ID
IF @Status=1
BEGIN
	IF @curState='0'
	BEGIN 
		UPDATE dbo.TP_RDShip SET Status=@Status,ModifyBy=@ModifyBy,ModifyDate=GETDATE() WHERE ID=@ID
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
		UPDATE dbo.TP_RDShip SET Status=@Status,ModifyBy=@ModifyBy,ModifyDate=GETDATE() WHERE ID=@ID
		SET @ApplicantID=(SELECT applicantid FROM dbo.TP_RDShip WHERE ID=@ID)
		IF ISNULL(@ApplicantID,'')!=''
		BEGIN 
			UPDATE dbo.TP_SampleApplication SET ShipmentQty=ShipmentQty+(SELECT COUNT(1) FROM dbo.TP_RDShipDetail WHERE ShipID=@ID) WHERE OAFlowID=@ApplicantID
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
		UPDATE dbo.TP_RDShip SET Status=@Status,ModifyBy=@ModifyBy,ModifyDate=GETDATE() WHERE ID=@ID
		SET @ApplicantID=(SELECT applicantid FROM dbo.TP_RDShip WHERE ID=@ID)
		IF ISNULL(@ApplicantID,'')!=''
		BEGIN 
			UPDATE dbo.TP_SampleApplication SET ShipmentQty=ShipmentQty-(SELECT COUNT(1) FROM dbo.TP_RDShipDetail WHERE ShipID=@ID) WHERE OAFlowID=@ApplicantID
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



		
		



