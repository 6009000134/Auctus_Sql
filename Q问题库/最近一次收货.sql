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
SELECT t.SCode 供应商编码,t.SName 供应商名称,t.Code 料号,t.Name 品名,t.DescFlexField_PrivateDescSeg3 外部标识,t.ConfirmDate 确认时间,t.rn,t.RcvQtyTU 最近一次收货数量
,(SELECT SUM(a.RcvQtyTU) FROM data1 a WHERE a.Code=t.Code) 累计收货数量
FROM data1 t WHERE t.rn=1

