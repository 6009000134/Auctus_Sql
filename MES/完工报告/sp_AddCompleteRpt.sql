/*
新增完工报告
*/
ALTER PROC [dbo].[sp_AddCompleteRpt]
(
@CreateBy VARCHAR(30),
@ListNo VARCHAR(30),
@TotalStartQty INT
)
AS
BEGIN
	--DECLARE @CreateBy VARCHAR(30)
	--DECLARE @ListNo VARCHAR(30)
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		--校验是否有排班
		IF NOT EXISTS(SELECT 1 FROM dbo.mxqh_MoLineArrange a INNER JOIN #TempTable b ON a.WorkOrder=b.WorkOrder AND a.ArrangeDate=FORMAT(CONVERT(DATE,b.CompleteDate),'yyyy-MM-dd'))
		BEGIN			
			SELECT '0'MsgType,(SELECT FORMAT(CONVERT(DATE,CompleteDate),'yyyy-MM-dd') FROM #TempTable)+'没有此工单的排班，请补充当日排班数据！' Msg			
			RETURN;	
		END		
		--校验完工总数是否大于工单数量
		DECLARE @Mes_CompleteQty INT,@Quantity INT
		SELECT @Mes_CompleteQty=SUM(ISNULL(CompleteQty,0)),@Quantity=MIN(ISNULL(t1.Quantity,0)) FROM 
		(
		SELECT a.WorkOrderID,a.CompleteQty FROM #TempTable a
		UNION ALL
		SELECT b.WorkOrderID,b.CompleteQty FROM #TempTable a INNER JOIN dbo.mxqh_CompleteRpt b ON a.workorderid=b.WorkOrderID
		) t LEFT JOIN dbo.mxqh_plAssemblyPlanDetail t1 ON t.WorkOrderID=t1.ID 
		GROUP BY t.workorderID 
		IF @Mes_CompleteQty>@Quantity
        BEGIN
			SELECT '0'MsgType,'完工总数大于工单数量！' Msg			
			RETURN;
		END 
		ELSE IF @Mes_CompleteQty>@TotalStartQty
		BEGIN
			SELECT '0'MsgType,'工单完工总数大于U9开工数！' Msg			
			RETURN;
		END
        ELSE        
		BEGIN        	
			INSERT INTO dbo.mxqh_CompleteRpt
			        ( CreateBy ,
			          CreateDate ,
			          ModifyBy ,
			          ModifyDate ,
			          DocNo ,
			          DocType ,
			          DocTypeCode ,
			          DocTypeName ,
					  Status,
			          MaterialID ,
			          MaterialCode ,
			          MaterialName ,
			          WorkOrderID ,
			          WorkOrder ,
			          CompleteDate ,
			          CompleteQty 
			        )SELECT @CreateBy , -- CreateBy - nvarchar(30)
			          GETDATE() , -- CreateDate - datetime
			          @CreateBy , -- ModifyBy - nvarchar(30)
			          GETDATE() , -- ModifyDate - datetime
			          @ListNo , 
					  0 , -- DocType - bigint
			          '' , -- DocTypeCode - varchar(30)
			          N'' , -- DocTypeName - nvarchar(30)
					  0,
			          a.MaterialID, -- MaterialID - int
			          a.MaterialCode , -- MaterialCode - varchar(30)
			          a.MaterialName , -- MaterialName - nvarchar(30)
			          a.WorkOrderID , -- WorkOrderID - int
			          a.WorkOrder , -- WorkOrder - varchar(30)
			          a.CompleteDate , -- CompleteDate - datetime
			          a.CompleteQty
					  FROM #TempTable a
			SELECT '1'MsgType,'添加成功！' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'添加失败！' Msg
	END 
END 

