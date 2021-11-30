/*
销售样机归还(OA接口调用)
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
		SELECT '1'StatusCode,'当前单据不是和核准中状态，无法'+@Status ErrorMsg
	END 
	IF EXISTS(SELECT 1 FROM dbo.TP_RDRcv a,#TempTable b WHERE a.id=b.proid AND a.OAFlowID=b.OAFlowID)
	BEGIN			
		IF EXISTS(SELECT 1 FROM dbo.TP_RDRcvDetail a,#TempTable1 b WHERE a.id=b.LineID)
		BEGIN
			--更新入库单
			UPDATE dbo.TP_RDRcv SET Status=a.Status FROM #TempTable a WHERE a.proid=dbo.TP_RDRcv.ID
			--更新入库单行
			UPDATE dbo.TP_RDRcvDetail SET HardwareVersion=b.HardwareVersion,
			SoftwareVersion=b.SoftwareVersion,
			HardwareStatus=b.HardwareStatus,
			SoftwareStatus=b.SoftwareStatus,
			TestItems=b.TestItems,
			Progress=b.Progress,
			Status=b.Status FROM #TempTable1 b WHERE b.LineID=TP_RDRcvDetail.ID
			IF @Status='审批通过'
			BEGIN 
				SELECT '0'StatusCode,'审批成功！'ErrorMsg 	
			END 
			IF @Status='驳回'
			BEGIN
				SELECT '0'StatusCode,'驳回成功！'ErrorMsg 	
			END 
		END 
		ELSE
		BEGIN
			SELECT '1'StatusCode,'入库明细信息为空，请检查OA\或接口数据！！'ErrorMsg	 	
		END 
	END 
	ELSE
	BEGIN
		SELECT '1'StatusCode,'找不到对应流程的入库单！！'ErrorMsg 	
		--RAISERROR('找不到对应流程的入库单',16,1)
	END 
END
ELSE
BEGIN
		SELECT '1'StatusCode,'找不到对应流程的入库单！！'ErrorMsg 	
END 

END 





		
		



