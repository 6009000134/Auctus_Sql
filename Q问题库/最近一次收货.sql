--SELECT  *
--FROM    temp11 
;
WITH data1 AS
(
SELECT s.Code SCode,s1.name SName,m.Code,m.Name,s.DescFlexField_PrivateDescSeg3,b.ConfirmDate,ROW_NUMBER()OVER(PARTITION BY m.Code ORDER BY b.ConfirmDate desc) rn
,b.RcvQtyTU
 FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
 INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
 INNER JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID
 INNER JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND s1.SysMLFlag='zh-cn'
 INNER JOIN temp11 d ON m.code=d.code
WHERE b.ConfirmDate>='2022-10-24' AND b.ConfirmDate<'2022-11-07'
AND s.DescFlexField_PrivateDescSeg3='WAI02'
)
SELECT t.SCode ��Ӧ�̱���,t.SName ��Ӧ������,t.Code �Ϻ�,t.Name Ʒ��,t.DescFlexField_PrivateDescSeg3 �ⲿ��ʶ,t.ConfirmDate ȷ��ʱ��,t.rn,t.RcvQtyTU ���һ���ջ�����
,(SELECT SUM(a.RcvQtyTU) FROM data1 a WHERE a.Code=t.Code) �ۼ��ջ�����
FROM data1 t WHERE t.rn=1

