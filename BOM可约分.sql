SELECT c.Code 母件料号,c.Name 母件品名,c.SPECS 母件规格,a.BOMVersionCode 母件版本
,d.Code 子件料号,d.Name 子件品名,d.SPECS 子件规格,b.ParentQty 母件底数,b.UsageQty 用量 
--,a.ID,b.ID
,a.EffectiveDate 母件生效日期,b.EffectiveDate 子件生效日期
--,ROW_NUMBER() OVER(PARTITION BY c.ID ORDER BY a.BOMVersion desc)
FROM dbo.CBO_BOMMaster a INNER JOIN dbo.CBO_BOMComponent b ON a.ID=b.BOMMaster
INNER JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID INNER JOIN dbo.CBO_ItemMaster d ON b.ItemMaster=d.ID
WHERE a.Org=1001708020135665
AND c.Effective_IsEffective=1 AND d.Effective_IsEffective=1
AND (b.ParentQty<>1 AND b.UsageQty<>1)
AND (b.ParentQty%b.UsageQty=0 OR b.UsageQty%b.ParentQty=0)
AND a.DisableDate>GETDATE()
AND b.DisableDate>GETDATE()
ORDER BY c.Code,d.Code

