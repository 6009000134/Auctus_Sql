/*
���ģ�����Թ�ϵ
*/
ALTER PROC sp_AddQualityTPRelation
(
@CreateBy varchar(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_QualityTPRelation a,#TempTable b WHERE a.PropertyID=b.PropertyID AND a.TemplateID=b.TemplateID)
		BEGIN
			SELECT '0'MsgType,'ģ������ͬ�����ԣ������ظ���ӣ�'Msg		
		END 
		ELSE
        BEGIN
			INSERT INTO dbo.mxqh_QualityTPRelation
					( CreateBy ,CreateDate ,ModifyBy ,ModifyDate ,TemplateID ,TemplateCode ,
					  TemplateName ,PropertyID ,PropertyCode ,PropertyName ,OrderNo)
			SELECT @CreateBy,GETDATE(),@CreateBy,GETDATE(),b.ID,b.Code,b.Name,c.ID,c.Code,c.text,a.OrderNo FROM #TempTable a INNER JOIN dbo.mxqh_QualityTemplate b ON a.TemplateID=b.ID
			INNER JOIN dbo.mxqh_QualityProperty c ON a.PropertyID=c.ID
			SELECT '1'MsgType,'��ӳɹ���'Msg        
		END 

    END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�'Msg		
	END 
END 