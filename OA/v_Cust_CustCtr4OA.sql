--客户管控范围
ALTER VIEW v_Cust_CustCtr4OA AS
SELECT a.OrgID,a.OrgCode,a.OrgName,a.CustomerID,a.CustomerCode,a.CustomerName
,CASE WHEN c.ID IS NULL THEN 0 ELSE 1 END IsControl FROM 
(
SELECT a.ID OrgID,a.Code OrgCode,a1.Name OrgName,b.ID CustomerID,b.Code CustomerCode,b1.Name CustomerName
FROM dbo.Base_Organization a,dbo.Base_Organization_Trl a1 ,dbo.CBO_Customer b,dbo.CBO_Customer_Trl b1
WHERE b.Org=1001708020135435 --取200组织的客户 
AND a.id NOT IN (1001708020000209,1001708020135890,1001806270217347)
AND a.ID=a1.ID AND b.ID=b1.ID
)a
LEFT JOIN (
SELECT a.ID
,a.Customer,cus.Code CustomerCode,cus1.Name CustomerName--客户信息
,a.CurOrg,oo.Code CurOrgCode,oo1.Name CurOrgName--所属组织
,a.TargetOrg,o.code TargetOrgCode,o1.Name TargetOrgName--管控组织
FROM dbo.CBO_CustCtrScopeDeliver a
INNER JOIN dbo.Base_Organization o ON a.TargetOrg=o.ID 
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.CBO_Customer cus ON a.Customer=cus.ID INNER JOIN dbo.CBO_Customer_Trl cus1 ON cus.id=cus1.ID AND ISNULL(cus1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.Base_Organization oo ON a.CurOrg=oo.ID 
INNER JOIN dbo.Base_Organization_Trl oo1 ON oo.ID=oo1.ID AND ISNULL(oo1.SysMLFlag,'zh-cn')='zh-cn'
) c ON a.OrgID=c.TargetOrg AND a.CustomerCode=c.CustomerCode
----客户管控范围视图
--SELECT a.ID
--,a.Customer,cus.Code CustomerCode,cus1.Name CustomerName--客户信息
--,a.CurOrg,oo.Code CurOrgCode,oo1.Name CurOrgName--所属组织
--,a.TargetOrg,o.code TargetOrgCode,o1.Name TargetOrgName--管控组织
--FROM dbo.CBO_CustCtrScopeDeliver a
--INNER JOIN dbo.Base_Organization o ON a.TargetOrg=o.ID 
--INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
--INNER JOIN dbo.CBO_Customer cus ON a.Customer=cus.ID INNER JOIN dbo.CBO_Customer_Trl cus1 ON cus.id=cus1.ID AND ISNULL(cus1.SysMLFlag,'zh-cn')='zh-cn'
--INNER JOIN dbo.Base_Organization oo ON a.CurOrg=oo.ID 
--INNER JOIN dbo.Base_Organization_Trl oo1 ON oo.ID=oo1.ID AND ISNULL(oo1.SysMLFlag,'zh-cn')='zh-cn'

GO
