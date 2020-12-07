/*
�����ֵ���
*/
ALTER PROC sp_AddDictionary
(
@CreateBy VARCHAR(30)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_Base_Dic a,#TempTable b WHERE (a.Code=b.Code OR a.Name=b.Name) AND (a.typeCode=b.TypeCode OR a.TypeName=b.TypeName))
		BEGIN
			SELECT '0'MsgType,'����������ظ������ʧ�ܣ�'Msg
		END 		
		ELSE
        BEGIN
			INSERT INTO dbo.mxqh_Base_Dic
			        ( CreateBy ,
			          CreateDate ,
			          ModifyBy ,
			          ModifyDate ,
			          Code ,
			          Name ,
					  TypeCode,
					  TypeName,
			          OrderNo,
					  IsActive
			        )
			select @CreateBy , -- CreateBy - nvarchar(40)
			          GETDATE() , -- CreateDate - datetime
			          @CreateBy , -- ModifyBy - nvarchar(40)
			          GETDATE() , -- ModifyDate - datetime
			           a.Code, -- Code - nvarchar(300)
			          a.Name , -- Name - nvarchar(300)
					  a.TypeCode,
					  a.TypeName,
			          a.OrderNo, -- OrderNo - int
					  a.IsActive
			        FROM #TempTable a
		SELECT '1'MsgType,'��ӳɹ���' Msg
		END 
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�' Msg
	END 
END 

