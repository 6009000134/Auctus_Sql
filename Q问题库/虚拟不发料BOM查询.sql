SELECT DISTINCT a.ParentCode 母件料号,m.Name 母件名称,a.Code 子件料号,m2.Name 子件名称,CASE WHEN a.IsPhantomPart=1 THEN '√' ELSE '' END 虚拟,a.IssueStyle 发料方式
FROM dbo.Auctus_NewestBom a LEFT JOIN dbo.CBO_ItemMaster m ON a.PID=m.ID
LEFT JOIN dbo.CBO_ItemMaster m2 ON a.MID=m2.ID
WHERE a.code IN
('204010260' ,'204010259','204010242')
ORDER BY a.Code,a.ParentCode
