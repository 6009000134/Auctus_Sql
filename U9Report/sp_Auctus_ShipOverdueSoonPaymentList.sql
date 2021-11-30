/*
销售款即将逾期报表
*/
ALTER PROC sp_Auctus_ShipOverdueSoonPaymentList
(
@Days int
)
AS
BEGIN 
	SELECT *,(逾期天数)*(-1)即将逾期天数 FROM  Auctus_V_ShipOverduePaymentlist a WHERE a.逾期天数*(-1)<@Days AND a.逾期天数*(-1)>0
END 