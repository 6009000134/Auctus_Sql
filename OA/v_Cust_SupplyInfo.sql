
/*
��Դ����Ӧ��-��Ʒ������Ϣ
*/
alter VIEW v_Cust_SupplyInfo
as
SELECT 
ROW_NUMBER()OVER(ORDER BY a.Code,ss.OrderNO)RN
,a.ID,a.Code,a.Name,a.SPECS--�Ϻš�Ʒ�������
,a.Org,o.Code OrgCode,o1.Name OrgName--��֯����
,p.PurchaseQuotaMode,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.PurchaseQuotaModeEnum',p.PurchaseQuotaMode,'zh-cn')Mode--��ʽ
,s.ID Supplier,s.Code SupplierCode,s1.Name SupplierName--��Ӧ������
,ss.ID SSID,ss.OrderNO--�����̻���
,ss.SupplierQuota--������
,ss.IsSmallQtyPurBatch--С������������
,ss.MaxPurQty--�ɹ�����
,ss.PurchaseBatchQty--�ɹ�����
,ss.SupplierStatus
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Supplier.SupplierStatusEnum',ss.SupplierStatus,'zh-cn')SupplierStatusName--��Դ״̬
,ss.Effective_IsEffective SS_IsEffective--��Դ��-�Ƿ���Ч
,ss.Effective_EffectiveDate SS_EffectiveDate--��Դ��-��Чʱ��
,ss.Effective_DisableDate SS_DisableDate--��Դ��-ʧЧʱ��
,p.PurchaseBatchQty MPQ--MPQ
,p.MinRcvQty MOQ--MOQ
--��Ʒ����
,si.ID SIID
,si.SupplierItemCode,si1.SupplierItemName--ԭ��Ʒ���ͺ�
,si.DescFlexField_PrivateDescSeg1 IsActive--���ϳ���
,si.DescFlexField_PrivateDescSeg2 ActiveStatus--����״̬
,si.DescFlexField_PrivateDescSeg3 Activer--������
,si.DescFlexField_PrivateDescSeg4 ActiveDate--������Ч����
,si.SupplyLeadTime--��������
,si.InspectLeadTime--��������
,si.Effective_IsEffective SI_IsEffective--�����-�Ƿ���Ч
,si.Effective_EffectiveDate SI_EffectiveDate--�����-��Чʱ��
,si.Effective_DisableDate SI_DisableDate--�����-ʧЧʱ��
FROM dbo.CBO_ItemMaster a
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID  
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_PurchaseInfo p ON a.ID=p.ItemMaster
LEFT JOIN dbo.CBO_SupplySource ss ON a.ID=ss.ItemInfo_ItemID
LEFT JOIN dbo.CBO_Supplier s ON ss.SupplierInfo_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND ISNULL(s1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_SupplierItem si ON a.ID=si.ItemInfo_ItemID AND si.SupplierInfo_Supplier=s.ID
LEFT JOIN dbo.CBO_SupplierItem_Trl si1 ON si1.ID=si.ID AND ISNULL(si1.SysMLFlag,'zh-cn')='zh-cn'
WHERE 1=1
AND a.Effective_IsEffective=1
AND a.Org=1001708020135665
AND ISNULL(s.ID,'')<>''
AND ISNULL(ss.ID,'')<>''
AND a.Code LIKE '3%'
--AND a.Code='335080289'
--��Դ��ͽ������Чʱ��

GO
