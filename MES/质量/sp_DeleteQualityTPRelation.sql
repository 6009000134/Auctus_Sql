/*
�޸�ģ�����Թ�ϵ
*/
Alter PROC sp_DeleteQualityTPRelation
(
@CreateBy varchar(30),
@ID INT
)
AS
BEGIN
	--TODO:У��ģ���Ƿ�����
	DELETE FROM dbo.mxqh_QualityTPRelation WHERE ID=@ID
	SELECT '1'MsgType,'ɾ���ɹ���'Msg
END 