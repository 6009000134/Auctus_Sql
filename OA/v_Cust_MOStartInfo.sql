alter VIEW v_Cust_MOStartInfo
as

WITH picks AS
(
SELECT a.DocNo,MIN(a.TotalIssuedQty)TotalIssuedQty 
FROM 
(
SELECT a.DocNo,a.Org,b.IssuedQty,b.IssuedQty*a.ProductQty/b.ActualReqQty TotalIssuedQty
FROM dbo.MO_MO a INNER JOIN dbo.MO_MOPickList b ON a.ID=b.MO
WHERE a.Cancel_Canceled=0 AND a.IsHoldRelease=0
AND a.DocState IN (1,2)
AND a.TotalStartQty<a.ProductQty
AND b.ActualReqQty>0
AND b.IssueStyle=0
) a 
GROUP BY a.DocNo
)
SELECT a.ID--工单ID
,a.DocNo--工单号
,a.Org
,uom1.Name UOM--生产单位
,a.ItemMaster--料品ID
,m.Code--料号
,m.Name--品名
,m.SPECS--规格
,a.ProductQty--生产数量
,a.TotalStartQty--累计开工数量
,b.TotalIssuedQty--累计齐套数量（推式）
,b.TotalIssuedQty-a.TotalStartQty UnStartQty--未开工数量
,b.TotalIssuedQty-a.TotalStartQty CanStartQty--可开工数量
,a.TotalStartQty-(SELECT ISNULL(SUM(t.CompleteQty),0) FROM dbo.MO_CompleteRpt t WHERE t.MO=a.ID AND t.DocState IN (1,3)) CanAntiStartQty
FROM dbo.MO_MO a 
LEFT JOIN dbo.CBO_ItemMaster  m ON a.ItemMaster=m.ID
LEFT JOIN picks b ON a.DocNo=b.DocNo
LEFT JOIN dbo.Base_UOM_Trl uom1 ON a.ProductUOM=uom1.ID and ISNULL(uom1.SysMLFlag,'zh-cn')='zh-cn'
WHERE 1=1
AND a.Cancel_Canceled=0 AND a.IsHoldRelease=0
AND a.DocState IN (1,2)


