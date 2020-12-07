/*
获取待创建的预测订单
*/
Alter PROC sp_Auctus_BE_GetForeCastList
AS
BEGIN
	DECLARE @DocTypeID BIGINT,@DocTypeCode VARCHAR(50),@DocTypeName NVARCHAR(10)
	SELECT @DocTypeID=a.ID,@DocTypeCode=a.Code,@DocTypeName=a1.Name	 FROM dbo.SM_ForecastOrderDocType a INNER JOIN dbo.SM_ForecastOrderDocType_Trl a1 ON a.ID=a1.ID
	WHERE a.Code='30101'
	SELECT a.ID,a.DocNo,@DocTypeID DocTypeID,@DocTypeCode DocTypeCode,@DocTypeName DocTypeName,a.BusinessDate,a.Customer_Name,b.DocLineNo,b.Itemmaster,c.Code,c.Name,b.SPECS,b.Qty,b.DemandDate,b.DeliveryDate
	,cus.ID CustomerID,cus.Code CustomerCode,cus1.Name CustomerName,cus.Saleser OperatorID,op.Code OperatorCode,op1.Name OperatorName
	,dept.ID DeptID,dept.Code DeptCode,dept1.Name DeptName,1001708020135665 OrgID,'300' OrgCode,'深圳市力同芯科技发展有限公司'OrgName
	,cs.ID ShipToSiteID,cs.Code ShipToSiteCode,cs.Name ShipToSiteName
	FROM dbo.Auctus_Forecast a INNER JOIN dbo.Auctus_ForecastLine b ON a.ID=b.Forecast INNER JOIN dbo.CBO_ItemMaster c ON b.Itemmaster=c.ID
	INNER JOIN dbo.CBO_Customer_Trl cus1 ON a.Customer_Name=cus1.Name INNER JOIN dbo.CBO_Customer cus ON cus1.ID=cus.ID AND cus.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
	INNER JOIN dbo.CBO_Operators op ON cus.Saleser=op.ID INNER JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID
	INNER JOIN dbo.CBO_Department dept ON cus.Department=dept.ID INNER JOIN dbo.CBO_Department_Trl dept1 ON dept.ID=dept1.ID	
	INNER JOIN 
	(SELECT cs.ID,cs.Code,cs1.Name,cs.Customer,ROW_NUMBER()OVER(PARTITION BY cs.Customer ORDER BY cs.CreatedOn)RN 
	FROM dbo.CBO_CustomerSite cs INNER JOIN dbo.CBO_CustomerSite_Trl cs1 ON cs.ID=cs1.ID WHERE cs.Effective_IsEffective=1 ) cs --客户位置，可能存在多条，所以按创建时间取最早创建的有效行
	ON cs.Customer=cus.ID	 AND cs.RN=1
	WHERE a.ID=20
	


END 



