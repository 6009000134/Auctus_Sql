/*
ɾ���깤����
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
			
			--����ɾ�����깤�����Ƿ�С��U9���Ѿ�¼����깤����
			--IF (SELECT SUM(a.CompleteQty) FROM dbo.mxqh_CompleteRpt a WHERE a.WorkOrderID=(SELECT b.WorkOrderID FROM dbo.mxqh_CompleteRpt b WHERE b.ID=@ID))<@CompleteQty
			--BEGIN
			--	SELECT '0'MsgType,'ɾ���󹤵��깤����С��U9�Ѿ�¼����깤������'+CONVERT(VARCHAR(50),@CompleteQty) Msg
			--	RETURN;
			--END   
			UPDATE dbo.op_IPQCMain SET U9InDocNo='',IsToU9=0,ToU9TS=NULL,InStorageTS=NULL,IsInStorage=0
			FROM dbo.mxqh_CompleteRpt a WHERE a.ID=@ID AND dbo.op_IPQCMain.U9InDocNo=a.DocNo
			DELETE FROM dbo.mxqh_CompleteRpt WHERE ID=@ID
			SELECT '1'MsgType,'ɾ���ɹ���' Msg
END 

