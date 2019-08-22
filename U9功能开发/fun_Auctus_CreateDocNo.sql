/*
生成订单号
*/
ALTER  FUNCTION fun_Auctus_CreateDocNo
(
	@Prefix VARCHAR(20),--订单号前缀
	@Date DATETIME,--订单日期
	@OrderNo INT--订单序号
)
RETURNS VARCHAR(50)
AS
BEGIN
--	DECLARE @Prefix VARCHAR(20)='FO'
--	DECLARE @Date DATETIME
--	DECLARE @OrderNo INT=11
--SET @Date=GETDATE()

RETURN @Prefix+FORMAT(@Date,'yyMMdd')+CASE WHEN @OrderNo<10 THEN '000'+CONVERT(VARCHAR(10),@OrderNo)
		WHEN @OrderNo>=10 AND @OrderNo<100 THEN '00'+CONVERT(VARCHAR(10),@OrderNo)
		WHEN @OrderNo>=100 AND @OrderNo<1000 THEN '0'+CONVERT(VARCHAR(10),@OrderNo)
		else CONVERT(VARCHAR(10),@OrderNo) END 

END