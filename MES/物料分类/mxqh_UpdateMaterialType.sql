/*
�޸����Ϸ���
*/
alter PROC mxqh_UpdateMaterialType
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		UPDATE dbo.baMaterialType SET TypeCode=a.TypeCode,TypeName=a.text FROM #TempTable a WHERE dbo.baMaterialType.ID=a.ID
		SELECT '1' MsgType,'�޸ĳɹ���'Msg		
	END 
	ELSE
    BEGIN
		SELECT '0' MsgType,'�޸�ʧ�ܣ�'Msg		
	END 
END 