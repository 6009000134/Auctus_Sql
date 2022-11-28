;
WITH data1 AS 
(
SELECT DISTINCT mrp.Name MRPName,a.Code,m2.Name,m2.SPECS,a.MasterCode ProductCode,m.Name ProductName
FROM dbo.Auctus_NewestBom a LEFT JOIN dbo.CBO_ItemMaster m ON a.MasterCode=m.code AND m.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.CBO_ItemMaster m2 ON a.Code=m2.Code AND m2.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
LEFT JOIN dbo.vw_MRPCategory mrp ON m2.DescFlexField_PrivateDescSeg22=mrp.Code
WHERE 1=1 AND a.MasterCode LIKE '1%' AND a.Code IN (
'332030079',
'332060039',
'202010696',
'326010054',
'204010275',
'204010273',
'329010189',
'334010095',
'307011777',
'204010272',
'336090015',
'333140046',
'332030078',
'314020158',
'202020550',
'333130006',
'332120023',
'403010352',
'336040043',
'306010732',
'307030113',
'315010077',
'310040088',
'332070180',
'307011796',
'204010276',
'334020078',
'319130037',
'333110057',
'336020026',
'202010736',
'332020094',
'335030141',
'307011697',
'314020118',
'332030081',
'333100132',
'332020072',
'308010330',
'202010697',
'336060015',
'336030013',
'310040090',
'202020616',
'333090096',
'308010740',
'306010648',
'335120013',
'309050170',
'336080011',
'308010720'
)
)
SELECT DISTINCT a.MRPName MRP分类,a.Code 料号,a.Name 品名,a.SPECS 规格,(SELECT b.ProductCode+'||' FROM data1 b WHERE b.code=a.Code FOR XML PATH('')) 成品料号
,(SELECT b.ProductName+'||' FROM data1 b WHERE b.code=a.Code FOR XML PATH('')) 成品品名
,(SELECT b.ProductName+'||' FROM data1 b WHERE b.code=a.Code AND (PATINDEX('%八哥%',b.ProductName)=0 AND PATINDEX('%BG200%',b.ProductName)=0) FOR XML PATH('')) 成品品名不含八哥
FROM data1 a 

