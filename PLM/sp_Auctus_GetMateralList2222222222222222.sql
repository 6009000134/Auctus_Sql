/*
物料库-料品列表
*/

DECLARE @pageSize INT=10000,
@pageIndex INT=1,
@Code VARCHAR(50),
@Name NVARCHAR(30)
BEGIN

--DECLARE @pageSize INT=10
--DECLARE @pageIndex INT =1
SET @Code='%'+ISNULL(@Code,'')+'%'
SET @Name='%'+ISNULL(@Name,'')+'%'
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT=@pageSize*@pageIndex+1

;WITH ExtendData AS
(
SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e 
INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
)
 SELECT                         
                        MaterialVerId ,
						  a.Code  ,
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
						--b.PropertyValue,CASE WHEN CHARINDEX('/',b.PropertyValue)>0 THEN '否' ELSE '是' END IsOnlyOne,
						ISNULL((SELECT t.Name+'/' FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH('')),b.PropertyValue)
						PropertyValue,
						CASE WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>0
						OR CHARINDEX('/',b.PropertyValue)>0
						THEN '否' ELSE '是' END IsOnlyOne,
						ROW_NUMBER()OVER(ORDER BY CreateDate desc) RN
              FROM      v_MAT_MaterialVersion a INNER JOIN Test227 c ON a.Code=FORMAT(c.Code,'########') LEFT JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
              WHERE     ArticleType = 0
						AND PATINDEX(@Code,a.Code)>0
						AND PATINDEX(@Name,Name)>0
                        AND IsEffect = 1
                        AND TypeId = '3'
                        AND FactoryId = ''                        
                        AND LanguageId = 0	


  END 
          