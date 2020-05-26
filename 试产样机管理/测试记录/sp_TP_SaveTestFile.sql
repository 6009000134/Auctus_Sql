/*
上传测试结论文件
*/
Alter PROC sp_TP_SaveTestFile
(
@CreateBy VARCHAR(50),
@ID INT--TestRecordID
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
	--更新SDK信息
	MERGE INTO dbo.TP_TestFile a
	USING #TempTable b 
	ON a.TestRecordID = @ID AND a.AttachSn = CONVERT(NVARCHAR(40),b.AttachSn) collate Chinese_PRC_CS_AS
	WHEN NOT MATCHED 
	THEN INSERT (TestRecordID ,
	          AttachSn ,
	          CreateBy ,
	          CreateDate)
		VALUES(@ID, b.AttachSn, @CreateBy, GETDATE())
	WHEN NOT MATCHED BY SOURCE AND a.TestRecordID=@ID
	THEN DELETE;
	END	
END 