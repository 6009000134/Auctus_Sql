CREATE VIEW v_cust_FALocation4OA
as
SELECT a.ID,a.Code,a1.Name--位置ID，编码，名称
,a.Org OrgID,o.Code OrgCode,o1.Name OrgName--组织信息
FROM dbo.FA_Location a INNER JOIN dbo.FA_Location_Trl a1 ON a.ID=a1.ID
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID