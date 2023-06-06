/*
货源表视图
*/
alter VIEW v_Cust_SupplySource4OA
AS

WITH PPRPrice AS
(
SELECT * FROM (
SELECT 
* 
,ROW_NUMBER() OVER(PARTITION BY t.Org,t.Supplier,t.ItemInfo_ItemID ORDER BY t.NetPrice)RN--未税最低价
FROM (
SELECT 
a.Org,a.Supplier,b.ID,b.ItemInfo_ItemID,b.Price,a.IsIncludeTax,a.Currency,b.Active,b.FromDate,b.ToDate
,CASE WHEN a.IsIncludeTax=1 THEN dbo.fn_CustGetCurrentRate(a.Currency, 1, GETDATE(), 2)*b.Price/1.13
ELSE dbo.fn_CustGetCurrentRate(a.Currency, 1, GETDATE(), 2)*b.Price END NetPrice
FROM dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b  ON a.ID=b.PurPriceList
WHERE a.Cancel_Canceled=0 AND b.Active=1
AND GETDATE() BETWEEN b.FromDate AND b.ToDate
)t
--,ROW_NUMBER() OVER(PARTITION BY a.Org,a.Supplier,b.ItemInfo_ItemID ORDER)
)t
WHERE t.RN=1

)
SELECT
a.ID
,a.Org OrgID,o.Code OrgCode,o1.Name OrgName
,a.ItemInfo_ItemID ItemID,m.Code ItemCode,m.Name ItemName--料品信息
,a.SupplierInfo_Supplier SupplierID,s.Code SupplierCode,s1.Name SupplierName--供应商信息
,ISNULL(ppr.NetPrice,0) NetPrice--供应商最低价
,CASE WHEN a.OrderNO=(SELECT MIN(t.OrderNO) FROM dbo.CBO_SupplySource t WHERE t.ItemInfo_ItemID=a.ItemInfo_ItemID AND t.Org=a.Org AND t.Effective_IsEffective=1 AND  GETDATE() BETWEEN t.Effective_EffectiveDate AND t.Effective_DisableDate GROUP BY t.ItemInfo_ItemID,t.Org) THEN '1' ELSE '0' END IsMainSupplier
,a.OrderNO
,ROW_NUMBER()OVER(PARTITION BY a.Org,a.ItemInfo_ItemID 
ORDER BY CASE WHEN a.Effective_IsEffective=1 OR a.DescFlexField_PrivateDescSeg2!='' THEN 0 ELSE 1 END 
,CASE WHEN s.DescFlexField_PrivateDescSeg3  IN ('NEI01','OT01') THEN 1 ELSE 0 END 
, ISNULL(ppr.NetPrice,0),a.OrderNo) NewOrderNo--有效的（含临时失效）、内外部、价格排序
,CONVERT(DATE,a.Effective_EffectiveDate)Effective_EffectiveDate,CONVERT(DATE,a.Effective_DisableDate)Effective_DisableDate,CASE WHEN a.Effective_IsEffective=1 THEN 1 ELSE 0 END Effective_IsEffective--有效性
,p.PurchaseQuotaMode
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.PurchaseQuotaModeEnum',p.PurchaseQuotaMode,'zh-cn')PurchaseQuotaModeName
,a.SupplierQuota--配额比例
,CASE WHEN p.PurchaseQuotaMode IN (1,4,6) THEN 1 ELSE NULL END  NewSupplierQuota--配额比例
,a.SupplierStatus--货源状态
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Supplier.SupplierStatusEnum',A.SupplierStatus,'zh-cn')SupplierStatusName
,a.MaxPurQty--采购限量
,m.PurchaseUOM --采购单位ID
,u.Code PurchaseUOMCode
,u1.Name PurchaseUOMName
,a.DescFlexField_PrivateDescSeg2 IsExistsFlow
FROM dbo.CBO_SupplySource a INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID
inner JOIN dbo.Base_Organization o ON a.Org=o.ID 
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_Supplier s ON a.SupplierInfo_Supplier=s.ID 
INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_PurchaseInfo p ON a.ItemInfo_ItemID=p.ItemMaster
INNER JOIN dbo.Base_UOM u ON m.PurchaseUOM=u.ID 
INNER JOIN dbo.Base_UOM_Trl u1 ON u.ID=u1.ID AND u1.SysMLFlag='zh-cn'
LEFT JOIN PPRPrice ppr ON a.Org=ppr.Org AND a.ItemInfo_ItemID=ppr.ItemInfo_ItemID AND a.SupplierInfo_Supplier=ppr.Supplier




GO
