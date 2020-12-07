/*
修改模板属性关系
*/
Alter PROC sp_DeleteQualityTPRelation
(
@CreateBy varchar(30),
@ID INT
)
AS
BEGIN
	--TODO:校验模板是否被引用
	DELETE FROM dbo.mxqh_QualityTPRelation WHERE ID=@ID
	SELECT '1'MsgType,'删除成功！'Msg
END 