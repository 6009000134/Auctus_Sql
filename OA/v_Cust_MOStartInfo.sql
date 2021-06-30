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
SELECT a.ID--����ID
,a.DocNo--������
,a.Org
,uom1.Name UOM--������λ
,a.ItemMaster--��ƷID
,m.Code--�Ϻ�
,m.Name--Ʒ��
,m.SPECS--���
,a.ProductQty--��������
,a.TotalStartQty--�ۼƿ�������
,b.TotalIssuedQty--�ۼ�������������ʽ��
,b.TotalIssuedQty-a.TotalStartQty UnStartQty--δ��������
,b.TotalIssuedQty-a.TotalStartQty CanStartQty--�ɿ�������
,a.TotalStartQty-(SELECT ISNULL(SUM(t.CompleteQty),0) FROM dbo.MO_CompleteRpt t WHERE t.MO=a.ID AND t.DocState IN (1,3)) CanAntiStartQty
FROM dbo.MO_MO a 
LEFT JOIN dbo.CBO_ItemMaster  m ON a.ItemMaster=m.ID
LEFT JOIN picks b ON a.DocNo=b.DocNo
LEFT JOIN dbo.Base_UOM_Trl uom1 ON a.ProductUOM=uom1.ID and ISNULL(uom1.SysMLFlag,'zh-cn')='zh-cn'
WHERE 1=1
AND a.Cancel_Canceled=0 AND a.IsHoldRelease=0
AND a.DocState IN (1,2)


