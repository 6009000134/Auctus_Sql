SELECT 
a.MasterCode 顶阶料号,c.VersionCode 版本,a.Level 层级,d.Code 父项料号,d.Name 父项名称
,d1.Code 子件料号,d1.Name 子件名称
,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a.ComponentType,'zh-cn')子件类型
,dbo.F_GetEnumName('',d1.ItemFormAttribute,'zh-cn') 料品形态属性
,a.ThisUsageQty 用量,a.Sequence 顺序,a.SubSeq 替代顺序,a.IssueStyle	发料方式,CASE WHEN a.IsPhantomPart=0 THEN '否'ELSE '是'end 虚拟
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
