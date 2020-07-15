/*
新增超投单
*/
alter PROC sp_AddOverInput
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		DECLARE @WorkOrderID INT		
		--投入数小于工单数不可申请
		--INSERT INTO #TempTable1
		--EXEC dbo.sp_GetWorkOrderByID @WorkOrderID = 4092 -- int
		
		--每个工单有且只有一张可超投的审核单据
		IF EXISTS(SELECT 1 FROM dbo.mxqh_OverInput a INNER JOIN #TempTable b ON a.WorkOrderID=b.WorkOrderID AND a.OverInputQty<>a.OverInputedQty)
		BEGIN
			SELECT '0'MsgType,'该工单已申请超投单'+(SELECT a.DocNo FROM dbo.mxqh_OverInput a INNER JOIN #TempTable b ON a.WorkOrderID=b.WorkOrderID AND a.OverInputQty<>a.OverInputedQty)+'未投满！不能再次申请！'Msg			
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
			SELECT '1'MsgType,'添加成功！'Msg
		END 
	
	END 
	ELSE
		SELECT '0'MsgType,'添加失败！'Msg
END 

