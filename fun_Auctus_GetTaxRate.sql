/*
2019.04��˰��˰�ʴ�16%����13%
һ�㵥���ڵ�ͷ����ץȡ˰�ʣ����ǳ��̼۱�û�У��˷�����Ҫ�����̼۱�ʹ��
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