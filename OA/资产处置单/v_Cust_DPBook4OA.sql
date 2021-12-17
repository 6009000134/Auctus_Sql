/*
’€æ…’À≤æ
*/
ALTER VIEW v_Cust_DPBook4OA
AS
    SELECT  a.ID ,
            a.Org ,
			o.Code OrgCode,
			o1.Name OrgName,
            a1.Name ,
            a.EffectiveRange_IsEffective
    FROM    FA_DepreciationBook a
            LEFT JOIN dbo.FA_DepreciationBook_Trl a1 ON a.ID = a1.ID
			LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID
			LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
    WHERE   a.EffectiveRange_IsEffective = 1