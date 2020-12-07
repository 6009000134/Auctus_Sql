SELECT o.Name 组织,s.Name 客户,a.DocNo 单号,doc.Name 单据类型,a.BusinessDate 业务日期
,cur.Name 币种,a.TotalNetMoneyTC 未税金额,a.TotalMoneyTC 税价合计,a.ACToFCRate 汇率
,cur1.Name 本币,a.TotalNetMoneyFC 未税金额_本币,a.TotalMoneyFC 税价合计_本币,op.Name 业务员,op61.Name 销售员
FROM dbo.SM_SO a --INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO INNER JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
INNER JOIN dbo.Base_Organization_Trl o ON a.Org=o.ID
LEFT JOIN dbo.CBO_Customer_Trl s ON a.OrderBy_Customer=s.ID
LEFT JOIN dbo.SM_SODocType_Trl doc ON a.DocumentType=doc.ID
LEFT JOIN dbo.CBO_Operators_Trl op ON a.Seller=op.ID
LEFT JOIN dbo.CBO_Operators op6 ON a.DescFlexField_PubDescSeg6=op6.code LEFT JOIN dbo.CBO_Operators_trl op61 ON op61.ID=op6.ID
LEFT JOIN dbo.Base_Currency_Trl cur ON a.TC=cur.ID AND ISNULL(cur.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.Base_Currency_Trl cur1 ON a.FC=cur1.ID AND ISNULL(cur1.SysMLFlag,'zh-cn')='zh-cn'

