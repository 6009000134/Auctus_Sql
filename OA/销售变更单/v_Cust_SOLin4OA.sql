/*
销售订单行
*/
ALTER VIEW v_Cust_SOLin4OA
as
SELECT o.ID OrgID,o.Code OrgCode,o1.Name OrgName,a.ID,a.DocNo,b.Status LineStatus,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',b.Status,'zh-cn')LineStatusName
,cus.Code,cus.ShortName
,b.ID LineID,b.DocLineNo,m.ID ItemID,m.Code ItemCode,m.Name ItemName,m.SPECS ItemSpecs,b.OrderByQtyTU
,b.DescFlexField_PubDescSeg3 CustomerOrder,(SELECT MIN(t.DeliveryDate) FROM dbo.SM_SOShipline t WHERE t.SOLine=b.ID)DeliveryDate
FROM SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO
INNER JOIN dbo.CBO_Customer cus ON a.OrderBy_Customer=cus.ID
INNER JOIN dbo.CBO_Customer_Trl cus1 ON cus.ID=cus1.ID AND cus1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID