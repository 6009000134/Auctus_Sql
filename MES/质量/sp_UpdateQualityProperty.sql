/*
�޸ļ���ά����
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
			SELECT '0' MsgType,'����������ظ����޸�ʧ�ܣ�'Msg
		END 
		ELSE
        BEGIN      
			UPDATE dbo.mxqh_QualityProperty SET ModifyBy=@CreateBy,ModifyDate=GETDATE(),Code=a.Code,text=a.text,OrderNo=a.OrderNo
			FROM #TempTable a WHERE a.ID=dbo.mxqh_QualityProperty.ID

			SELECT '1'MsgType,'�޸ĳɹ���' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'�޸�ʧ�ܣ�' Msg
	END 
END 

--SELECT * FROM dbo.mxqh_QualityProperty