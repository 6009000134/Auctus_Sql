SELECT 
o.Name ��֯,s.Name �ͻ�,a.DocNo ����,doc.Name ��������,a.BusinessDate ҵ������,cur.Name ����,cur1.Name ����,a.ACToFCExRate ����
,a.TotalNetMoneyAC δ˰���,a.TotalMoney ˰�ۺϼ�,a.TotalNetMoneyFC δ˰���_����,a.TotalMoneyFC ˰�ۺϼ�_����
--,b.SrcDocNo,b.SrcDocLineNo 
FROM dbo.SM_Ship a --INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
INNER JOIN dbo.Base_Organization_Trl o ON a.Org=o.ID
LEFT JOIN dbo.CBO_Customer_Trl s ON a.OrderBy_Customer=s.ID
LEFT JOIN dbo.SM_ShipDocType_Trl doc ON a.DocumentType=doc.ID
LEFT JOIN dbo.Base_Currency_Trl cur ON a.ac=cur.ID AND ISNULL(cur.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.Base_Currency_Trl cur1 ON a.FC=cur1.ID AND ISNULL(cur1.SysMLFlag,'zh-cn')='zh-cn'
--WHERE a.DocNo='SM30201803009'
ORDER BY a.BusinessDate DESC 


