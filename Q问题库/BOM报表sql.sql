SELECT  a.MasterCode ����BOM�Ϻ� ,
        m.Code ĸ���Ϻ�,
        m.Name Ʒ��,
        m2.Code �Ӽ��Ϻ�,
        m2.Name Ʒ��,
        a.Sequence ˳��,
        CASE WHEN a.ComponentType=0 THEN '��׼'ELSE '���'END  ���,
        a.SubSeq ���˳��,
        a.SubEffectiveDate ��Ч����,
        a.SubDisableDate ʧЧ����,
        CASE WHEN a.IsPhantomPart=1 THEN '����' ELSE '' END �Ƿ�����,
        a.IssueStyle ���Ϸ�ʽ
FROM    dbo.Auctus_NewestBom a
        LEFT JOIN dbo.CBO_ItemMaster m ON a.PID = m.ID
        LEFT JOIN dbo.CBO_ItemMaster m2 ON a.MID = m2.ID
		LEFT JOIN (SELECT strID FROM dbo.fun_Cust_StrToTable('H50BT,MHS130,UH35,UH45,UH610,WT100,����׳��˰�,WT500,WT900,�׺�,������,��ɽ,��ɽ,̩ɽ,���,��ͩɽ,RB39,BGB500,M50BT'))c
		ON 1=1 AND PATINDEX('%'+c.strID+'%',m.Name)>0
WHERE   a.Org = 1001708020135665
AND m.Code LIKE '1%' 
AND PATINDEX('%'+c.strID+'%',m.Name)>0
ORDER BY a.MasterCode ,
        a.Level ,
        a.ParentCode ,
        a.Code




