/*
ɾ����װ�Ǽ���Ϣ
*/
ALTER PROC sp_DeletePackInfo
(
@PackMainID INT
)
AS
BEGIN
	DECLARE @IsExistsChild INT
	SET @IsExistsChild=(SELECT COUNT(*) 
	FROM dbo.opPackageMain a INNER JOIN dbo.opPackageDetail b ON a.ID=b.PackMainID INNER JOIN dbo.opPackageChild c ON b.ID=c.PackDetailID
	WHERE a.ID=@PackMainID)
	IF @IsExistsChild>0
	BEGIN
     SELECT '0' MsgType,'�˹����ѿ�ʼ��װ������ɾ����װ�Ǽ���Ϣ��ɾ��ʧ�ܣ�' Msg
	END
	ELSE
	BEGIN
		DELETE FROM dbo.opPackageDetail WHERE PackMainID=@PackMainID
		DELETE FROM dbo.opPackageMain WHERE ID=@PackMainID
		SELECT '1' MsgType,'ɾ���ɹ���' Msg
	END 		
END 