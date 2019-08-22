/*
保存模具变更单
*/
ALTER PROC sp_SaveMouldModify
(
@CreatedBy VARCHAR(50),
@DocNo VARCHAR(50)
)
AS
BEGIN 
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.MouldModify a,#Temptable b WHERE a.MouldID=b.ID AND a.Status=0)
	BEGIN
		SELECT '0' MsgType,'此模具有未审核变更单，不可再添加变更单！'Msg
	END 
	--SELECT * FROM #TempTable
	INSERT INTO dbo.MouldModify
	        ( CreateBy ,
	          CreateDate ,
	          ModifyBy ,
	          ModifyDate ,
	          DocNo ,
	          Status ,
	          MouldID ,
	          Code ,
	          Name ,
	          SPECS ,
	          HoleNum ,
	          TotalNum ,
	          DailyCapacity ,
	          DailyNum ,
	          RemainNum ,
	          Holder ,
	          Manufacturer ,
	          CycleTime ,
	          ProductWeight ,
	          NozzleWeight ,
	          DealDate ,
	          --IsEffective ,
	          EffectiveDate ,
	          Remark
	        )SELECT @CreatedBy,GETDATE(),null,null,@DocNo,0,a.ID,a.Code,a.Name,a.SPECS,a.HoleNum,a.TotalNum ,a.DailyCapacity ,a.DailyNum ,a.RemainNum 
			,a.Holder ,a.Manufacturer ,a.CycleTime ,a.ProductWeight ,a.NozzleWeight ,a.DealDate --,a.IsEffective 
			,a.EffectiveDate ,a.Remark
			FROM #TempTable a

END 
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable1') AND TYPE='U')
BEGIN
	--SELECT * FROM dbo.MouldModifySeg
	--SELECT * FROM #TempTable1
	INSERT INTO	dbo.MouldModifySeg
	        ( CreateBy ,
	          CreateDate ,
	          ModifyBy ,
	          ModifyDate ,
			  ModifyID,
	          ModifySeg ,
	          DataBeforeModify ,
	          DataAfterModify,
			  DataType
	        )SELECT @CreatedBy,GETDATE(),null,null,(SELECT ID FROM dbo.MouldModify WHERE DocNo=@DocNo),a.ModifySeg,a.DataBeforeModify,a.DataAfterModify,b.DATA_TYPE
			FROM #TempTable1 a LEFT JOIN INFORMATION_SCHEMA.columns b ON a.ModifySeg=b.COLUMN_NAME AND b.TABLE_NAME='Mould'
		
END 
	SELECT '1' MsgType,'添加成功！'Msg,(SELECT ID FROM dbo.MouldModify WHERE DocNo=@DocNo)ID

END 



