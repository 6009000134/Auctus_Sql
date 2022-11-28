alter VIEW v_Cust_SO4OA
as
SELECT a.ID,a.DocNo,a.Status,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',a.Status,'zh-cn')StatusName
,cus.Code,cus.ShortName
,o.ID OrgID,o.Code OrgCode,o1.Name OrgName
FROM SM_SO a
INNER JOIN dbo.CBO_Customer cus ON a.OrderBy_Customer=cus.ID
INNER JOIN dbo.CBO_Customer_Trl cus1 ON cus.ID=cus1.ID AND cus1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'