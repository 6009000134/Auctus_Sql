/*
删除完工报告
*/
ALTER   PROC sp_DeleteCompleteRpt
(
@ID INT,
@CompleteQty INT
)
AS
BEGIN
			DECLARE @WorkOrder VARCHAR(50)=''
			SELECT @WorkOrder=a.WorkOrder FROM dbo.mxqh_CompleteRpt a WHERE a.ID=@ID
			
			--检验删除后功完工数量是否小于U9中已经录入的完工数量
			--IF (SELECT SUM(a.CompleteQty) FROM dbo.mxqh_CompleteRpt a WHERE a.WorkOrderID=(SELECT b.WorkOrderID FROM dbo.mxqh_CompleteRpt b WHERE b.ID=@ID))<@CompleteQty
			--BEGIN
			--	SELECT '0'MsgType,'删除后工单完工数量小于U9已经录入的完工数量：'+CONVERT(VARCHAR(50),@CompleteQty) Msg
			--	RETURN;
			--END   
			UPDATE dbo.op_IPQCMain SET U9InDocNo='',IsToU9=0,ToU9TS=NULL,InStorageTS=NULL,IsInStorage=0
			FROM dbo.mxqh_CompleteRpt a WHERE a.ID=@ID AND dbo.op_IPQCMain.U9InDocNo=a.DocNo
			DELETE FROM dbo.mxqh_CompleteRpt WHERE ID=@ID
			SELECT '1'MsgType,'删除成功！' Msg
END 

