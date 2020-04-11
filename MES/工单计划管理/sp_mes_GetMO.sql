/*
MES系统，获取U9工单信息 ，此存储过程用于跨库连接数据
*/
ALTER  PROC sp_mes_GetMO
(
@WorkOrder NVARCHAR(MAX),
@MRPCategory VARCHAR(200)
)
AS
BEGIN

--DECLARE @WorkOrder NVARCHAR(MAX)

SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
SET @MRPCategory='%'+ISNULL(@MRPCategory,'')+'%'

 --料品扩展字段的值集
 IF object_id('tempdb.dbo.#tempDefineValue') is NULL
 CREATE TABLE #tempDefineValue(Code VARCHAR(50),Name NVARCHAR(255),Type VARCHAR(50))
 ELSE
 TRUNCATE TABLE #tempDefineValue
 --MRP分类值集
 INSERT INTO #tempDefineValue
         ( Code, Name, Type )
SELECT T.Code,T.Name,'MRPCategory' FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='MRPCategory') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T 

   SELECT a.DocNo,a.ProductQty,a.TotalStartQty,a.TotalCompleteQty,b.Code,b.Name,mrp.Code MRPCategoryCode,mrp.Name MRPCategoryName
   ,o1.Name MCName
   FROM MO_MO a INNER JOIN dbo.CBO_ItemMaster b ON a.ItemMaster=b.ID
   LEFT JOIN #tempDefineValue mrp ON b.DescFlexField_PrivateDescSeg22=mrp.Code
   LEFT JOIN dbo.CBO_Operators o ON b.DescFlexField_PrivateDescSeg24=o.Code LEFT JOIN dbo.CBO_Operators_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cm')='zh-cn'
   WHERE 1=1 
   AND PATINDEX('WMO%',a.DocNo)=0 
   AND PATINDEX('VMO%',a.DocNo)=0 
   AND PATINDEX(@WorkOrder,a.DocNo)>0
   AND PATINDEX(@MRPCategory,ISNULL(mrp.Code,''))>0





END 