/*
ȡ���빺ת�ɹ�ʱ�������������Ʒ
*/
CREATE PROC sp_Auctus_UI_GetNonEditableItem
(
@IDs VARCHAR(MAX)
)
AS
BEGIN
--DECLARE @IDs VARCHAR(MAX)='1001708090164019,,1001804104517706'
SELECT a.ItemMaster ItemID,a.PurchaseQuotaMode FROM dbo.CBO_PurchaseInfo a WHERE a.ItemMaster IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@IDs))
AND a.PurchaseQuotaMode=4
END
