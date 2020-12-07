/*
�޸�ģ�����Թ�ϵ
*/
Alter PROC sp_UpdateQualityTPRelation
(
@CreateBy varchar(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_QualityTPRelation a,#TempTable b WHERE a.PropertyID=b.PropertyID AND a.TemplateID=b.TemplateID AND a.ID<>b.ID)
		BEGIN
			SELECT '0'MsgType,'ģ������ͬ�����ԣ������ظ���ӣ�'Msg		
		END 
		ELSE
        BEGIN
 			UPDATE dbo.mxqh_QualityTPRelation SET ModifyBy=@CreateBy,ModifyDate=GETDATE(),TemplateID=b.ID,TemplateCode=b.Code,TemplateName=b.Name
			,PropertyID=c.ID,PropertyCode=c.Code,PropertyName=c.text,OrderNo=a.OrderNo	
			FROM #TempTable a INNER JOIN dbo.mxqh_QualityTemplate b ON a.TemplateID=b.ID
			INNER JOIN dbo.mxqh_QualityProperty c ON a.PropertyID=c.ID
			WHERE a.ID=dbo.mxqh_QualityTPRelation.ID
			SELECT '1'MsgType,'�޸ĳɹ���'Msg       
		END 

    END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'�޸�ʧ�ܣ�'Msg		
	END 
END 