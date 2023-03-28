
SELECT DISTINCT mrp.Name MRPName,a.Code,m2.Name,m2.SPECS,a.MasterCode ProductCode,m.Name ProductName
,m.DescFlexField_PrivateDescSeg20 ProjectCode,(SELECT a.Name FROM dbo.v_Cust_KeyValue WHERE GroupCode='RDProject' AND Code=m.DescFlexField_PrivateDescSeg20) ProjectName
INTO #TempTable
FROM dbo.Auctus_NewestBom a LEFT JOIN dbo.CBO_ItemMaster m ON a.MasterCode=m.code AND m.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.CBO_ItemMaster m2 ON a.Code=m2.Code AND m2.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.vw_MRPCategory mrp ON m2.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE 1=1 AND a.MasterCode LIKE '1%' AND a.Code IN (
SELECT code FROM dbo.CBO_ItemMaster WHERE org=(SELECT id FROM dbo.Base_Organization WHERE code='300') AND Effective_IsEffective=1)

;
WITH WHInfo AS
(
SELECT code,SUM(BalQty)WH FROM dbo.v_Cust_InvInfo4OA GROUP BY Code
),
ReqInfo AS
(
SELECT code,SUM(ReqQty)ReqQty FROM dbo.Auctus_FullSetCheckResult8 WHERE CopyDate>'2023-02-06'
GROUP BY Code
)
SELECT DISTINCT a.MRPName MRP分类,a.Code 料号,a.Name 品名,a.SPECS 规格
--,a.ProductCode  BOM料号
--,a.ProductName BOM品名
,(SELECT b.ProductCode+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) 成品料号
,(SELECT b.ProductName+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) 成品品名
,(SELECT b.ProjectCode+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) 成品项目编码
,(SELECT b.ProjectName+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) 成品项目名称
,(SELECT t.WH FROM WHInfo t WHERE t.code=a.Code)库存
,(SELECT t.ReqQty FROM ReqInfo t WHERE t.code=a.Code)八周需求
FROM #TempTable a 
ORDER BY a.Code



