SELECT 
a.MasterCode �����Ϻ�,c.VersionCode �汾,a.Level �㼶,d.Code �����Ϻ�,d.Name ��������
,d1.Code �Ӽ��Ϻ�,d1.Name �Ӽ�����
,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')�Ӽ�����
,dbo.F_GetEnumName('',d1.ItemFormAttribute,'zh-cn') ��Ʒ��̬����
,a.ThisUsageQty ����,a.Sequence ˳��,a.SubSeq ���˳��,a.IssueStyle	���Ϸ�ʽ,CASE WHEN a.IsPhantomPart=0 THEN '��'ELSE '��'end ����
FROM dbo.Auctus_NewestBom a 
LEFT JOIN dbo.CBO_BOMMaster b ON a.BOMMaster=b.ID LEFT JOIN dbo.CBO_BOMVersion c ON b.BOMVersion=c.ID
LEFT JOIN dbo.CBO_ItemMaster d ON a.PID=d.ID
LEFT JOIN dbo.CBO_ItemMaster d1 ON a.MID=d1.ID
WHERE a.MasterCode IN (
'102040152',
'102040150',
'102040143',
'102040146',
'102040122',
'102040139',
'102040136',
'102040116'
)
ORDER BY a.MasterCode,a.Level,a.Sequence,a.SubSeq
