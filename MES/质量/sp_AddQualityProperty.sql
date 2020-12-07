/*
��������ά����
*/
CREATE PROC sp_AddQualityProperty
(
@CreateBy VARCHAR(50)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_QualityProperty a,#TempTable b WHERE a.Code=b.Code OR a.text=b.text)
		BEGIN
			SELECT '0' MsgType,'����������ظ������ʧ�ܣ�'Msg
		END 
		ELSE
        BEGIN        	
			INSERT INTO dbo.mxqh_QualityProperty
			        ( CreateBy ,
			          CreateDate ,
			          ModifyBy ,
			          ModifyDate ,
			          PID ,
			          Code ,
			          text ,
			          OrderNo
			        ) SELECT @CreateBy,GETDATE(),@CreateBy,GETDATE(),a.PID,a.Code,a.text,a.OrderNo FROM #TempTable  a
			SELECT '1'MsgType,'��ӳɹ���' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�' Msg
	END 
END 

--SELECT * FROM dbo.mxqh_QualityProperty