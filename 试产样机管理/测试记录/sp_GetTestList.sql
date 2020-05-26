/*
获取测试记录列表
*/
ALTER PROC sp_GetTestList
(
@pageIndex INT=1,
@pageSize INT=10,
@DocNo VARCHAR(50),
@TestedBy VARCHAR(100),
@SD DATETIME,
@ED DATETIME,
@SNCode VARCHAR(100)
)
AS
BEGIN

	--DECLARE @pageIndex INT=1,@pageSize INT=10,@TestedBy VARCHAR(100),@SD DATETIME,@ED DATETIME,@SNCode VARCHAR(100)
	IF	ISNULL(@SD,'')=''
	SET @SD='2000-01-01'
	IF ISNULL(@ED,'')=''
	SET @ED='9999-01-01'

	SET @DocNo='%'+ISNULL(@DocNo,'')+'%'
	SET @TestedBy='%'+ISNULL(@TestedBy,'')+'%'
	SET @SNCode='%'+ISNULL(@SNCode,'')+'%'

	SELECT a.ID,a.DocNo,a.CreateBy,a.TestedBy,FORMAT(a.TestedDate,'yyyy-MM-dd')TestedDate,a.Remark,a.Status
	,(SELECT COUNT(1) FROM dbo.TP_TestDetail b WHERE b.TestRecordID=a.ID AND b.IsPass=0)UnPassCount
	,(SELECT COUNT(1) FROM dbo.TP_TestDetail b WHERE b.TestRecordID=a.ID)TestCount
	FROM dbo.TP_TestRecord a
	WHERE 1=1
	AND PATINDEX(@TestedBy,a.TestedBy)>0 
	AND a.TestedDate>=@SD AND a.TestedDate<@ED
	AND PATINDEX(@DocNo,a.DocNo)>0
	--AND (SELECT COUNT(1) FROM dbo.TP_TestDetail b WHERE b.TestRecordID=a.ID AND PATINDEX(@SNCode,b.SNCode)>0)>0

	SELECT COUNT(1)Count
	FROM dbo.TP_TestRecord a
	WHERE 1=1
	AND PATINDEX(@TestedBy,a.TestedBy)>0 
	AND PATINDEX(@DocNo,a.DocNo)>0
	AND a.TestedDate>=@SD AND a.TestedDate<@ED
END 

