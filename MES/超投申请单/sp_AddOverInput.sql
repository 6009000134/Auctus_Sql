/*
������Ͷ��
*/
alter PROC sp_AddOverInput
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		DECLARE @WorkOrderID INT		
		--Ͷ����С�ڹ�������������
		--INSERT INTO #TempTable1
		--EXEC dbo.sp_GetWorkOrderByID @WorkOrderID = 4092 -- int
		
		--ÿ����������ֻ��һ�ſɳ�Ͷ����˵���
		IF EXISTS(SELECT 1 FROM dbo.mxqh_OverInput a INNER JOIN #TempTable b ON a.WorkOrderID=b.WorkOrderID AND a.OverInputQty<>a.OverInputedQty)
		BEGIN
			SELECT '0'MsgType,'�ù��������볬Ͷ��'+(SELECT a.DocNo FROM dbo.mxqh_OverInput a INNER JOIN #TempTable b ON a.WorkOrderID=b.WorkOrderID AND a.OverInputQty<>a.OverInputedQty)+'δͶ���������ٴ����룡'Msg			
		END 
		ELSE 
		BEGIN
        	INSERT INTO dbo.mxqh_OverInput
		        ( CreateBy ,
		          CreateDate ,
		          DocNo ,
		          WorkOrderID ,
		          WorkOrder ,
		          OverInputQty ,
				  OverInputedQty,
		          Status ,
		          Reason
		        )
			SELECT a.CreateBy,GETDATE(),a.DocNo,a.WorkOrderID,a.WorkOrder,a.OverInputQty,0,0,a.Reason
			FROM #TempTable a
			SELECT '1'MsgType,'��ӳɹ���'Msg
		END 
	
	END 
	ELSE
		SELECT '0'MsgType,'���ʧ�ܣ�'Msg
END 

