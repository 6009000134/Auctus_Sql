SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
ALTER VIEW vw_tempSO
AS
       
        
	SELECT t.DocNo,t.DocLineNo,t.DocSubLineNo,t.DocType,CONVERT(INT,t.Num)Num,t.DemandType,t.ItemID Itemmaster,t.Code,t.Name,t.SPECS
	,CONVERT(INT,t.OrderQtyTU)OrderQtyTU,CONVERT(INT,t.ReqQtyTU)ReqQtyTU,t.ReqDate
	,t.MRPCategory
	,ROW_NUMBER()OVER(ORDER BY t.ReqDate)RN 
	FROM (
	SELECT  b.DocNo ,a.DocLineNo ,0 DocSubLineNo ,c.Name DocType ,a.Num ,a.DemandType ,a.ItemInfo_ItemID ItemID ,
			m.Code ,m.Name ,m.SPECS ,a.Num OrderQtyTU ,ISNULL(a.Num, 0) - ISNULL(a.SumPreUsedQtyTU, 0) ReqQtyTU ,a.ShipPlanDate ReqDate
			,m2.Name MRPCategory
	FROM    SM_ForecastOrderLine a
			INNER  JOIN SM_ForecastOrder b ON a.ForecastOrder = b.ID
			INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID = m.ID
			INNER JOIN dbo.CBO_MrpInfo m1 ON m.ID=m1.ItemMaster AND m1.MRPPlanningType=0
			LEFT JOIN dbo.vw_MRPCategory m2 ON m.DescFlexField_PrivateDescSeg22=m2.Code
			LEFT JOIN dbo.SM_ForecastOrderDocType_Trl c ON b.DocmentType = c.ID
	WHERE   1 = 1
			AND b.Org = 1001708020135665
			AND a.Status = 2
			AND ISNULL(a.Num, 0) - ISNULL(a.SumPreUsedQtyTU, 0) > 0
			AND DATEDIFF(HH, a.ShipPlanDate, DATEADD(DAY, 10000, GETDATE())) >= 0
	UNION ALL
	SELECT  c.DocNo ,b.DocLineNo ,a.DocSubLineNo ,dt.Name ,a.ShipPlanQtyTU ,a.DemandType ,a.ItemInfo_ItemID ItemID ,m.Code ,m.Name ,m.SPECS 
			,a.ShipPlanQtyTU OrderQtyTU ,a.SOShipLineSumInfo_SumLackQtyTU ReqQtyTU ,a.AffirmShipDate ReqDate
			,m2.Name MRPCategory
	FROM    SM_SOShipline a
			INNER JOIN SM_SOLine b ON a.SOLine = b.ID
			INNER  JOIN SM_SO c ON b.SO = c.ID
			INNER JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID = m.ID
			INNER JOIN dbo.CBO_MrpInfo m1 ON m.ID=m1.ItemMaster AND m1.MRPPlanningType=0
			LEFT JOIN dbo.vw_MRPCategory m2 ON m.DescFlexField_PrivateDescSeg22=m2.Code
			LEFT JOIN dbo.SM_SODocType_Trl dt ON c.DocumentType = dt.ID
	WHERE   1 = 1
			AND c.Org = 1001708020135665
			AND a.Status = 3
			AND a.Cancel_Canceled = 0
			AND a.SOShipLineSumInfo_SumLackQtyTU > 0
			AND DATEDIFF(HH, a.AffirmShipDate, DATEADD(DAY, 10000, GETDATE())) >= 0		
			) t --WHERE t.DocNo='FO30200817005' AND t.DocLineNo  IN (10,20)


