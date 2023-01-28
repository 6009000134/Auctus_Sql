
SELECT DISTINCT mrp.Name MRPName,a.Code,m2.Name,m2.SPECS,a.MasterCode ProductCode,m.Name ProductName
INTO #TempTable
FROM dbo.Auctus_NewestBom a LEFT JOIN dbo.CBO_ItemMaster m ON a.MasterCode=m.code AND m.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.CBO_ItemMaster m2 ON a.Code=m2.Code AND m2.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.vw_MRPCategory mrp ON m2.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE 1=1 AND a.MasterCode LIKE '1%' AND a.Code IN (
SELECT DISTINCT FORMAT(料号,'###') FROM dbo.Tempp11)

SELECT DISTINCT a.MRPName MRP分类,a.Code 料号,a.Name 品名,a.SPECS 规格
--,a.ProductCode  BOM料号
--,a.ProductName BOM品名
,(SELECT b.ProductCode+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) 成品料号
,(SELECT b.ProductName+'||' FROM #TempTable b WHERE b.code=a.Code FOR XML PATH('')) 成品品名
FROM #TempTable a 

