----;
----WITH data1 AS
----(
----SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
----INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
----)
----SELECT a.* FROM data1 a INNER JOIN dbo.MAT_MaterialVersion b ON a.ObjectId=b.MaterialVerId
----WHERE b.IsEffect=1
------SELECT * FROM dbo.MAT_MaterialVersion a WHERE a.IsEffect=1


--SELECT 
--c.MaterialVerId,c.Code,c.Name,c.VerCode,c.IsEffect,c.IsFrozen
--,e.*,'11111' ss,es.* FROM dbo.MAT_Extend e 
--INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
--INNER JOIN dbo.MAT_MaterialVersion c ON e.ObjectId=c.MaterialVerId

--SELECT a.* FROM dbo.MAT_Extend a INNER JOIN dbo.PS_ExtendSettings b ON a.SettingsId=b.SettingsId
--WHERE b.ExtendName='品牌/型号'

--SELECT * FROM dbo.PS_ExtendSettings WHERE ExtendName='品牌/型号'

--SELECT * FROM dbo.PS_ExtendSettings  WHERE ExtendName='品牌/型号'
--;
--WITH data1 AS
--(
--SELECT b.MaterialVerId,a.Name FROM dbo.MAT_Brands a INNER JOIN dbo.MAT_BrandsMaterialRelation b ON a.BrandsId=b.BrandsId
--INNER JOIN dbo.MAT_MaterialVersion c ON b.MaterialVerId=c.MaterialVerId
--WHERE ISNULL(b.ParentVerId,'')='' AND c.IsEffect=1 AND c.IsFrozen=0
--)
--SELECT * FROM data1 a



--SELECT * FROM dbo.PS_BusinessCategory

--SELECT * FROM dbo.MAT_MaterialVersion 
--SELECT * FROM dbo.PS_BusinessCategoryRelation

DROP TABLE #TempTable

;
WITH Materials AS
(
SELECT a.MaterialVerId,a.Code,a.Name FROM dbo.MAT_MaterialVersion a WHERE a.IsFrozen=0 AND a.IsEffect=1 --AND a.Code='309050179'
),
HasBrands AS--有“品牌/型号”扩展字段的 最新、有效、未冻结 料号
(
SELECT c.MaterialVerId,c.Code MaterialCode,c.Name MaterialName,b.CategoryId,s.ExtendName FROM MAT_Auxiliary a INNER JOIN dbo.PS_BusinessCategory b ON a.categoryid=b.CategoryId INNER JOIN dbo.PS_ExtendSettings s ON b.CategoryId=s.CategoryId
INNER JOIN Materials c ON a.MaterialVerId=c.MaterialVerId
WHERE s.ExtendName='品牌/型号'
),
BrandsRelation AS 
(
SELECT a.BrandsId,a.Name,b.MaterialVerId FROM dbo.MAT_Brands a INNER JOIN dbo.MAT_BrandsMaterialRelation b ON a.BrandsId=b.BrandsId 
WHERE ISNULL(b.ParentVerId,'')=''--原材料，过滤BOM中的厂牌信息
),
Brands AS
(
SELECT a.*,b.BrandsId,b.Name FROM HasBrands a INNER JOIN BrandsRelation b ON a.MaterialVerId=b.MaterialVerId
),
BrandsResult AS
(
SELECT DISTINCT a.MaterialVerId,a.CategoryId,(SELECT b.Name+'/' FROM Brands b WHERE b.MaterialVerId=a.MaterialVerId FOR XML PATH('')) Brands
FROM Brands a)
,
ExistsMaterials AS--
(
SELECT a.ObjectExtendId,a.ObjectId,a.PropertyValue,b.ExtendName FROM dbo.MAT_Extend a INNER JOIN dbo.PS_ExtendSettings b ON a.SettingsId=b.SettingsId WHERE b.ExtendName='品牌/型号'
)
SELECT * INTO #TempTable FROM 
(
SELECT a.MaterialVerId,a.CategoryId,SUBSTRING(a.Brands,0,LEN(a.Brands))Brands,ISNULL(b.ObjectId,'0')IsExists,b.ObjectExtendId,c.Code,c.Name 
FROM BrandsResult a LEFT JOIN ExistsMaterials b ON a.MaterialVerId=b.ObjectId  
LEFT JOIN dbo.MAT_MaterialVersion c ON a.MaterialVerId=c.MaterialVerId
WHERE SUBSTRING(a.Brands,0,LEN(a.Brands))<>b.PropertyValue
UNION ALL 
SELECT a.MaterialVerId,a.CategoryId,SUBSTRING(a.Brands,0,LEN(a.Brands))Brands,ISNULL(b.ObjectId,'0')IsExists,b.ObjectExtendId,c.Code,c.Name 
FROM BrandsResult a LEFT JOIN ExistsMaterials b ON a.MaterialVerId=b.ObjectId
LEFT JOIN dbo.MAT_MaterialVersion c ON a.MaterialVerId=c.MaterialVerId
WHERE SUBSTRING(a.Brands,0,LEN(a.Brands))<>b.PropertyValue
) t
SELECT * FROM #TempTable

--UPDATE dbo.MAT_Extend SET PropertyValue=a.Brands FROM #TempTable a WHERE a.ObjectExtendId=dbo.MAT_Extend.ObjectExtendId

--INSERT INTO dbo.MAT_Extend
--        ( ObjectExtendId ,
--          SettingsId ,
--          ObjectId ,
--          PropertyValue
--        )
--SELECT LOWER(NEWID()),b.SettingsId,a.MaterialVerId,a.Brands FROM #TempTable a,dbo.PS_ExtendSettings b  WHERE a.IsExists=0 AND a.CategoryId=b.CategoryId AND b.ExtendName='品牌/型号'
----AND a.Code='311010004'


--SELECT a.*,b.* 
--FROM dbo.MAT_Extend a INNER JOIN dbo.PS_ExtendSettings b ON a.SettingsId=b.SettingsId WHERE b.ExtendName='品牌/型号'

--SELECT *FROM dbo.PS_ExtendSettings WHERE CategoryId='6b22a36e-c30e-45ad-86b0-a4cc547834ad' AND ExtendName='品牌/型号'

--SELECT * FROM dbo.MAT_Brands a INNER JOIN dbo.MAT_BrandsMaterialRelation b ON a.BrandsId=b.BrandsId

