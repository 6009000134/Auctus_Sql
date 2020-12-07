/*
修改检验维修模板
*/
alter PROC sp_UpdateQualityTemplate
(
@CreateBy VARCHAR(50)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_QualityTemplate a,#TempTable b WHERE (a.Code=b.Code OR a.Name=b.Name) AND a.ID<>b.ID)
		BEGIN
			SELECT '0' MsgType,'编码或名称重复，修改失败！'Msg
		END 
		ELSE
        BEGIN      
			UPDATE dbo.mxqh_QualityTemplate SET ModifyBy=@CreateBy,ModifyDate=GETDATE(),Code=a.Code,Name=a.Name,OrderNo=a.OrderNo
			FROM #TempTable a WHERE a.ID=dbo.mxqh_QualityTemplate.ID

			SELECT '1'MsgType,'修改成功！' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'修改失败！' Msg
	END 
END 

--SELECT * FROM dbo.mxqh_QualityProperty