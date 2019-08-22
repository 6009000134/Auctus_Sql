/*
删除包装登记信息
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
     SELECT '0' MsgType,'此工单已开始包装，不可删除包装登记信息，删除失败！' Msg
	END
	ELSE
	BEGIN
		DELETE FROM dbo.opPackageDetail WHERE PackMainID=@PackMainID
		DELETE FROM dbo.opPackageMain WHERE ID=@PackMainID
		SELECT '1' MsgType,'删除成功！' Msg
	END 		
END 