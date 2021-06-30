ALTER  proc sp_auctus_CheckWorkTime
(
@ProjectID VARCHAR(100),
@WorkID VARCHAR(100),
@StartDate DATETIME,
@EndDate DATETIME,
@UserName VARCHAR(20)
)
AS
BEGIN
	--DECLARE @ProjectID VARCHAR(100)='963B9C23-C455-4FFB-98C1-F7F5C02C5D8D',@WorkID VARCHAR(100)='CE632224-5D90-4590-8A36-46A3B3DF7C2A'
	--,@StartDate DATETIME='2021-05-01 8:00:00',@EndDate DATETIME='2021-04-02 18:00:00'
	DECLARE @msg VARCHAR(600)='';--记录错误信息
	IF NOT	EXISTS(SELECT 1 FROM dbo.SM_Users WHERE UserName=@UserName)
	SET @msg='PLM不存在'''+@UserName+'''的账号，请联系管理员！'

	IF ISNULL(@msg,'')=''
	SELECT '1' MsgType,'成功' Msg
	ELSE
    SELECT '0' MsgType,@msg Msg
END


