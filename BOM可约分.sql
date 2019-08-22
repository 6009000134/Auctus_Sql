SELECT c.Code ĸ���Ϻ�,c.Name ĸ��Ʒ��,c.SPECS ĸ�����,a.BOMVersionCode ĸ���汾
,d.Code �Ӽ��Ϻ�,d.Name �Ӽ�Ʒ��,d.SPECS �Ӽ����,b.ParentQty ĸ������,b.UsageQty ���� 
--,a.ID,b.ID
,a.EffectiveDate ĸ����Ч����,b.EffectiveDate �Ӽ���Ч����
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

