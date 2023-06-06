/*
���̼�Ŀ����
*/
ALTER VIEW v_Cust_PurPriceLine4OA
as
SELECT * FROM (
SELECT 
b.ID--��ID  Ψһֵ
,a.ID PriceListID--�۱�ID
,a.Code--�۱����
,o.ID OrgID,o.Code OrgCode,o1.Name OrgName--��֯��Ϣ
,a.Supplier SupplierID,s.Code SupplierCode,s1.Name SupplierName--��Ӧ����Ϣ
,a.SupplierSite--��Ӧ��λ��
,a.Currency CurrencyID,cur.Code CurrencyCode,cur1.Name CurrencyName--����
,a.IsIncludeTax--�Ƿ�˰
,a.PricePerson--�۸�Ա
,a.Status--״̬
,dbo.F_GetEnumName('UFIDA.U9.PPR.Enums.Status',a.Status,'zh-CN')StatusName--״̬
,a.Cancel_Canceled--�Ƿ�����
,CASE WHEN a.Cancel_Canceled=1 THEN '����' ELSE '' END Cancel_CanceledName--�Ƿ�����
,a.DescFlexField_PrivateDescSeg1--�۱�����
,a1.Discription --��ע
,b.DocLineNo--�к�
,b.FromDate--��Ч����
,b.ToDate--ʧЧ����
,b.ItemInfo_ItemID
,m.Code ItemInfo_ItemCode
,m.Name ItemInfo_ItemName
,m.SPECS
,b.Price--�۸�
,CASE WHEN b.Active=1 THEN '��' ELSE '' END ActiveName--��Ч
,b.Active
,b.Manufacturer--����
,b.Uom PurchaseUomID
,b.SrcDoc,b.SrcDocNo,b.SrcDoclineNo--��Դ����
,ROW_NUMBER() OVER(PARTITION BY a.Supplier,b.ItemInfo_ItemID,b.Active,a.Cancel_Canceled,a.IsIncludeTax,a.Currency ORDER BY b.ToDate DESC)RN
FROM  dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
INNER JOIN dbo.PPR_PurPriceList_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_Supplier s ON a.Supplier=s.ID
INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Currency cur ON a.Currency=cur.ID
INNER JOIN dbo.Base_Currency_Trl cur1 ON cur.ID=cur1.ID AND cur1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
WHERE 1=1
--AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
--AND b.ItemInfo_ItemCode='336030010'
--AND s.Code='2.CHXB.001'
) t 
WHERE t.Cancel_Canceled=0 AND t.Active=1 AND t.RN=1



