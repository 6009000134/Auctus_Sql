/*
���ۿ�����ڱ���
*/
ALTER PROC sp_Auctus_ShipOverdueSoonPaymentList
(
@Days int
)
AS
BEGIN 
	SELECT *,(��������)*(-1)������������ FROM  Auctus_V_ShipOverduePaymentlist a WHERE a.��������*(-1)<@Days AND a.��������*(-1)>0
END 