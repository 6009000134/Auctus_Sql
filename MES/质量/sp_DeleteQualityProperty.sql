/*
ɾ������ά����
*/
ALTER PROC sp_DeleteQualityProperty
(
@ID int
)
AS
BEGIN
	--����Ƿ���ģ�������˷������ݣ����в�����ɾ��
	IF 1=0
	BEGIN
		SELECT '0'MsgType,'�м���ģ�������˼���ά�������ݣ�����ɾ��ģ�����ã�' Msg     
	END 
	ELSE 
	BEGIN		
		;WITH Childs AS
        (
		SELECT ID,PID,a.Code FROM dbo.mxqh_QualityProperty a WHERE a.ID=@ID
		UNION ALL
        SELECT a.ID,a.PID,a.Code FROM mxqh_QualityProperty a
		INNER JOIN Childs b ON a.PID=b.ID
		)
		SELECT ID INTO #tempIDs FROM Childs
		DELETE FROM dbo.mxqh_QualityProperty WHERE ID IN (SELECT Id FROM #tempIDs)
		SELECT '1'MsgType,'ɾ���ɹ���' Msg     
	END 
END 

--SELECT * FROM dbo.mxqh_QualityProperty