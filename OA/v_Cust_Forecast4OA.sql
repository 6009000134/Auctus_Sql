/*
Ô¤²â¶©µ¥±íÍ·
*/
ALTER  VIEW v_Cust_Forecast4OA
as
SELECT 
a.ID,a.DocNo,a.Org,a.DocmentType,doctype.Code DocTypeCode,doctype1.Name DocTypeName,a.CreatedBy,a.OrderOperator
,op1.Name Operator,FORMAT(a.BusinessDate,'yyyy-MM-dd')BusinessDate,FORMAT(a.CreatedOn,'yyyy-MM-dd')CreatedOn,a1.Note
FROM dbo.SM_ForecastOrder a 
INNER JOIN dbo.SM_ForecastOrder_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.SM_ForecastOrderDocType doctype ON a.DocmentType=doctype.ID LEFT JOIN dbo.SM_ForecastOrderDocType_Trl doctype1 ON doctype.ID=doctype1.ID AND ISNULL(doctype1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op ON a.OrderOperator=op.ID LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Org=1001708020135665 AND a.Status=2
AND (SELECT COUNT(1) FROM dbo.SM_ForecastOrderLine t WHERE t.ForecastOrder=a.ID AND t.Status<>3)>0

