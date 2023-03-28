--SELECT 
--s.Name 供应商,CASE WHEN MIN(s1.DescFlexField_PrivateDescSeg3) IN ('NEI01','OT01') THEN '内' ELSE '外' END 内外供应商
--,b.ItemInfo_ItemCode 料号,CONVERT(INT,SUM(CASE WHEN a.ReceivementType=0 THEN b.RcvQtyTU ELSE (-1)*b.RejectQtyTU END ))RcvQty
--FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
--LEFT JOIN dbo.CBO_Supplier_Trl s ON a.Supplier_Supplier=s.ID AND s.SysMLFlag='zh-cn'
--LEFT JOIN CBO_Supplier s1 ON a.Supplier_Supplier=s1.ID
--WHERE 1=1
--AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
--AND b.ConfirmDate>=DATEADD(YEAR,-1,GETDATE()) AND b.ConfirmDate<=GETDATE()
--AND a.ReceivementType IN (0,1)
----AND a.ReceivementType=1
--GROUP BY a.Supplier_Supplier,b.ItemInfo_ItemCode,s.Name
--ORDER BY b.ItemInfo_ItemCode


;
WITH data1 AS
(
SELECT * FROM (
SELECT 
DISTINCT o.Code OrgCode,o.ID OrgID,op.Code OpCode,a.DescFlexField_PrivateDescSeg4 SourcingCode
,SUBSTRING(a.DescFlexField_PrivateDescSeg4,1,2)oo
,CASE WHEN SUBSTRING(a.DescFlexField_PrivateDescSeg4,1,2)+'0'=o.Code THEN '1' ELSE '0' END Flag
FROM dbo.CBO_Supplier a
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID
LEFT JOIN dbo.CBO_Operators op ON a.Purchaser=op.ID
)t  WHERE t.flag=0 AND t.SourcingCode!=''
)
SELECT s.ID,s.Code,s1.Name,b.*,op1.Name OpName FROM CBO_Supplier s  LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
INNER JOIN data1 b ON s.Org=b.OrgID AND s.DescFlexField_PrivateDescSeg4=b.SourcingCode
AND b.OrgCode='300'
LEFT JOIN dbo.CBO_Operators op ON b.SourcingCode=op.Code
LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.id=op1.id AND op1.SysMLFlag='zh-cn'


