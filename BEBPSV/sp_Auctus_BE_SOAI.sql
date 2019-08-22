/*
标题：销售订单BE插件
需求人：曾婷、义红云
需求：SO有源PO号的都是卖往马来的物料。源PO中固定4行整机，计算出PO的BOM原材料用量汇总，所有关联源PO的SO中的原材料数量不能大于计算出来的BOM总用量
开发时间：2019-3-26
*/
alter PROC sp_Auctus_BE_SOAI
(
@SODocNo NVARCHAR(50),
@PoDocNo nvarchar(50),
@Result NVARCHAR(MAX) OUT
)
AS
BEGIN 
--SET @Remark='123'
--SET @Result='0';
--RETURN;
--DECLARE @PoDocNo  NVARCHAR(50) = 'PO80180531001'
--DECLARE @PoDocNo  NVARCHAR(50) = 'PO80190214001'

	DECLARE @Remark NVARCHAR(MAX)--如果SO中存在非BOM中的料品信息，在SO备注中标明：XX行XXX料不在BOM中
	DECLARE @OrgHk BIGINT = 1001712010015192
	DECLARE @Org BIGINT = 1001708020135665;
	DECLARE @PoData VARCHAR(1000);
	DECLARE @StandardTime DATE = dbo.fun_Auctus_GetInventoryDate(GETDATE());


	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#MainPoData') AND TYPE='U') BEGIN DROP TABLE #MainPoData; END 
	--汇总相同整机采购单单行
	SELECT a.DocNo, a.Supplier_ShortName, b.ItemInfo_ItemID, b.ItemInfo_ItemCode, SUM(b.SupplierConfirmQtyTU) SupplierConfirmQtyTU,
		SUM(b.TotalRecievedQtyTU)TotalRecievedQtyTU,
		'Pn'+CHAR(ASCII('A') + ROW_NUMBER()OVER(ORDER BY ItemInfo_ItemID) - 1) AS MateNo
	INTO #MainPoData
	FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID = b.PurchaseOrder
	WHERE a.DocNo = @PoDocNo AND  a.Org = @OrgHk --AND b.ItemInfo_ItemCode = '101010295'
	GROUP BY a.DocNo, a.Supplier_ShortName, b.ItemInfo_ItemID, b.ItemInfo_ItemCode

	--SELECT * FROM #MainPoData

	SET @PoData = STUFF((SELECT ',' + ItemInfo_ItemCode+'('+MateNo+'):'+ CONVERT(VARCHAR(30),CONVERT(FLOAT, SupplierConfirmQtyTU)) +
				'/'+  CONVERT(VARCHAR(30),CONVERT(FLOAT, TotalRecievedQtyTU))
			       FROM #MainPoData FOR XML PATH('')), 1, 1, '')

	--SELECT @PoData

	--获取bomData --最新版本
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#BomData') AND TYPE='U') BEGIN DROP TABLE #BomData; END 
	;WITH 
		BomData AS 
		(
			SELECT a.ID, a.BOMVersionCode, ROW_NUMBER()OVER(PARTITION BY c.ItemInfo_ItemCode ORDER BY a.BOMVersionCode DESC) AS RowNum,
				c.SupplierConfirmQtyTU, c.MateNo, c.TotalRecievedQtyTU 
			FROM dbo.CBO_BOMMaster a INNER JOIN dbo.CBO_ItemMaster b ON a.ItemMaster = b.ID 
				INNER JOIN #MainPoData c ON b.Code = c.ItemInfo_ItemCode
			WHERE a.Org = @Org
		)
		SELECT b.MasterBom, a.SupplierConfirmQtyTU, a.TotalRecievedQtyTU, b.Code, b.Name, b.SPECS, b.ProCode, b.ProName, b.ParentQty, b.UsageQty, b.TreeMateCodeRelation, 
			CASE WHEN LEFT(b.Code, 5)='20201' OR b.IssueStyle = 4 --SMT或者不发料 
				THEN 1 ELSE 0 END IsSmtOrLast, b.IssueStyle, a.MateNo
		INTO #BomData
		FROM BomData a INNER JOIN dbo.Auctus_DailyBomResult b ON a.ID = b.MasterBom
		WHERE a.RowNum = 1;

	--Bom 数据处理汇总
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#BomDataMerge') AND TYPE='U') BEGIN DROP TABLE #BomDataMerge; END 
	;WITH 
		BomData AS 
		(
			SELECT a.Code, a.Name, a.SPECS, a.MateNo, a.ProCode, a.ProName, a.IsSmtOrLast, a.ParentQty, a.UsageQty, a.TreeMateCodeRelation, a.SupplierConfirmQtyTU, a.IssueStyle,
					a.TotalRecievedQtyTU,
					--判断SMT及其以下的物料，不发料的下级
					(SELECT MAX(1) FROM #BomData b WHERE LEN(REPLACE(a.TreeMateCodeRelation, b.TreeMateCodeRelation, '')) != LEN(a.TreeMateCodeRelation) AND b.IsSmtOrLast = 1) IsSmtMate 
			FROM #BomData a
		),
		BomData2 AS 
		(
			SELECT a.Code, a.Name, a.SPECS, a.MateNo, a.ProCode, a.ProName, a.IsSmtOrLast, a.ParentQty, a.UsageQty, a.TreeMateCodeRelation, a.IsSmtMate, SupplierConfirmQtyTU,
				CONVERT(FLOAT, (a.UsageQty/a.ParentQty)*a.SupplierConfirmQtyTU) AS BomNeedQty,
				CONVERT(FLOAT, (a.UsageQty/a.ParentQty)*a.TotalRecievedQtyTU) AS HavedReciveQty
			FROM BomData a
			WHERE (a.IsSmtMate IS NULL OR a.IsSmtOrLast = 1) AND a.IssueStyle != 4 --排除不发料
		),
		--汇总物料Bom标准用量
		BomData3 AS 
		(
			SELECT a.Code, a.Name, a.SPECS, SUM(a.BomNeedQty)BomNeedQty, SUM(HavedReciveQty)HavedReciveQty
			FROM BomData2 a 
			GROUP BY a.Code, a.Name, a.SPECS
		),
		--成品转列
		ProPivot AS 
		(
			SELECT b.Code, PnA, PnB, PnC, PnD, PnE--, PnF, PnG 
			FROM (SELECT Code, MateNo, BomNeedQty FROM BomData2) a
			--PIVOT(SUM(BomNeedQty) FOR MateNo IN (PnA, PnB, PnC, PnD, PnE, PnF, PnG)) b
			PIVOT(SUM(BomNeedQty) FOR MateNo IN (PnA, PnB, PnC, PnD, PnE)) b
		),
		--成品转列
		RecivePivot AS 
		(
			SELECT b.Code, PnA_R, PnB_R, PnC_R, PnD_R, PnE_R--, PnF, PnG 
			FROM (SELECT Code, MateNo, HavedReciveQty FROM BomData2) a
			--PIVOT(SUM(BomNeedQty) FOR MateNo IN (PnA, PnB, PnC, PnD, PnE, PnF, PnG)) b
			PIVOT(SUM(HavedReciveQty) FOR MateNo IN (PnA_R, PnB_R, PnC_R, PnD_R, PnE_R)) b
		)
		SELECT a.Code, a.Name , BomNeedQty, a.SPECS, PnA, PnB, PnC, PnD, PnE--, PnF, PnG 
			,PnA_R, PnB_R, PnC_R, PnD_R, PnE_R
		INTO #BomDataMerge 
		FROM BomData3 a LEFT JOIN ProPivot b ON a.Code = b.Code
			LEFT JOIN RecivePivot c ON a.Code = c.Code
		--SELECT * FROM BomData2
		--SELECT * FROM #BomDataMerge

	--销售单信息
	;WITH 
		--工厂物料销售单信息
		SoData AS 
		(
			SELECT a.DescFlexField_PrivateDescSeg1 AS SourcePo, a.DocNo +'-' + CONVERT(VARCHAR(10), b.DocLineNo) AS RelateSo, a.CustomerPONo--客户采购订单
				, a.OrderBy_ShortName, a.OrderBy_Code, b.ItemInfo_ItemCode AS SoMateCode, b.ItemInfo_ItemName AS SoMateName, 
				CONVERT(FLOAT, b.OrderByQtyTU) AS OrderByQtyTU, CONVERT(FLOAT, b.OrderPriceTC) AS OrderPriceTC,
				CONVERT(FLOAT, b.OrderByQtyTU) AS ShipQtyTUAmount
			FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID = b.SO 
			WHERE a.DescFlexField_PrivateDescSeg1 = @PoDocNo AND  a.Org = @Org AND a.DescFlexField_PrivateDescSeg1 IS NOT NULL AND a.DescFlexField_PrivateDescSeg1 !=''
		),
		--累计汇总
		SoTotal AS 
		(
			SELECT a.SoMateCode, a.SoMateName, CONVERT(FLOAT, SUM(a.ShipQtyTUAmount)) TotalShipCount 
			FROM SoData a
			GROUP BY a.SoMateCode, a.SoMateName
		),
		MergeSo AS (
			SELECT *, STUFF((SELECT ',' + RelateSo+':'+ CONVERT(VARCHAR(30),CONVERT(FLOAT, ShipQtyTUAmount))  
			       FROM SoData WHERE SoMateCode = a.SoMateCode FOR XML PATH('')), 1, 1, '') SoDtl
			FROM SoTotal a
		),
		BomSoData AS 
		(
			--数据对比
			SELECT a.Code, a.Name, a.SPECS, a.BomNeedQty , b.TotalShipCount,b.SoMateCode, b.SoMateName
			FROM #BomDataMerge a LEFT JOIN MergeSo b ON a.Code = b.SoMateCode
			UNION ALL
			--未在Bom的物料
			SELECT NULL Code, NULL Name, NULL SPECS, NULL BomNeedQty, b.TotalShipCount, b.SoMateCode, b.SoMateName
			FROM MergeSo b 
			WHERE NOT EXISTS(SELECT 1 FROM #BomDataMerge a WHERE a.Code = b.SoMateCode)
		),
		FinalData AS
        (
			SELECT 
				ISNULL(a.Code, a.SoMateCode)AS Code,  ISNULL(a.Name, a.SoMateName) AS Name, a.SPECS
				,a.BomNeedQty , a.TotalShipCount				
			FROM BomSoData a
		)
		SELECT a.Code,a.Name,a.SPECS,CEILING(a.BomNeedQty)BomNeedQty,CEILING(a.TotalShipCount)TotalShipCount INTO #tempBom
		FROM  FinalData a  	

				
		DECLARE @count INT--数量超出源PO总BOM用量的SOLine数
		SELECT @count=COUNT(1)
		FROM dbo.SM_SO so INNER JOIN dbo.SM_SOLine soline ON so.ID=soline.SO
		LEFT JOIN #tempBom c ON soline.ItemInfo_ItemCode=c.Code
		--SELECT a.Code,a.Name,a.SPECS,a.BomNeedQty,a.TotalShipCount
		--FROM  FinalData a  			
		WHERE so.DocNo=@SODocNo
		AND ISNULL(c.BomNeedQty,-1)<>-1
		AND ISNULL(c.TotalShipCount,0)>ISNULL(c.BomNeedQty,0)

		IF @Count>0
		BEGIN--数量不正常
			SET @Result=(
			SELECT '行号：'+CONVERT(VARCHAR(10),soline.DocLineNo)+'，料号：'+soline.ItemInfo_ItemCode+'的数量超出了'+CONVERT(VARCHAR(50),c.TotalShipCount-c.BomNeedQty)
			FROM dbo.SM_SO so INNER JOIN dbo.SM_SOLine soline ON so.ID=soline.SO
			LEFT JOIN #tempBom c ON soline.ItemInfo_ItemCode=c.Code
			--SELECT a.Code,a.Name,a.SPECS,a.BomNeedQty,a.TotalShipCount
			--FROM  FinalData a  			
			WHERE so.DocNo=@SODocNo
			AND ISNULL(c.BomNeedQty,-1)<>-1
			AND ISNULL(c.TotalShipCount,0)>ISNULL(c.BomNeedQty,0)
			FOR XML PATH('')
			)
		END 
		ELSE--数量正常
        BEGIN			
			SET @Result='0'
			--判断SO中是否有料品不在BOM中
			SET @Remark=(
			SELECT '行号：'+CONVERT(VARCHAR(10),soline.DocLineNo)+',料号：'+soline.ItemInfo_ItemCode+';'
			FROM dbo.SM_SO so INNER JOIN dbo.SM_SOLine soline ON so.ID=soline.SO
			LEFT JOIN #tempBom c ON soline.ItemInfo_ItemCode=c.Code		
			WHERE so.DocNo=@SODocNo
			AND ISNULL(c.BomNeedQty,-1)=-1
			FOR XML PATH('')
			)
			IF ISNULL(@Remark,'')<>''
			BEGIN
				SET @Remark=LEFT(@Remark,LEN(@Remark)-1)+'不在BOM中'
				UPDATE dbo.SM_SO SET DescFlexField_PrivateDescSeg2=@Remark WHERE DocNo=@SODocNo--备注信息放到扩展字段2中
			END 
		END 		

		
END


