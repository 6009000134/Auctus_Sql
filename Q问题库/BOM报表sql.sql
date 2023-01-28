SELECT  a.MasterCode 顶级BOM料号 ,
        m.Code 母件料号,
        m.Name 品名,
        m2.Code 子件料号,
        m2.Name 品名,
        a.Sequence 顺序,
        CASE WHEN a.ComponentType=0 THEN '标准'ELSE '替代'END  替代,
        a.SubSeq 替代顺序,
        a.SubEffectiveDate 生效日期,
        a.SubDisableDate 失效日期,
        CASE WHEN a.IsPhantomPart=1 THEN '虚拟' ELSE '' END 是否虚拟,
        a.IssueStyle 发料方式
FROM    dbo.Auctus_NewestBom a
        LEFT JOIN dbo.CBO_ItemMaster m ON a.PID = m.ID
        LEFT JOIN dbo.CBO_ItemMaster m2 ON a.MID = m2.ID
		LEFT JOIN (SELECT strID FROM dbo.fun_Cust_StrToTable('H50BT,MHS130,UH35,UH45,UH610,WT100,蓑羽鹤成人版,WT500,WT900,白鹤,丹顶鹤,恒山,嵩山,泰山,天鹅,梧桐山,RB39,BGB500,M50BT'))c
		ON 1=1 AND PATINDEX('%'+c.strID+'%',m.Name)>0
WHERE   a.Org = 1001708020135665
AND m.Code LIKE '1%' 
AND PATINDEX('%'+c.strID+'%',m.Name)>0
ORDER BY a.MasterCode ,
        a.Level ,
        a.ParentCode ,
        a.Code




