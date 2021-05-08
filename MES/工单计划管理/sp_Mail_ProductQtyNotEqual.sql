/*
U9工单数量与MES工单数量不一致邮件推送
*/
ALTER PROC [dbo].[sp_Mail_ProductQtyNotEqual]
AS
BEGIN

	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		DROP TABLE #TempTable
	END 

	;
	WITH MesMo AS
	(
	SELECT a.WorkOrder,a.Quantity,a.MaterialCode,a.MaterialName,a.ERPQuantity ,a.Status,a.CustomerOrder,a.IsCanceled
	FROM dbo.mxqh_plAssemblyPlanDetail a WHERE a.Status<>4 and a.IsCanceled<>1
	)
	SELECT ROW_NUMBER()OVER(ORDER BY a.DocNo)RN,a.DocNo,b.WorkOrder
	,CASE WHEN a.DocState='0' THEN '开立'
	WHEN a.DocState=1 THEN '已核准'
	WHEN a.DocState=2 THEN '开工'
	WHEN a.DocState=3 THEN '完工'
	WHEN a.DocState=4 THEN '核准中'
	ELSE ''END DocState
	,CONVERT(INT,a.ProductQty)ProductQty,b.Quantity,b.MaterialCode,b.MaterialName,b.ERPQuantity,CONVERT(INT,d.OrderByQtyTU) U9ERPQuantity
	,m.Code,m.Name,d.DescFlexField_PubDescSeg3 U9CustomerOrder,b.CustomerOrder
	,CASE WHEN b.Status =0 OR b.Status=1 THEN '开立'
	WHEN b.Status=2 THEN '开工'
	WHEN b.Status=4 THEN '完工'
	ELSE '非完工' END Status	
	,CASE WHEN m.Code<>b.MaterialCode THEN 0 
	WHEN a.ProductQty<>b.Quantity THEN 1
	WHEN ISNULL(d.OrderByQtyTU,0)!=0 AND PATINDEX('MO%',b.WorkOrder)>0 AND ISNULL(d.OrderByQtyTU,0)!=b.ERPQuantity THEN 1
	WHEN ISNULL(d.DescFlexField_PubDescSeg3,'')='' AND ISNULL(b.CustomerOrder,'')!='' THEN 3
	ELSE 2 END OrderNo
	INTO #TempTable
	FROM U9DATA.AuctusERP.dbo.MO_MO a INNER JOIN  MesMo b ON a.DocNo=b.WorkOrder
	LEFT JOIN (SELECT shipLine.DemandType,shipLine.SOLine,shipLine.Org FROM U9DATA.AuctusERP.dbo.SM_SOShipline shipLine 
WHERE shipLine.DemandType<>-1 AND shipLine.Org=1001708020135665) c  ON a.DemandCode=c.DemandType  

LEFT JOIN U9DATA.AuctusERP.dbo.SM_SOLine d ON c.SOLine=d.ID 
LEFT JOIN U9DATA.AuctusERP.dbo.CBO_Itemmaster m ON a.ItemMaster=m.ID
	WHERE a.ProductQty<>b.Quantity OR m.Code<>b.MaterialCode 
	OR 	(ISNULL(d.OrderByQtyTU,0)!=0 AND ISNULL(d.OrderByQtyTU,0)!=b.ERPQuantity AND PATINDEX('MO%',b.WorkOrder)>0)
	OR 
	(ISNULL(d.DescFlexField_PubDescSeg3,'')!=ISNULL(CustomerOrder,'') AND PATINDEX('MO%',a.DocNo)>0 AND b.Status<>4)

	IF EXISTS(SELECT 1 FROM #TempTable)
	BEGIN
		SELECT  TOP 1 1 MailNo, 'liufei@auctus.com,xuyw@auctus.cn' AS MailTo, 'ProductQtyNotEqual.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE
		--SELECT  TOP 1 1 MailNo, 'liufei@auctus.com' AS MailTo, 'ProductQtyNotEqual.xml' AS  XmlName, '刘飞' CHI_NAME, 'dddsfal' FORM_TYPE
		,FORMAT(GETDATE(),'yyyy-MM-dd')NowDate
	SELECT *
	,CASE WHEN Code!=MaterialCode THEN 'background-color:red;' ELSE ''END CodeStyle
	,CASE WHEN ISNULL(U9CustomerOrder,'')='' AND ISNULL(CustomerOrder,'')!='' THEN 'background-color:yellow;' 
	WHEN ISNULL(U9CustomerOrder,'')!=ISNULL(CustomerOrder,'') THEN 'background-color:red;' 
	ELSE ''END CustomerOrderStyle
	,CASE WHEN ProductQty!=Quantity THEN 'background-color:red;' ELSE ''END QtyStyle
	,CASE WHEN U9ERPQuantity=NULL THEN '' WHEN PATINDEX('MO%',WorkOrder)>0 AND CONVERT(INT,U9ERPQuantity)!=ERPQuantity THEN 'background-color:red;' ELSE '' END ERPStyle
	FROM #TempTable
	ORDER BY OrderNo
	END		


END 