
/*
获取输入日期的是不是节假日的日期
例如：今天星期六，输入日期后得到下周一的具体日期
*/
ALTER FUNCTION Auctus_GetNextWorkDay
(
	@Date DATETIME
)
RETURNS DATETIME
AS
BEGIN
DECLARE @IsHoliday INT
SELECT @IsHoliday=COUNT(1) FROM dbo.Auctus_Holidays a WHERE a.Date=CONVERT(DATE,@Date)

WHILE @IsHoliday=1
BEGIN
SET @Date=DATEADD(DAY,1,@Date)

IF	(SELECT COUNT(1) FROM dbo.Auctus_Holidays a WHERE a.Date=CONVERT(DATE,@Date))<>1
SET @IsHoliday=0
END 
RETURN  @Date
END