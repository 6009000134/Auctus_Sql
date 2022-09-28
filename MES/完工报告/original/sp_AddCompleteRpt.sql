USE [au_mes]
GO
/****** Object:  StoredProcedure [dbo].[sp_AddCompleteRpt]    Script Date: 2022/8/1 16:00:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
新增完工报告
*/
ALTER PROC [dbo].[sp_AddCompleteRpt]
(
@CreateBy VARCHAR(30),
@ListNo VARCHAR(30),
@TotalStartQty INT,
@IsToU9 BIT
)
AS
BEGIN
	--DECLARE @CreateBy VARCHAR(30)
	--DECLARE @ListNo VARCHAR(30)
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		DECLARE @WorkOrderID INT =(SELECT id FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN #TempTable b ON a.WorkOrder=b.WorkOrder)
		----校验是否有排班
		--IF NOT EXISTS(SELECT 1 FROM dbo.mxqh_MoLineArrange a INNER JOIN #TempTable b ON a.WorkOrder=b.WorkOrder AND a.ArrangeDate=FORMAT(CONVERT(DATE,b.CompleteDate),'yyyy-MM-dd'))
		--BEGIN			
		--	SELECT '0'MsgType,(SELECT FORMAT(CONVERT(DATE,CompleteDate),'yyyy-MM-dd') FROM #TempTable)+'没有此工单的排班，请补充当日排班数据！' Msg			
		--	RETURN;	
		--END		
		--校验完工总数是否大于工单数量
		DECLARE @Mes_CompleteQty INT,@Quantity INT
		SELECT @Mes_CompleteQty=SUM(ISNULL(CompleteQty,0)),@Quantity=MIN(ISNULL(t1.Quantity,0)) FROM 
		(
		SELECT a.WorkOrder,a.CompleteQty FROM #TempTable a
		UNION ALL
		SELECT b.WorkOrder,b.CompleteQty FROM #TempTable a INNER JOIN dbo.mxqh_CompleteRpt b ON a.WorkOrder=b.WorkOrder
		) t LEFT JOIN dbo.mxqh_plAssemblyPlanDetail t1 ON t.WorkOrder=t1.WorkOrder 
		GROUP BY t.WorkOrder 
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
			IF ISNULL(@IsToU9,0)=0--完工报告不集成到U9
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
						  U9WorkOrderID ,
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
						  a.U9WorkOrderID , -- WorkOrderID - int
						  @WorkOrderID,
						  a.WorkOrder , -- WorkOrder - varchar(30)
						  a.CompleteDate , -- CompleteDate - datetime
						  a.CompleteQty
						  FROM #TempTable a
				SELECT '1'MsgType,'添加成功！' Msg
			END
			ELSE--完工报告集成到U9
			BEGIN
				INSERT INTO dbo.mxqh_CompleteRpt
				        ( CreateBy , CreateDate , ModifyBy , ModifyDate ,
				          DocNo ,U9DocID , DocType , DocTypeCode , DocTypeName ,
				          Status ,
				          MaterialID ,
				          MaterialCode ,
				          MaterialName ,
						  U9WorkOrderID,
				          WorkOrderID ,
				          WorkOrder ,
				          CompleteDate ,
				          CompleteQty ,
				          ActualRcvQty ,				          
				          HandlePerson ,
				          HandlePersonID ,
				          HandleDept ,
				          HandleDeptID ,
				          WhID ,
				          WhCode ,
				          WhName ,
				          LineID ,
				          LineCode ,
				          LineName ,
				          LotParam
				        )
				select @CreateBy , -- CreateBy - nvarchar(30)
				          GETDATE() , -- CreateDate - datetime
				          N'' , -- ModifyBy - nvarchar(30)
				          GETDATE() , -- ModifyDate - datetime
				           a.DocNo, -- DocNo - varchar(30)
				          a.DocID , -- U9DocID - bigint
				          a.DocTypeID, -- DocType - bigint
				          a.DocTypeCode , -- DocTypeCode - varchar(30)
				          a.DocTypeName, -- DocTypeName - nvarchar(30)
				          0 , -- Status - int
				          0 , -- MaterialID - int
				          a.MaterialCode , -- MaterialCode - varchar(30)
				          a.MaterialName , -- MaterialName - nvarchar(600)
				          a.U9WorkOrderid , -- WorkOrderID - int
						  @WorkOrderID,
				          a.WorkOrder , -- WorkOrder - varchar(30)
				          GETDATE() , -- CompleteDate - datetime
				          a.CompleteQty , -- CompleteQty - int
				          0 , -- ActualRcvQty - int
				          a.HandlePerson, -- HandlePerson - varchar(100)
				          a.HandlePersonID , -- HandlePersonID - bigint
				          a.HandleDept , -- HandleDept - varchar(100)
				          a.HandleDeptID , -- HandleDeptID - bigint
				          a.WhID , -- WhID - bigint
				          a.WhCode , -- WhCode - varchar(50)
				          a.WhName , -- WhName - varchar(100)
				          a.LineID, -- LineID - bigint
				          a.LineCode , -- LineCode - varchar(50)
				          a.LineName , -- LineName - varchar(100)
				          a.LotName  -- LotParam - varchar(100)
				       FROM #TempTable a
					   	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable1') AND TYPE='U')
						BEGIN
							UPDATE op_IPQCMain SET U9InDocNo='',IsToU9=0,ToU9TS='',IsInStorage=0,InStorageTS=NULL,DocID=NULL
							FROM #TempTable a WHERE a.docno=ISNULL(dbo.op_IPQCMain.U9InDocNo,'')							
							UPDATE op_IPQCMain SET U9InDocNo=b.DocNo,IsToU9=1,ToU9TS=GETDATE(),IsInStorage=0,InStorageTS=NULL,DocID=NULL
							FROM #TempTable1 a,#TempTable b WHERE a.ID=dbo.op_IPQCMain.ID
							
						END 						
						SELECT '1'MsgType,'添加成功！' Msg
			END  
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'添加失败！' Msg
	END 
END 

