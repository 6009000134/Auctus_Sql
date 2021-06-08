CREATE VIEW v_Auctus_MOAndWPO
AS

WITH data1 AS 
(
SELECT a.DocNo WPO,b.DocLineNo,c.SubLineNo,a.MO
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE ISNULL(a.MO,'')!=''
),
MO AS
(
SELECT
a.DocNo,a.ItemMaster,b.Code,b.Name
,a.DocState
,dbo.F_GetEnumName('UFIDA.U9.MO.Enums.MOStateEnum',a.DocState,'zh-cn')DocStateName
FROM dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster b ON a.ItemMaster=b.ID
)
--SELECT a.*,b.WPO,b.DocLineNo,b.SubLineNo --INTO testTemp 
SELECT *
FROM MO a LEFT JOIN data1 b ON a.DocNo=b.MO