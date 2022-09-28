/*
生产线x别
*/
ALTER VIEW v_Cust_Line4Mes
AS
WITH data1 AS
(
SELECT  A.ID, A.Code, A1.Name
,a.IsLeaf,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate,a.ParentNode
	FROM  Base_DefineValue as A  
	left join Base_Language as A2 on A2.Code = 'zh-CN' and A2.Effective_IsEffective = 1 
	left join Base_DefineValue_Trl as A1 on A1.SysMlFlag = 'zh-CN' and A1.SysMlFlag = A2.Code and A.ID = A1.ID
	LEFT JOIN dbo.Auctus_ProductResource p ON a.Code=p.Code
	WHERE  a.Effective_IsEffective=1
	and   DATEDIFF_BIG(day, A. Effective_EffectiveDate ,GETDATE()) >=0
	and   DATEDIFF_BIG(day, A. Effective_DisableDate ,GETDATE())  <=0
	and  exists (select 1 from  Base_ValueSetDef  WHERE code='ZDY_SCXB' and   id=A.ValueSetDef)
)
SELECT *,(SELECT t.Name FROM data1 t WHERE t.id=a.parentnode)DeptName 
,ROW_NUMBER()OVER(ORDER BY a.Code)RN
FROM data1 a
WHERE a.IsLeaf=1