SELECT 
o.Name 组织,s.Name 客户,a.DocNo 单号,doc.Name 单据类型,a.BusinessDate 业务日期,cur.Name 币种,cur1.Name 本币,a.ACToFCExRate 汇率
,a.TotalNetMoneyAC 未税金额,a.TotalMoney 税价合计,a.TotalNetMoneyFC 未税金额_本币,a.TotalMoneyFC 税价合计_本币
--,b.SrcDocNo,b.SrcDocLineNo 
FROM dbo.SM_Ship a --INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
INNER JOIN dbo.Base_Organization_Trl o ON a.Org=o.ID
LEFT JOIN dbo.CBO_Customer_Trl s ON a.OrderBy_Customer=s.ID
LEFT JOIN dbo.SM_ShipDocType_Trl doc ON a.DocumentType=doc.ID
LEFT JOIN dbo.Base_Currency_Trl cur ON a.ac=cur.ID AND ISNULL(cur.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.Base_Currency_Trl cur1 ON a.FC=cur1.ID AND ISNULL(cur1.SysMLFlag,'zh-cn')='zh-cn'
--WHERE a.DocNo='SM30201803009'
ORDER BY a.BusinessDate DESC 


