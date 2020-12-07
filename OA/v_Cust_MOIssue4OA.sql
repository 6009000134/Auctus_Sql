/*
生产领料
*/
CREATE VIEW v_Cust_MOIssue4OA
AS
SELECT 
a.ID,a.DocNo
,doc1.Name DocType
,a.BusinessDate
,c.DocNo MO_DocNo
,m.Code ProductCode,m.Name ProductName--产品信息
,CONVERT(INT,c.ProductQty)ProductQty
,a.DescFlexField_PrivateDescSeg1--上线日期
,a.DescFlexField_PrivateDescSeg2--退料理由
,a.DescFlexField_PrivateDescSeg3--以旧换新
,a.DescFlexField_PrivateDescSeg4--生产线别
,a.IsSpecialIssue--特别领料
,b.LineNum,m2.Code,m2.Name,m2.SPECS--领料信息
,b.Wh,wh.Code Wh_Code,wh1.Name Wh_Name--发料仓库
,b.IssueQty--应发数量
,b.IssuedQty--实发数量
,b.LotNo--批号
FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocLine b ON a.ID=b.IssueDoc
LEFT JOIN MO_MO c ON b.MO=c.ID LEFT JOIN dbo.CBO_ItemMaster m ON c.ItemMaster=m.ID
LEFT JOIN dbo.CBO_ItemMaster m2 ON b.item=m2.ID
LEFT JOIN dbo.CBO_Wh wh ON b.Wh=wh.ID LEFT JOIN dbo.CBO_Wh_Trl wh1 ON wh.ID=wh1.ID AND ISNULL(wh1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.MO_IssueDocType doc ON a.IssueDocType=doc.ID LEFT JOIN dbo.MO_IssueDocType_Trl doc1 ON doc.ID=doc1.ID AND ISNULL(doc1.SysMLFlag,'zh-cn')='zh-cn'
WHERE 1=1
--AND a.DocNo='LL-302006150032'
AND a.IssueType=0

