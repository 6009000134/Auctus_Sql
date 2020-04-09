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

--DECLARE @pageSize INT=10
--DECLARE @pageIndex INT =1
SET @Name='%'+ISNULL(@Name,'')+'%'
SET @CategoryName='%'+ISNULL(@CategoryName,'')+'%'
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT=@pageSize*@pageIndex+1

IF PATINDEX('%,%',ISNULL(@Code,''))>0 OR PATINDEX('%，%',ISNULL(@Code,''))>0--Code中含逗号“，”，批量查询
BEGIN
	SET @Code=REPLACE(@Code,'，',',')
			IF ISNULL(@Brands,'')=''
			BEGIN
				;WITH ExtendData AS
			(
			SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
			INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'			
			)
			SELECT t.*,b.PropertyValue,CASE WHEN CHARINDEX('/',b.PropertyValue)>0 THEN '否' ELSE '是' END IsOnlyOne FROM 
			(
			 SELECT                         
									MaterialVerId ,
									  Code  ,
									Name  ,
									Spec  ,
									Patent  ,
									VerCode  ,
									IntProductMode  ,
									Creator  ,
									CreateDate  ,
									Count  ,
									CategoryName  ,
									IsVirtualDesign  ,
									TypeName  ,
									IsImportERP ,
									IsFrozen,						
									--(SELECT t.Name+'/' FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH(''))
									--PropertyValue,
									--CASE WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>0
									--THEN '否' ELSE '是' END IsOnlyOne,
									ROW_NUMBER()OVER(ORDER BY CreateDate desc) RN
						  FROM      v_MAT_MaterialVersion a 
						  WHERE     ArticleType = 0
									AND a.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Code))
									AND PATINDEX(@Name,Name)>0						
									AND PATINDEX(@CategoryName,CategoryName)>0						
									AND IsEffect = 1
									AND TypeId = '3'
									AND FactoryId = ''                        
									AND LanguageId = 0						
			  ) t LEFT JOIN ExtendData b ON t.MaterialVerId=b.ObjectId
			  WHERE t.RN>@beginIndex AND t.RN<@endIndex
    
			  ;WITH ExtendData AS
			(
			SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
			INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
			)
			  SELECT COUNT(*) Count
						  FROM      v_MAT_MaterialVersion a LEFT JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
						  WHERE     ArticleType = 0
									AND a.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Code))
									AND PATINDEX(@Name,Name)>0
									AND PATINDEX(@CategoryName,CategoryName)>0						
									AND IsEffect = 1
									AND TypeId = '3'
									AND FactoryId = ''                        
									AND LanguageId = 0	
			END 
			ELSE
			BEGIN
			SET @Brands='%'+ISNULL(@Brands,'')+'%'
				;WITH ExtendData AS
			(
			SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
			INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
			WHERE  PATINDEX(@Brands,ISNULL(e.PropertyValue,''))>0
			)
			SELECT * FROM 
			(
			 SELECT                         
									MaterialVerId ,
									  Code  ,
									Name  ,
									Spec  ,
									Patent  ,
									VerCode  ,
									IntProductMode  ,
									Creator  ,
									CreateDate  ,
									Count  ,
									CategoryName  ,
									IsVirtualDesign  ,
									TypeName  ,
									IsImportERP ,
									IsFrozen,
									b.PropertyValue,CASE WHEN CHARINDEX('/',b.PropertyValue)>0 THEN '否' ELSE '是' END IsOnlyOne,
									--(SELECT t.Name+'/' FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH(''))
									--PropertyValue,
									--CASE WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>0
									--THEN '否' ELSE '是' END IsOnlyOne,
									ROW_NUMBER()OVER(ORDER BY CreateDate desc) RN
						  FROM      v_MAT_MaterialVersion a INNER JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
						  WHERE     ArticleType = 0
									AND a.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Code))
									AND PATINDEX(@Name,Name)>0						
									AND PATINDEX(@CategoryName,CategoryName)>0						
									AND IsEffect = 1
									AND TypeId = '3'
									AND FactoryId = ''                        
									AND LanguageId = 0						
			  ) t 
			  WHERE t.RN>@beginIndex AND t.RN<@endIndex
    
			  ;WITH ExtendData AS
			(
			SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
			INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
			WHERE  PATINDEX(@Brands,ISNULL(e.PropertyValue,''))>0
			)
			  SELECT COUNT(*) Count
						  FROM      v_MAT_MaterialVersion a INNER JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
						  WHERE     ArticleType = 0
									AND a.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Code))
									AND PATINDEX(@Name,Name)>0
									AND PATINDEX(@CategoryName,CategoryName)>0						
									AND IsEffect = 1
									AND TypeId = '3'
									AND FactoryId = ''                        
									AND LanguageId = 0	
			END 
