SELECT DISTINCT a.ParentCode ĸ���Ϻ�,m.Name ĸ������,a.Code �Ӽ��Ϻ�,m2.Name �Ӽ�����,CASE WHEN a.IsPhantomPart=1 THEN '��' ELSE '' END ����,a.IssueStyle ���Ϸ�ʽ
FROM dbo.Auctus_NewestBom a LEFT JOIN dbo.CBO_ItemMaster m ON a.PID=m.ID
LEFT JOIN dbo.CBO_ItemMaster m2 ON a.MID=m2.ID
WHERE a.code IN
('204010260' ,'204010259','204010242')
ORDER BY a.Code,a.ParentCode
