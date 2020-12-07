/*
新增检验维修模板
*/
CREATE PROC sp_AddQualityTemplate
(
@CreateBy VARCHAR(50)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_QualityTemplate a,#TempTable b WHERE a.Code=b.Code OR a.Name=b.Name)
		BEGIN
			SELECT '0' MsgType,'编码或名称重复，添加失败！'Msg
		END 
		ELSE
        BEGIN        	
			INSERT INTO dbo.mxqh_QualityTemplate
			        ( CreateBy ,
			          CreateDate ,
			          ModifyBy ,
			          ModifyDate ,
			          Code ,
			          Name,
					  OrderNo
			        ) SELECT @CreateBy,GETDATE(),@CreateBy,GETDATE(),a.Code,a.Name,a.OrderNo FROM #TempTable  a
			SELECT '1'MsgType,'添加成功！' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'添加失败！' Msg
	END 
END 

--SELECT * FROM dbo.mxqh_QualityTemplate