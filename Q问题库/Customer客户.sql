SELECT o.Code,o1.name,a.Code,a1.Name,c1.Name
FROM dbo.CBO_Customer a INNER JOIN dbo.CBO_Customer_Trl a1 ON a.id=a1.ID AND a1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_ARConfirmTerm c ON a.ARConfirmTerm=c.ID
LEFT JOIN dbo.CBO_ARConfirmTerm_Trl c1 ON c.id=c1.id AND c1.SysMLFlag='zh-cn'
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID
LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
WHERE a.Effective_IsEffective=1
AND a.Effective_DisableDate>GETDATE()
--WHERE a.Code='1.1.MLDZ.001'

--客户账期是否一致
--SELECT t.Code,t.Name,COUNT(1) FROM 
--(
--SELECT a.Code,a1.Name,c1.Name ARName
--FROM dbo.CBO_Customer a INNER JOIN dbo.CBO_Customer_Trl a1 ON a.id=a1.ID AND a1.SysMLFlag='zh-cn'
--LEFT JOIN dbo.CBO_ARConfirmTerm c ON a.ARConfirmTerm=c.ID
--LEFT JOIN dbo.CBO_ARConfirmTerm_Trl c1 ON c.id=c1.id AND c1.SysMLFlag='zh-cn'
--WHERE ISNULL(c1.Name,'')!=''
--GROUP BY a.Code,a1.Name,c1.Name
--) t GROUP BY t.Code,t.Name HAVING COUNT(1)>1
--ORDER BY t.Code