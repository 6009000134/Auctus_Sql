/*
ɾ������ά��ģ��
*/
ALTER PROC sp_DeleteQualityTemplate
(
@ID int
)
AS
BEGIN
	--����Ƿ���ģ�������˷������ݣ����в�����ɾ��
	IF 1=1
	BEGIN
		SELECT '0'MsgType,'�м���ģ�������˼���ά�������ݣ�����ɾ��ģ�����ã�' Msg     
	END 
	ELSE 
	BEGIN		
		DELETE FROM dbo.mxqh_QualityTemplate WHERE ID=@ID
		DELETE FROM dbo.mxqh_QualityTPRelation WHERE TemplateID=@ID     
	END 
END 

--SELECT * FROM dbo.mxqh_QualityProperty