/*
删除检验维修项
*/
ALTER PROC sp_DeleteQualityProperty
(
@ID int
)
AS
BEGIN
	--检测是否有模板引用了分类数据，若有不允许删除
	IF 1=0
	BEGIN
		SELECT '0'MsgType,'有检验模板引用了检验维护项数据，请先删除模板引用！' Msg     
	END 
	ELSE 
	BEGIN		
		;WITH Childs AS
        (
		SELECT ID,PID,a.Code FROM dbo.mxqh_QualityProperty a WHERE a.ID=@ID
		UNION ALL
        SELECT a.ID,a.PID,a.Code FROM mxqh_QualityProperty a
		INNER JOIN Childs b ON a.PID=b.ID
		)
		SELECT ID INTO #tempIDs FROM Childs
		DELETE FROM dbo.mxqh_QualityProperty WHERE ID IN (SELECT Id FROM #tempIDs)
		SELECT '1'MsgType,'删除成功！' Msg     
	END 
END 

--SELECT * FROM dbo.mxqh_QualityProperty