END 
ELSE
BEGIN
	SET @Code='%'+ISNULL(@Code,'')+'%'		
			IF ISNULL(@Brands,'')=''
			BEGIN
				;WITH ExtendData AS
			(
			SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
			INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'			
			)
			SELECT t.*,b.PropertyValue,CASE WHEN CHARINDEX('/',b.PropertyValue)>0 THEN '否' ELSE '是' END IsOnlyOne FROM 
			(
			 SELECT                         
									MaterialVerId ,
									  Code  ,
									Name  ,
									Spec  ,
									Patent  ,
									VerCode  ,
									IntProductMode  ,
									Creator  ,
									CreateDate  ,
									Count  ,
									CategoryName  ,
									IsVirtualDesign  ,
									TypeName  ,
									IsImportERP ,
									IsFrozen,						
									--(SELECT t.Name+'/' FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH(''))
									--PropertyValue,
									--CASE WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>0
									--THEN '否' ELSE '是' END IsOnlyOne,
									ROW_NUMBER()OVER(ORDER BY CreateDate desc) RN
						  FROM      v_MAT_MaterialVersion a 
						  WHERE     ArticleType = 0
									AND PATINDEX(@Code,Code)>0
									AND PATINDEX(@Name,Name)>0						
									AND PATINDEX(@CategoryName,CategoryName)>0						
									AND IsEffect = 1
									AND TypeId = '3'
									AND FactoryId = ''                        
									AND LanguageId = 0						
			  ) t LEFT JOIN ExtendData b ON t.MaterialVerId=b.ObjectId
			  WHERE t.RN>@beginIndex AND t.RN<@endIndex
    
			  ;WITH ExtendData AS
			(
			SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
			INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
			)
			  SELECT COUNT(*) Count
						  FROM      v_MAT_MaterialVersion a LEFT JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
						  WHERE     ArticleType = 0
									AND PATINDEX(@Code,Code)>0
									AND PATINDEX(@Name,Name)>0
									AND PATINDEX(@CategoryName,CategoryName)>0						
									AND IsEffect = 1
									AND TypeId = '3'
									AND FactoryId = ''                        
									AND LanguageId = 0	
			END 
			ELSE
			BEGIN
			SET @Brands='%'+ISNULL(@Brands,'')+'%'
				;WITH ExtendData AS
			(
			SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
			INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
			WHERE  PATINDEX(@Brands,ISNULL(e.PropertyValue,''))>0
			)
			SELECT * FROM 
			(
			 SELECT                         
									MaterialVerId ,
									  Code  ,
									Name  ,
									Spec  ,
									Patent  ,
									VerCode  ,
									IntProductMode  ,
									Creator  ,
									CreateDate  ,
									Count  ,
									CategoryName  ,
									IsVirtualDesign  ,
									TypeName  ,
									IsImportERP ,
									IsFrozen,
									b.PropertyValue,CASE WHEN CHARINDEX('/',b.PropertyValue)>0 THEN '否' ELSE '是' END IsOnlyOne,
									--(SELECT t.Name+'/' FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH(''))
									--PropertyValue,
									--CASE WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>0
									--THEN '否' ELSE '是' END IsOnlyOne,
									ROW_NUMBER()OVER(ORDER BY CreateDate desc) RN
						  FROM      v_MAT_MaterialVersion a INNER JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
						  WHERE     ArticleType = 0
									AND PATINDEX(@Code,Code)>0
									AND PATINDEX(@Name,Name)>0						
									AND PATINDEX(@CategoryName,CategoryName)>0						
									AND IsEffect = 1
									AND TypeId = '3'
									AND FactoryId = ''                        
									AND LanguageId = 0						
			  ) t 
			  WHERE t.RN>@beginIndex AND t.RN<@endIndex
    
			  ;WITH ExtendData AS
			(
			SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
			INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
			WHERE  PATINDEX(@Brands,ISNULL(e.PropertyValue,''))>0
			)
			  SELECT COUNT(*) Count
						  FROM      v_MAT_MaterialVersion a INNER JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
						  WHERE     ArticleType = 0
									AND PATINDEX(@Code,Code)>0
									AND PATINDEX(@Name,Name)>0
									AND PATINDEX(@CategoryName,CategoryName)>0						
									AND IsEffect = 1
									AND TypeId = '3'
									AND FactoryId = ''                        
									AND LanguageId = 0	
			END 
END 



END 
          