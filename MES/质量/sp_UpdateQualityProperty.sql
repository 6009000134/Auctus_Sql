/*
修改检验维修项
*/
CREATE PROC sp_UpdateQualityProperty
(
@CreateBy VARCHAR(50)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_QualityProperty a,#TempTable b WHERE (a.Code=b.Code OR a.text=b.text) AND a.ID<>b.ID)
		BEGIN
			SELECT '0' MsgType,'编码或名称重复，修改失败！'Msg
		END 
		ELSE
        BEGIN      
			UPDATE dbo.mxqh_QualityProperty SET ModifyBy=@CreateBy,ModifyDate=GETDATE(),Code=a.Code,text=a.text,OrderNo=a.OrderNo
			FROM #TempTable a WHERE a.ID=dbo.mxqh_QualityProperty.ID

			SELECT '1'MsgType,'修改成功！' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'修改失败！' Msg
	END 
END 

--SELECT * FROM dbo.mxqh_QualityProperty