/*
�޸ĳ�Ͷ��
1���������ݲ������޸�
*/
ALTER PROC sp_UpdateOverInput
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.mxqh_OverInput a INNER JOIN #TempTable b ON a.ID=b.ID AND a.Status<>0)
		BEGIN--�������ݲ������޸�
			SELECT '0'MsgType,'���ݲ��ǿ���״̬���������޸ģ�'Msg        
		END 
		ELSE
        BEGIN
        	UPDATE dbo.mxqh_OverInput SET OverInputQty=a.OverInputQty,Reason=a.Reason,ModifyBy=a.ModifyBy,ModifyDate=getdate()
			FROM #TempTable a WHERE a.id=dbo.mxqh_OverInput.ID
			SELECT '1'MsgType,'�޸ĳɹ���'Msg
		END 		
	END 
	ELSE
		SELECT '0'MsgType,'�޸�ʧ�ܣ�'Msg
END 

