/*
���������黹(OA�ӿڵ���)
*/
ALTER PROC sp_TP_ReturnRDRcv4OA
(
@Status VARCHAR(10)
)
AS 
BEGIN 
IF EXISTS ( SELECT  1 FROM    tempdb.dbo.sysobjects WHERE   id = OBJECT_ID(N'TEMPDB..#TempTable') AND type = 'U')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM dbo.TP_RDRcv a ,#TempTable b WHERE a.id=b.proid AND a.OAFlowID=b.OAFlowID AND a.Status=1)
	BEGIN
		SELECT '1'StatusCode,'��ǰ���ݲ��Ǻͺ�׼��״̬���޷�'+@Status ErrorMsg
	END 
	IF EXISTS(SELECT 1 FROM dbo.TP_RDRcv a,#TempTable b WHERE a.id=b.proid AND a.OAFlowID=b.OAFlowID)
	BEGIN			
		IF EXISTS(SELECT 1 FROM dbo.TP_RDRcvDetail a,#TempTable1 b WHERE a.id=b.LineID)
		BEGIN
			--������ⵥ
			UPDATE dbo.TP_RDRcv SET Status=a.Status FROM #TempTable a WHERE a.proid=dbo.TP_RDRcv.ID
			--������ⵥ��
			UPDATE dbo.TP_RDRcvDetail SET HardwareVersion=b.HardwareVersion,
			SoftwareVersion=b.SoftwareVersion,
			HardwareStatus=b.HardwareStatus,
			SoftwareStatus=b.SoftwareStatus,
			TestItems=b.TestItems,
			Progress=b.Progress,
			Status=b.Status FROM #TempTable1 b WHERE b.LineID=TP_RDRcvDetail.ID
			IF @Status='����ͨ��'
			BEGIN 
				SELECT '0'StatusCode,'�����ɹ���'ErrorMsg 	
			END 
			IF @Status='����'
			BEGIN
				SELECT '0'StatusCode,'���سɹ���'ErrorMsg 	
			END 
		END 
		ELSE
		BEGIN
			SELECT '1'StatusCode,'�����ϸ��ϢΪ�գ�����OA\��ӿ����ݣ���'ErrorMsg	 	
		END 
	END 
	ELSE
	BEGIN
		SELECT '1'StatusCode,'�Ҳ�����Ӧ���̵���ⵥ����'ErrorMsg 	
		--RAISERROR('�Ҳ�����Ӧ���̵���ⵥ',16,1)
	END 
END
ELSE
BEGIN
		SELECT '1'StatusCode,'�Ҳ�����Ӧ���̵���ⵥ����'ErrorMsg 	
END 

END 





		
		



