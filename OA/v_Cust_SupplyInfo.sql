
/*
货源表、供应商-料品交叉信息
*/
ALTER  VIEW v_Cust_SupplyInfo
as
SELECT 
ROW_NUMBER()OVER(ORDER BY a.Code,ss.OrderNO)RN
,a.ID,a.Code,a.Name,a.SPECS--料号、品名、规格
,a.Org,o.Code OrgCode,o1.Name OrgName--组织名称
,p.PurchaseQuotaMode,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.PurchaseQuotaModeEnum',p.PurchaseQuotaMode,'zh-cn')Mode--配额方式
,s.ID Supplier,s.Code SupplierCode,s1.Name SupplierName--供应商名称
,ss.ID SSID,ss.OrderNO--供货商魂虚
,ss.SupplierQuota--配额比例
,ss.IsSmallQtyPurBatch--小倍量批量处理
,ss.MaxPurQty--采购限量
,ss.PurchaseBatchQty--采购倍量
,ss.SupplierStatus
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Supplier.SupplierStatusEnum',ss.SupplierStatus,'zh-cn')SupplierStatusName--货源状态
,CASE WHEN ss.Effective_IsEffective=1 THEN '1' ELSE '0'END  SS_IsEffective--货源表-是否生效
,FORMAT(ss.Effective_EffectiveDate,'yyyy-MM-dd') SS_EffectiveDate--货源表-生效时间
,FORMAT(ss.Effective_DisableDate,'yyyy-MM-dd') SS_DisableDate--货源表-失效时间
,p.PurchaseBatchQty MPQ--MPQ
,p.MinRcvQty MOQ--MOQ
--料品交叉
,si.ID SIID
,si.SupplierItemCode,si1.SupplierItemName--原厂品牌型号
,si.DescFlexField_PrivateDescSeg1 IsActive--物料承认
,si.DescFlexField_PrivateDescSeg2 ActiveStatus--承认状态
,si.DescFlexField_PrivateDescSeg3 Activer--承认人
,si.DescFlexField_PrivateDescSeg4 ActiveDate--承认生效日期
--,si.SupplyLeadTime--供货周期
--,si.InspectLeadTime--检验周期
--,si.SupplyLeadTime--供货周期
--,si.InspectLeadTime--检验周期
--,mi.PurForwardProcessLT--采购预提前期--订单处理周期
,mi.PurProcessLT SupplyLeadTime--供货周期--采购处理提前期
,mi.PurBackwardProcessLT InspectLeadTime--采购后提前期--检验周期
,CASE WHEN si.Effective_IsEffective=1 THEN '1' ELSE '0' END  SI_IsEffective--交叉表-是否生效
,FORMAT(si.Effective_EffectiveDate,'yyyy-MM-dd') SI_EffectiveDate--交叉表-生效时间
,FORMAT(si.Effective_DisableDate,'yyyy-MM-dd') SI_DisableDate--交叉表-失效时间
FROM dbo.CBO_ItemMaster a
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID  
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_PurchaseInfo p ON a.ID=p.ItemMaster
LEFT JOIN dbo.CBO_MrpInfo mi ON mi.ItemMaster=a.ID
LEFT JOIN dbo.CBO_SupplySource ss ON a.ID=ss.ItemInfo_ItemID AND ss.Org=a.Org
LEFT JOIN dbo.CBO_Supplier s ON ss.SupplierInfo_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND ISNULL(s1.SysMLFlag,'zh-cn')='zh-cn' AND s.Org=a.Org
LEFT JOIN dbo.CBO_SupplierItem si ON a.ID=si.ItemInfo_ItemID AND si.SupplierInfo_Supplier=s.ID AND si.Org=a.Org
LEFT JOIN dbo.CBO_SupplierItem_Trl si1 ON si1.ID=si.ID AND ISNULL(si1.SysMLFlag,'zh-cn')='zh-cn'
WHERE 1=1
AND a.Effective_IsEffective=1
AND a.Org=1001708020135665
AND ISNULL(s.ID,'')<>''
AND ISNULL(ss.ID,'')<>''
--AND a.Code LIKE '3%'
AND a.ItemFormAttribute=9
--AND a.Code='335080289'
--货源表和交叉表生效时间


GO
