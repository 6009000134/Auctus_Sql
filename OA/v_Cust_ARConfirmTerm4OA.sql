/*
应收立账条件
*/
ALTER VIEW v_Cust_ARConfirmTerm4OA
as
SELECT  a.Org ,
        o.Code Org_Code ,
        o1.Name Org_Name ,
        --a.Currency ,
        --cur.Code ,
        --cur1.Name ,
        --a.IsDocEditable ,
        --a.IsInstallmentConfirm ,
        a.Code ,
        b.Name ,
        a.Effective_IsEffective ,
        a.Effective_EffectiveDate ,
        a.Effective_DisableDate,
		con.ConfirmDateType,
		dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.ConfirmDateTypeEnum',con.ConfirmDateType,'zh-cn')ConfirmDateTypeName
FROM    CBO_ARConfirmTerm a
        INNER JOIN dbo.CBO_ARConfirmTerm_Trl b ON a.ID = b.ID
                                                  AND ISNULL(b.SysMLFlag,
                                                             'zh-cn') = 'zh-cn'
        LEFT JOIN dbo.Base_Organization o ON a.Org = o.ID
        LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID = o1.ID
                                                  AND ISNULL(o1.SysMLFlag,
                                                             'zh-cn') = 'zh-cn'
        LEFT JOIN dbo.Base_Currency cur ON a.Currency = cur.ID
        LEFT JOIN dbo.Base_Currency_Trl cur1 ON cur.ID = cur1.ID
                                                AND ISNULL(cur1.SysMLFlag,
                                                           'zh-cn') = 'zh-cn'
LEFT JOIN CBO_ARInstalmentTerm con ON a.ID=con.ARAccrueTerm
														   WHERE a.Effective_IsEffective=1 AND GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate
