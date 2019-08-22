/*
QC登记信息保存
*/
Alter PROC sp_QCSave
(
@CreateBy VARCHAR(30),
@OQCDocNo VARCHAR(50)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT ID FROM #TempTable WHERE ID=-1)--新增
		BEGIN
			SELECT '新增' Msg
			INSERT INTO dbo.qlCheckMain
			        ( ID ,DocNo,TS ,PalletCode ,CustomOrder ,CheckNum ,IsOK ,CheckTime ,CheckUser ,ProblemType ,ProblemInfo ,ProblemDesp 
			        )
					SELECT (SELECT MAX(ID) FROM dbo.qlCheckMain)+1,@OQCDocNo,GETDATE(),a.PalletCode,a.CustomOrder,(SELECT COUNT(*) FROM #TempTable1),a.IsOK,GETDATE(),a.CheckUser
					,a.ProblemType,a.ProblemInfo,a.ProblemDesp
					FROM #TempTable a 
		END 
		ELSE--编辑操作
        BEGIN
			SELECT '编辑' Msg
			UPDATE dbo.qlCheckMain SET CheckNum=(SELECT COUNT(*) FROM #TempTable1),IsOK=a.IsOK,CheckTime=GETDATE(),CheckUser=a.CheckUser
			,ProblemType=a.ProblemType,ProblemInfo=a.ProblemInfo,ProblemDesp=a.ProblemDesp
			FROM #TempTable a WHERE dbo.qlCheckMain.ID=a.ID
		END 
	END 
	
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable1') AND TYPE='U')
	BEGIN
		DECLARE @MainID INT
		SELECT @MainID=a.ID FROM dbo.qlCheckMain a ,#TempTable b WHERE a.PalletCode=b.PalletCode
		IF EXISTS(SELECT ID FROM #TempTable WHERE ID=-1)--新增
		BEGIN
			SELECT '新增' Msg
			INSERT INTO dbo.qlCheckPar
			        ( ID ,TS ,MainID ,SNCode ,InternalCode ,ProductCode ,ProductName ,IsCheckOk ,Remark ,CreateDate ,Item1
			        )
					SELECT (SELECT MAX(ID) FROM dbo.qlCheckPar)+ROW_NUMBER()OVER(ORDER BY a.SNCode),GETDATE(),@MainID,a.SNCode,a.InternalCode,a.ProductCode,a.ProductName,CASE WHEN a.IsCheckOk='true' THEN 1 ELSE 0 END,a.Remark,GETDATE(),a.Item1
					FROM #TempTable1 a
		END 
		ELSE--编辑操作
        BEGIN			
			--删除校验记录	
			DELETE FROM  dbo.qlCheckPar WHERE MainID=@MainID AND ID  NOT IN (SELECT b.ID FROM #tempTable1 a,dbo.qlCheckPar b WHERE a.ID=b.ID )	
			--编辑校验记录
			SELECT '编辑' Msg
			UPDATE dbo.qlCheckPar SET SNCode=a.SNCode,InternalCode=a.InternalCode,ProductCode=a.ProductCode,ProductName=a.ProductName,IsCheckOk=CASE WHEN a.IsCheckOk='true' THEN 1 ELSE 0 END
			,Remark=a.Remark,CreateDate=GETDATE(),Item1=a.Item1
			FROM #TempTable1 a WHERE dbo.qlCheckPar.ID=a.ID
			--新增校验记录
			INSERT INTO dbo.qlCheckPar
			    ( ID ,TS ,MainID ,SNCode ,InternalCode ,ProductCode ,ProductName ,IsCheckOk ,Remark ,CreateDate ,Item1
			    )
				SELECT (SELECT MAX(ID) FROM dbo.qlCheckPar)+ROW_NUMBER()OVER(ORDER BY a.SNCode),GETDATE(),@MainID,a.SNCode,a.InternalCode,a.ProductCode,a.ProductName,a.IsCheckOk,a.Remark,GETDATE(),a.Item1
				FROM #TempTable1 a WHERE a.ID=-1
			
		END 
	END 
END 