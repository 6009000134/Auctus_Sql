/*
2019.04减税，税率从16%降到13%
一般单据在单头可以抓取税率，但是厂商价表没有，此方法主要给厂商价表使用
*/
CREATE FUNCTION fun_Auctus_GetTaxRate
(
@Date DATETIME
)
RETURNS decimal(18,2)
AS
BEGIN
DECLARE @TaxRate DECIMAL(18,2)
IF ISNULL(@Date,GETDATE())<'2019-04-01'
SET @TaxRate=0.16
ELSE
SET @TaxRate=0.13
RETURN @TaxRate
END 