/*
开工/返工记录
*/
ALTER  VIEW v_Cust_MOStartHistory
as

SELECT a.ID--工单ID
,a.DocNo--工单号
,b.StartSeq
,a.Org
,dbo.F_GetEnumName('UFIDA.U9.MO.Enums.BusinessDirectionEnum',b.BusinessDirection,'zh-cn')BusinessDirection
,b.StartDatetime
,CONVERT(INT,b.StartQty)StartQty
,b.StartManager
FROM dbo.MO_MO a 
LEFT JOIN dbo.CBO_ItemMaster  m ON a.ItemMaster=m.ID
LEFT JOIN dbo.MO_MOStartInfo b ON a.ID=b.MO
WHERE 1=1
AND a.Cancel_Canceled=0 AND a.IsHoldRelease=0
AND a.DocState IN (1,2)
AND a.TotalStartQty<a.ProductQty


