ALTER FUNCTION f_auctus_GetWorkTime
(
@ProjectID VARCHAR(100),
@WorkID VARCHAR(100),
@Datetime DATETIME
)
RETURNS DATETIME
AS
BEGIN

	--DECLARE @ProjectID VARCHAR(200)='28C3542C-1D0A-4BD3-9806-0083616FA505',@Datetime DATETIME='2020-03-31 11:00:00'\
	DECLARE @weekday INT=(SELECT DATEPART(weekday,@Datetime)-1)
	DECLARE @hour INT=(SELECT DATEPART(HOUR,@Datetime))
	DECLARE @minute INT=(SELECT DATEPART(MINUTE,@Datetime))
	--SELECT @hour,@minute

	DECLARE @IsBreak INT=0

	IF EXISTS(SELECT 1 FROM dbo.PJ_Project a WHERE a.WorkId=@ProjectID)
	BEGIN
	WHILE @IsBreak>-1
	BEGIN	
		IF EXISTS(
		SELECT b.* FROM dbo.PJ_Project a  INNER JOIN dbo.PJ_CalendarItem b ON a.CalendarId=b.CalendarID
		WHERE a.WorkId=@ProjectID AND b.WeekDay=@weekday AND b.IsWork=1)--TODO:排除特殊休息日 特殊工作日
		BEGIN	
			SET @Datetime=DATEADD(DAY,@IsBreak,@Datetime)				
			SET @IsBreak=-1--中断
		END
		ELSE
		BEGIN
			SET @IsBreak=@IsBreak+1
			IF @weekday=6
			SET @weekday=0
			ELSE
			SET @weekday=@weekday+1	 
		END 
		DECLARE @amsh INT,@ameh int,@amsm INT,@amem INT,@pmsh INT,@pmeh int,@pmsm INT,@pmem int,@nsh INT,@neh int,@nsm INT,@nem INT
		IF @hour >=@amsh AND @hour<=@ameh AND @amsh!=''
		BEGIN
			IF @minute<@amsm
			SET @minute=@amsm
			ELSE IF @minute>@pmem
			BEGIN
				SET @minute=@amsm
				SET @Datetime=DATEADD(DAY,1,@Datetime)
			END 
			ELSE IF (@minute>=@amsm AND @minute<=@amem) OR (@minute>=@pmsm AND @minute<=@pmem)
			SET @minute=@minute
			ELSE IF @minute>@amem AND @minute<@pmsm
			SET @minute=@pmsm
		END
		SET @Datetime=@Datetime
	END
	END 
	RETURN @Datetime
END 