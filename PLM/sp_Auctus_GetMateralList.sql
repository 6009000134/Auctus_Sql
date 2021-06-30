/*
物料库-料品列表
*/
ALTER  PROC [dbo].[sp_Auctus_GetMateralList]
(
@pageSize INT,
@pageIndex INT,
@Code VARCHAR(MAX),
@Name NVARCHAR(30),
@Brands NVARCHAR(300),
@CategoryName NVARCHAR(30)
)
AS
BEGIN


SET @Name='%'+ISNULL(@Name,'')+'%'
SET @CategoryName='%'+ISNULL(@CategoryName,'')+'%'
SET @Brands='%'+ISNULL(@Brands,'')+'%'
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT=@pageSize*@pageIndex+1
IF CHARINDEX(',',@Code)>0--料号用逗号“,"隔开代表：批量查询
BEGIN	
	SELECT *,CASE WHEN t.IsFrozen=0 THEN '否' ELSE '是'END IsFrozenName FROM (
	SELECT * ,
	ROW_NUMBER()OVER(ORDER BY CreateDate desc) RN
	FROM (
	SELECT                         
	MaterialVerId ,Code  ,Name  ,Spec  ,Patent  ,VerCode  ,IntProductMode  ,Creator  ,CreateDate  ,Count  ,CategoryName  ,IsVirtualDesign  ,TypeName  ,
	IsImportERP ,IsFrozen						
	,STUFF((SELECT '/'+t.Name FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH('')),1,1,'')
	PropertyValue,
	CASE WHEN PATINDEX('30701%',a.Code)>0 OR PATINDEX('30801%',a.Code)>0 THEN '否'
	WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>1
	THEN '否' 
	ELSE '是' END IsOnlyOne
	FROM      v_MAT_MaterialVersion a 
	WHERE     1=1
	AND a.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Code))					
	AND PATINDEX(@Name,a.Name)>0
	AND PATINDEX(@CategoryName,a.CategoryName)>0
	AND ArticleType = 0	
	AND IsEffect = 1
	AND TypeId = '3'
	AND FactoryId = ''                        
	AND LanguageId = 0	
	)	t WHERE PATINDEX(@Brands,ISNULL(t.PropertyValue,''))>0
	) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
	
	--统计数量
	SELECT COUNT(1)Count FROM 
	(
	SELECT    a.MaterialVerId,(SELECT '/'+t.Name FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH(''))
	PropertyValue  
	FROM      v_MAT_MaterialVersion a 
	WHERE     1=1
	AND a.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Code))					
	AND PATINDEX(@Name,a.Name)>0
	AND PATINDEX(@CategoryName,a.CategoryName)>0
	AND ArticleType = 0	
	AND IsEffect = 1
	AND TypeId = '3'
	AND FactoryId = ''                        
	AND LanguageId = 0	
	) t WHERE PATINDEX(@Brands,ISNULL(t.PropertyValue,''))>0

END
ELSE
BEGIN
	SET @Code='%'+ISNULL(@Code,'')+'%'
	SELECT *,CASE WHEN t.IsFrozen=0 THEN '否' ELSE '是'END IsFrozenName FROM (
	SELECT * ,
	ROW_NUMBER()OVER(ORDER BY CreateDate desc) RN
	FROM (
	SELECT                         
	MaterialVerId ,Code  ,Name  ,Spec  ,Patent  ,VerCode  ,IntProductMode  ,Creator  ,CreateDate  ,Count  ,CategoryName  ,IsVirtualDesign  ,TypeName  ,
	IsImportERP ,IsFrozen						
	,STUFF((SELECT '/'+t.Name FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH('')),1,1,'')
	PropertyValue,
	CASE WHEN PATINDEX('30701%',a.Code)>0 OR PATINDEX('30801%',a.Code)>0 THEN '否'
	WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>1
	THEN '否' ELSE '是' END IsOnlyOne
	FROM      v_MAT_MaterialVersion a 
	WHERE     1=1
	AND PATINDEX(@Code,a.Code)>0
	AND PATINDEX(@Name,a.Name)>0
	AND PATINDEX(@CategoryName,a.CategoryName)>0
	AND ArticleType = 0	
	AND IsEffect = 1
	AND TypeId = '3'
	AND FactoryId = ''                        
	AND LanguageId = 0	
	)	t WHERE PATINDEX(@Brands,ISNULL(t.PropertyValue,''))>0
	) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
	
	--统计数量
	SELECT COUNT(1)Count FROM (
	SELECT    a.MaterialVerId,(SELECT '/'+t.Name FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH(''))
	PropertyValue  
	FROM      v_MAT_MaterialVersion a 
	WHERE     1=1
	AND PATINDEX(@Code,a.Code)>0
	AND PATINDEX(@Name,a.Name)>0
	AND PATINDEX(@CategoryName,a.CategoryName)>0
	AND ArticleType = 0	
	AND IsEffect = 1
	AND TypeId = '3'
	AND FactoryId = ''                        
	AND LanguageId = 0	
	)t WHERE PATINDEX(@Brands,ISNULL(t.PropertyValue,''))>0
END 	

END 