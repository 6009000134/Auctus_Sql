/*
�������Ϸ���
*/
ALTER PROC mxqh_AddMaterialType
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.baMaterialType a,#TempTable b WHERE a.TypeCode=b.TypeCode OR a.TypeName=b.text)
		BEGIN
			SELECT '0' MsgType,'����������ظ������ʧ�ܣ�'Msg
		END 
		ELSE
        BEGIN
        	UPDATE dbo.baMaterialType SET LastLayerFlag=0 WHERE ID IN (SELECT pid FROM #TempTable)--�����½��ӷ���ʱ����ǰ���಻�����һ��
					INSERT INTO dbo.baMaterialType
		        ( ID ,
		          TS ,
		          TypeCode ,
		          TypeName ,
		          LevelCode ,
		          PID ,
		          LastLayerFlag
		        ) SELECT (SELECT MAX(ID)+1 FROM dbo.baMaterialType),Getdate(),a.TypeCode,a.text,'',a.PID,1 FROM #TempTable  a
			SELECT '1'MsgType,'��ӳɹ���' Msg
		END 		
	END 
	ELSE
    BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�' Msg
	END 
	
END 




