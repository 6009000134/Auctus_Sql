--SELECT org,* FROM dbo.CBO_ItemMaster WHERE code='101010009'
--SELECT IsInheritBomMasterNo 
--FROM dbo.CBO_MfgInfo WHERE ItemMaster=1001708090013187

SELECT id,a.Code FROM dbo.CBO_ItemMaster a WHERE a.Code IN('328010033','332020064') AND a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')

SELECT t.BOMMaster FROM (
SELECT a.BOMMaster,a.ItemMaster,a.ComponentType FROM dbo.CBO_BOMComponent a WHERE a.ItemMaster=1001805020041416
UNION all
SELECT a.BOMMaster,a.ItemMaster,a.ComponentType FROM dbo.CBO_BOMComponent a WHERE a.ItemMaster=1001708090450283
) t GROUP BY t.BOMMaster HAVING COUNT(1)>1

SELECT * FROM dbo.CBO_BOMComponent a WHERE a.BOMMaster IN (
SELECT a.BOMMaster FROM dbo.CBO_BOMComponent a WHERE a.ItemMaster=1001805020041416
) AND a.ItemMaster=1001708090450283

;
WITH data1 AS --子件信息
(
SELECT a.BOMMaster,a.ItemMaster,a.Sequence,a.SubSeq,a.ComponentType FROM dbo.CBO_BOMComponent a WHERE a.ItemMaster=1001805020041416
)
SELECT a.BOMMaster,a.ItemMaster,c.Code,c.Name,c.SPECS,a.Sequence,a.SubSeq,a.ComponentType,d.Code,d.Name,d.SPECS,b.* FROM dbo.CBO_BOMComponent a INNER JOIN data1 b ON a.BOMMaster=b.BOMMaster AND a.Sequence=b.Sequence AND a.SubSeq!=b.SubSeq
INNER JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID INNER JOIN dbo.CBO_ItemMaster d ON b.ItemMaster=d.ID
