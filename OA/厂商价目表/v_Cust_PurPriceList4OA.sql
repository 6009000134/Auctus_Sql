/*
���̼�Ŀ��
*/
ALTER VIEW v_Cust_PurPriceList4OA
as
SELECT t.* FROM (
SELECT 
a.ID--�۱�ID
,a.Code,a1.Name--�۱����
,o.ID OrgID,o.Code OrgCode,o1.Name OrgName--��֯��Ϣ
,a.Supplier SupplierID,s.Code SupplierCode,s1.Name SupplierName--��Ӧ����Ϣ
,a.SupplierSite--��Ӧ��λ��
,a.Currency CurrencyID,cur.Code CurrencyCode,cur1.Name CurrencyName--����
,a.IsIncludeTax--�Ƿ�˰
,CASE WHEN a.IsIncludeTax=1 THEN '��' ELSE '��' END IsIncludeTaxName --�Ƿ�˰
,a.PricePerson--�۸�Ա
,a.Status--״̬
,dbo.F_GetEnumName('UFIDA.U9.PPR.Enums.Status',a.Status,'zh-CN')StatusName--״̬
,a.Cancel_Canceled--�Ƿ�����
,CASE WHEN a.Cancel_Canceled=1 THEN '����' ELSE '' END Cancel_CanceledName--�Ƿ�����
,a.DescFlexField_PrivateDescSeg1--�۱�����
,a1.Discription --��ע
--,ROW_NUMBER() OVER(PARTITION BY a.Supplier,b.ItemInfo_ItemID,b.Active,a.Cancel_Canceled,a.IsIncludeTax,a.Currency ORDER BY b.ToDate)RN
FROM  dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceList_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_Supplier s ON a.Supplier=s.ID
INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Currency cur ON a.Currency=cur.ID
INNER JOIN dbo.Base_Currency_Trl cur1 ON cur.ID=cur1.ID AND cur1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
WHERE 1=1
) t 
WHERE t.Cancel_Canceled=0 AND t.Status=2
