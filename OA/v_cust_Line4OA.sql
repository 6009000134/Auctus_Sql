
alter VIEW v_cust_Line4OA
as
SELECT * FROM (
SELECT  A.ID, A.Code, A1.Name,SUBSTRING(a.Code,1,3)Dept,
CASE WHEN LEN(a.Code)<3 THEN 0
WHEN SUBSTRING(a.Code,1,3)=a.Code THEN 1 ELSE 0 END  IsDept
,p.Num,p.WorkHours
,ROW_NUMBER()OVER(PARTITION BY a.code ORDER BY a.Code,p.CreatedOn DESC)RN
	FROM  Base_DefineValue as A  
	left join Base_Language as A2 on A2.Code = 'zh-CN' and A2.Effective_IsEffective = 1 
	left join Base_DefineValue_Trl as A1 on A1.SysMlFlag = 'zh-CN' and A1.SysMlFlag = A2.Code and A.ID = A1.ID
	LEFT JOIN dbo.Auctus_ProductResource p ON a.Code=p.Code
	WHERE  a.Effective_IsEffective=1
	and   DATEDIFF_BIG(day, A. Effective_EffectiveDate ,GETDATE()) >=0
	and   DATEDIFF_BIG(day, A. Effective_DisableDate ,GETDATE())  <=0
	and  exists (select 1 from  Base_ValueSetDef  WHERE code='ZDY_SCXB' and   id=A.ValueSetDef)

) t WHERE rn=1
