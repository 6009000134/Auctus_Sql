;
WITH Materials AS
(
SELECT a.MaterialVerId,a.Code,a.Name FROM dbo.MAT_MaterialVersion a WHERE a.IsFrozen=0 AND a.IsEffect=1 --AND a.Code='309050179'
AND PATINDEX('3%',a.Code)>0 --AND a.Code='307040008'
--SELECT a.MaterialVerId,a.Code,a.Name FROM dbo.MAT_MaterialVersion a WHERE a.IsEffect=1 AND a.code='331010003'
),
HasBrand AS
(
SELECT a.BrandsId,a.Name,b.MaterialVerId FROM dbo.MAT_Brands a INNER JOIN dbo.MAT_BrandsMaterialRelation b ON a.BrandsId=b.BrandsId 
INNER JOIN Materials c ON b.MaterialVerId=c.MaterialVerId
WHERE ISNULL(b.ParentVerId,'')=''
),
ExtendValue AS
(
SELECT a.ObjectExtendId,a.ObjectId,a.PropertyValue
FROM dbo.MAT_Extend a INNER JOIN dbo.PS_ExtendSettings b ON a.SettingsId=b.SettingsId WHERE b.ExtendName='品牌/型号'
),
NoExtendValue AS
(
SELECT a.MaterialVerId,a.Code,b.ObjectId,b.PropertyValue M2 FROM Materials a LEFT JOIN ExtendValue b ON a.MaterialVerId=b.ObjectId
WHERE ISNULL(b.ObjectId,'')=''
),
Result AS
(
SELECT c.Code,c.Name,a.Name Brand FROM HasBrand a INNER  JOIN NoExtendValue b ON a.MaterialVerId=b.MaterialVerId
LEFT JOIN dbo.MAT_MaterialVersion c ON a.MaterialVerId=c.MaterialVerId AND c.IsEffect=1
)
--SELECT * FROM HasBrand
--SELECT * FROM NoExtendValue
SELECT * INTO #TempTable FROM (
SELECT DISTINCT a.Code,a.Name,(SELECT b.Brand+'/' FROM Result b WHERE b.Code=a.Code FOR XML PATH(''))Brand   FROM Result a
) t


SELECT * FROM #TempTable


--SELECT * FROM Result a WHERE a.Code='331010003'



--;
--WITH data1 AS
--(
--SELECT a.MaterialVerId,a.Code,a.Name,b.Brand FROM dbo.MAT_MaterialVersion a INNER JOIN #TempTable b ON a.Code=b.Code
--WHERE a.IsEffect=1
--),
--Extend AS
--(
--SELECT a.ObjectExtendId,a.ObjectId,a.PropertyValue,b.*
--FROM dbo.MAT_Extend a INNER JOIN dbo.PS_ExtendSettings b ON a.SettingsId=b.SettingsId WHERE b.ExtendName='品牌/型号'
--)
--SELECT a.Brand,b.ObjectExtendId,b.ObjectId --INTO #TempTable 
----*
--FROM data1 a INNER JOIN extend b ON a.MaterialVerId=b.ObjectId


