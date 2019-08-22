/*
新增物料分类
*/
ALTER PROC mxqh_AddMaterialType
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.baMaterialType a,#TempTable b WHERE a.TypeCode=b.TypeCode OR a.TypeName=b.text)
		BEGIN
			SELECT '0' MsgType,'编码或名称重复，添加失败！'Msg
		END 
		ELSE
        BEGIN
        	UPDATE dbo.baMaterialType SET LastLayerFlag=0 WHERE ID IN (SELECT pid FROM #TempTable)--增加下阶子分类时，当前分类不是最后一层
					INSERT INTO dbo.baMaterialType
		        ( ID ,
		          TS ,
		          TypeCode ,
		          TypeName ,
		          LevelCode ,
		          PID ,
		          LastLayerFlag
		        ) SELECT (SELECT MAX(ID)+1 FROM dbo.baMaterialType),Getdate(),a.TypeCode,a.text,'',a.PID,1 FROM #TempTable  a
			SELECT '1'MsgType,'添加成功！' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'添加失败！' Msg
	END 
	
END 




