SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
ALTER  VIEW vw_tempDocInfo
AS
        
		WITH Itemmaster AS--MPS料品
	(
	SELECT a.ID,a.Code,a.Name
	,b.MRPPlanningType--0/MPS件
	,b.FixedLT--固定提前期
	,ISNULL(c.Name,'')MRPCategory
	FROM dbo.CBO_ItemMaster a INNER JOIN dbo.CBO_MrpInfo b ON a.ID=b.ItemMaster
	LEFT JOIN dbo.vw_MRPCategory c ON a.DescFlexField_PrivateDescSeg22=c.Code
	WHERE b.MRPPlanningType=0
	),
	MOS AS--工单集合
	(
	SELECT a.ID,a.DocNo,a.StartDate,a.CompleteDate,a.ProductQty
	,a.ProductQty-
	ISNULL((SELECT SUM(CompleteQty) FROM dbo.MO_CompleteRpt
	WHERE DocState IN (1,3) AND MO=a.ID),0) UnCompleteQty
	,ISNULL((SELECT SUM(CompleteQty) FROM dbo.MO_CompleteRpt
	WHERE DocState IN (1,3) AND MO=a.ID),0)UsedQty
	,a.ProductQty-
	ISNULL((SELECT SUM(CompleteQty) FROM dbo.MO_CompleteRpt
	WHERE DocState IN (1,3) AND MO=a.ID),0) CanAffordQty
	,a.ItemMaster,c.Code,c.Name,c.FixedLT,a.DemandCode
	,c.MRPCategory
	FROM dbo.MO_MO a  LEFT JOIN dbo.MO_MODocType_Trl a1 ON a.MODocType=a1.ID
	INNER JOIN Itemmaster c ON a.ItemMaster=c.ID
	WHERE a.Cancel_Canceled=0 AND a.DocState<>3 
	AND a1.Name NOT LIKE '%返工%' AND a1.name NOT LIKE '%客退%'
	),
	POS AS--采购订单集合
	(
	SELECT a.ID,a.DocNo+'-'+CONVERT(VARCHAR(10),b.DocLineNo)DocNo
	,(SELECT MIN(c.NeedPODate) FROM dbo.PM_POShipLine c WHERE c.POLine=b.ID AND c.Status IN (0,1,2))StartDate
	,(SELECT MIN(c.PlanArriveDate) FROM dbo.PM_POShipLine c WHERE c.POLine=b.ID AND c.Status IN (0,1,2))CompleteDate
	,b.SupplierConfirmQtyTU ProductQty
	,b.SupplierConfirmQtyTU-ISNULL((SELECT sum(rcv.RcvQtyTU)
FROM dbo.PM_Receivement rec INNER JOIN dbo.PM_RcvLine rcv ON rec.ID=rcv.Receivement
WHERE rcv.SrcPO_SrcDocNo=a.DocNo AND rcv.SrcPO_SrcDocLineNo=b.DocLineNo AND rcv.Status=5),0)UnCompleteQty
	,ISNULL((SELECT sum(rcv.RcvQtyTU)
	FROM dbo.PM_Receivement rec INNER JOIN dbo.PM_RcvLine rcv ON rec.ID=rcv.Receivement
	WHERE rcv.SrcPO_SrcDocNo=a.DocNo AND rcv.SrcPO_SrcDocLineNo=b.DocLineNo AND rcv.Status=5),0)UsedQty
	,b.SupplierConfirmQtyTU-ISNULL((SELECT sum(rcv.RcvQtyTU)
FROM dbo.PM_Receivement rec INNER JOIN dbo.PM_RcvLine rcv ON rec.ID=rcv.Receivement
WHERE rcv.SrcPO_SrcDocNo=a.DocNo AND rcv.SrcPO_SrcDocLineNo=b.DocLineNo AND rcv.Status=5),0) CanAffordQty
	,b.ItemInfo_ItemID Itemmaster,m.Code,m.Name,m.FixedLT
	,b.DemondCode DemandCode
	,m.MRPCategory
	FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.id=b.PurchaseOrder	
	INNER JOIN Itemmaster m ON b.ItemInfo_ItemID=m.ID
	WHERE a.Status in(0,1,2) and b.Status in (0,1,2) AND a.Org=1001708020135665
	AND a.Cancel_Canceled=0
	),
	Result as
	(
	SELECT ID  ,DocNo ,StartDate ,CompleteDate ,CONVERT(INT,ProductQty)ProductQty,CONVERT(INT,UnCompleteQty)UnCompleteQty,CONVERT(INT,UsedQty)UsedQty,CONVERT(INT,CanAffordQty)CanAffordQty ,Itemmaster,Code,Name,FixedLT ,DemandCode,MRPCategory FROM MOS
			UNION ALL
		SELECT ID  ,DocNo ,StartDate ,CompleteDate ,CONVERT(INT,ProductQty)ProductQty,CONVERT(INT,UnCompleteQty)UnCompleteQty,CONVERT(INT,UsedQty)UsedQty,CONVERT(INT,CanAffordQty)CanAffordQty ,Itemmaster,Code,Name,FixedLT ,DemandCode,MRPCategory FROM POS
	)
	SELECT a.*,ROW_NUMBER() OVER(ORDER BY a.StartDate)OrderNo FROM RESULT a
	
			


GO
