/*
将料品-厂牌关系更新到料品扩展字段“品牌/型号”中去，厂牌以/分隔
*/
CREATE PROC sp_Auctus_UpdateBrandExtend
AS
BEGIN

--更新料品-厂牌数据 与扩展字段数据不一致的
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN
	DROP TABLE #TempTable
END 


;
WITH HasBrand AS--料品-厂牌数据
(
SELECT c.MaterialVerId,c.Code,c.Name,a.Name BrandName,b.ParentVerId,b.State,a.Status FROM dbo.MAT_Brands a INNER JOIN MAT_BrandsMaterialRelation b ON a.BrandsId=b.BrandsId
INNER JOIN dbo.MAT_MaterialVersion c ON b.MaterialVerId=c.MaterialVerId AND ISNULL(b.ParentVerId,'')=''
),
Mat AS
(
SELECT a.MaterialVerId,a.Code,a.Name,a.VerCode 
FROM dbo.MAT_MaterialVersion a WHERE a.IsEffect=1
AND PATINDEX('3%',a.Code)>0
),
ExtendData AS--有扩展字段的料品
(
SELECT a.*,b.ExtendName FROM dbo.MAT_Extend a INNER JOIN dbo.PS_ExtendSettings b ON a.SettingsId=b.SettingsId
WHERE b.ExtendName='品牌/型号' 
),
NoneExtendData AS--有料品-厂牌数据，但是没有扩展字段料品数据
(
SELECT * FROM HasBrand a LEFT JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
WHERE ISNULL(b.ObjectExtendId,'')=''
),
BrandList AS
(
SELECT DISTINCT a.MaterialVerId,a.Code,a.Name,STUFF((SELECT '/'+b.BrandName FROM HasBrand b WHERE b.MaterialVerId=a.MaterialVerId FOR XML PATH('')),1,1,'')BrandList FROM HasBrand a
)
SELECT a.*,b.ObjectExtendId,b.PropertyValue
,CASE WHEN ISNULL(b.ObjectExtendId,'')='' THEN 'Add' ELSE 'Update' END OperateType
INTO #TempTable
FROM BrandList a 
LEFT JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
WHERE a.BrandList<>ISNULL(b.PropertyValue,'') 



IF EXISTS(SELECT 1 FROM #TempTable a WHERE a.OperateType='Update')
BEGIN
	UPDATE dbo.MAT_Extend SET PropertyValue=a.BrandList 
	FROM #TempTable a 
	WHERE a.OperateType='Update' AND a.ObjectExtendId=dbo.MAT_Extend.ObjectExtendId
END 



IF EXISTS(SELECT 1 FROM #TempTable a WHERE a.OperateType='Add')
BEGIN
	;
	WITH AddData AS--插入扩展字段数据集合
	(
	SELECT * FROM #TempTable a WHERE a.OperateType='Add'
	)
	INSERT INTO dbo.MAT_Extend
	        ( ObjectExtendId ,
	          SettingsId ,
	          ObjectId ,
	          PropertyValue
	        )
	SELECT NEWID(),e.SettingsId,a.MaterialVerId,m.BrandList
	FROM dbo.MAT_MaterialVersion a INNER JOIN AddData m ON a.MaterialVerId=m.MaterialVerId LEFT JOIN dbo.MAT_MaterialBase b ON a.BaseId=b.BaseId
	LEFT JOIN dbo.PS_BusinessCategory c ON b.CategoryId=c.CategoryId 
	LEFT JOIN dbo.PS_ExtendSettings e ON c.CategoryId=e.CategoryId
	WHERE ISNULL(e.ExtendName,'')='品牌/型号'
END 

END 