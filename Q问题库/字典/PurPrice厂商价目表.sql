--���̼�Ŀ��
SELECT 
a.ID,a.Code
,a.Supplier SupplierID,s.Code SupplierCode,s1.Name SupplierName--��Ӧ����Ϣ
,a.SupplierSite--��Ӧ��λ��
,a.Currency CurrencyID,cur.Code CurrencyCode,cur1.Name CurrencyName--����
,a.IsIncludeTax--�Ƿ�˰
,a.PricePerson--�۸�Ա
,a.Status--״̬
,dbo.F_GetEnumName('UFIDA.U9.PPR.Enums.Status',a.Status,'zh-CN')StatusName--״̬
,a.Cancel_Canceled--�Ƿ�����
,CASE WHEN a.Cancel_Canceled=1 THEN '����' ELSE '' END ����--�Ƿ�����
,a.DescFlexField_PrivateDescSeg1--�۱�����
,a1.Discription --��ע
,b.ID LineID--��ID
,b.DocLineNo--�к�
,b.FromDate--��Ч����
,b.ToDate--ʧЧ����
,b.ItemInfo_ItemCode
,b.Price--�۸�
,CASE WHEN b.Active=1 THEN '��' ELSE '' END �Ƿ���Ч--��Ч
,b.Active
,b.Manufacturer--����
,b.SrcDoc,b.SrcDocNo,b.SrcDoclineNo--��Դ����
FROM  dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
INNER JOIN dbo.PPR_PurPriceList_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_Supplier s ON a.Supplier=s.ID
INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Currency cur ON a.Currency=cur.ID
INNER JOIN dbo.Base_Currency_Trl cur1 ON cur.ID=cur1.ID AND cur1.SysMLFlag='zh-cn'
WHERE a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND b.ItemInfo_ItemCode='336030010'
AND s.Code='2.CHXB.001'


--�۱�����
SELECT t.*,s.OrderNO ,CASE WHEN t.δ˰�۸�����=ISNULL(s.OrderNO,0) THEN '��' ELSE '��' END �Ƿ�һ��
FROM (SELECT t.Name ��֯ ,t.ItemInfo_ItemCode �Ϻ�,t.CreatedOn ����ʱ��,t.ModifiedOn �޸�ʱ��,t.FromDate ��Ч����,t.ToDate ʧЧ����,t.SupplierName ��Ӧ������ ,
CASE WHEN t.IsIncludeTax =1 THEN '��' ELSE '��' END �Ƿ�˰
,t.CurName ����,t.Price �۸� ,t.NetPrice δ˰��_�����
,ROW_NUMBER()OVER(PARTITION BY t.name,t.ItemInfo_ItemCode ORDER BY t.NetPrice)δ˰�۸����� 
,t.Supplier,t.ItemInfo_ItemID
FROM 
(
SELECT 
o1.Name,a.Supplier,s1.Name SupplierName,a.IsIncludeTax,b.ItemInfo_ItemID,b.ItemInfo_ItemCode,b.Price,b.CreatedOn,b.ModifiedOn
,a.Currency,cur.Name CurName
,b.FromDate,b.ToDate
,CASE WHEN a.currency=1 AND  a.IsIncludeTax = 1 
 THEN ISNULL(Price, 0)/1.13
 WHEN a.Currency=1 AND a.IsIncludeTax=0
 THEN ISNULL(Price, 0)
 WHEN a.Currency!=1 AND a.IsIncludeTax=1
 THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a.Currency, 1, GETDATE(), 2)/1.13
 ELSE
 ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a.Currency, 1, GETDATE(), 2) END NetPrice
,ROW_NUMBER() OVER(PARTITION BY a.Org,a.Supplier,b.ItemInfo_ItemID ORDER BY b.FromDate) RN
FROM dbo.PPR_PurPriceList a INNER JOIN dbo.PPR_PurPriceLine b ON a.ID=b.PurPriceList
LEFT JOIN dbo.CBO_Supplier s ON a.Supplier=s.ID 
LEFT JOIN dbo.CBO_Supplier_Trl s1 ON a.Supplier=s1.ID AND s1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization_Trl o1 ON a.Org=o1.ID AND o1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Currency_Trl cur ON a.Currency=cur.ID AND cur.SysMLFlag='zh-cn'
WHERE b.Active=1 AND GETDATE()BETWEEN b.FromDate AND b.ToDate AND a.Cancel_Canceled=0
AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND s.DescFlexField_PrivateDescSeg3 NOT IN ('NEI01','OT01')
)t  
WHERE t.RN=1
)t
LEFT JOIN dbo.CBO_SupplySource s ON t.Supplier=s.SupplierInfo_Supplier AND t.ItemInfo_ItemID=s.ItemInfo_ItemID
ORDER BY t.��֯,t.�Ϻ�
--ORDER BY a.Org,b.ItemInfo_ItemID
