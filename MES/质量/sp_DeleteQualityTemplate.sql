/*
删除检验维修模板
*/
ALTER PROC sp_DeleteQualityTemplate
(
@ID int
)
AS
BEGIN
	--检测是否有模板引用了分类数据，若有不允许删除
	IF 1=1
	BEGIN
		SELECT '0'MsgType,'有检验模板引用了检验维护项数据，请先删除模板引用！' Msg     
	END 
	ELSE 
	BEGIN		
		DELETE FROM dbo.mxqh_QualityTemplate WHERE ID=@ID
		DELETE FROM dbo.mxqh_QualityTPRelation WHERE TemplateID=@ID     
	END 
END 

--SELECT * FROM dbo.mxqh_QualityProperty