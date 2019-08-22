/*
��֤�����Լ��ӷ����Ƿ��б����ã�������ɾ����
��֮,ɾ�������Լ��ַ����µ������ӷ���
*/
ALTER PROC mxqh_DeleteMaterialType
(
@ID INT
)
AS
BEGIN

DECLARE @Result VARCHAR(4)

IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#tempMT') AND TYPE='U')
BEGIN
	DROP TABLE #tempMT
END 

;WITH data1 AS
(
SELECT a.ID,a.TypeCode,a.TypeName,a.PID FROM dbo.baMaterialType a WHERE a.ID=@ID
UNION ALL
SELECT a.ID,a.TypeCode,a.TypeName,a.PID FROM dbo.baMaterialType a INNER JOIN data1 b ON a.PID=b.ID
)
SELECT * INTO #tempMT FROM data1 a 

--�ж��Ƿ��з��౻����
IF EXISTS(SELECT a.ID FROM dbo.baMaterial a INNER JOIN #tempMT b ON a.MaterialTypeID=b.ID)
BEGIN
	SELECT '0' MsgType,'���౻���ã�����ɾ����'Msg
END 
ELSE--δ������
BEGIN
	DELETE FROM dbo.baMaterialType WHERE dbo.baMaterialType.ID IN (SELECT ID FROM #tempMT)
	SELECT '1' MsgType,'ɾ���ɹ���'Msg
END 



END 