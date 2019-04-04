/*
���⣺���۶���BE���
�����ˣ����á������
����SO��ԴPO�ŵĶ����������������ϡ�ԴPO�й̶�4�������������PO��BOMԭ�����������ܣ����й���ԴPO��SO�е�ԭ�����������ܴ��ڼ��������BOM������
����ʱ�䣺2019-3-26
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

	DECLARE @Remark NVARCHAR(MAX)--���SO�д��ڷ�BOM�е���Ʒ��Ϣ����SO��ע�б�����XX��XXX�ϲ���BOM��
	DECLARE @OrgHk BIGINT = 1001712010015192
	DECLARE @Org BIGINT = 1001708020135665;
	DECLARE @PoData VARCHAR(1000);
	DECLARE @StandardTime DATE = dbo.fun_Auctus_GetInventoryDate(GETDATE());


	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#MainPoData') AND TYPE='U') BEGIN DROP TABLE #MainPoData; END 
	--������ͬ�����ɹ�������
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

	--��ȡbomData --���°汾
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
			CASE WHEN LEFT(b.Code, 5)='20201' OR b.IssueStyle = 4 --SMT���߲����� 
				THEN 1 ELSE 0 END IsSmtOrLast, b.IssueStyle, a.MateNo
		INTO #BomData
		FROM BomData a INNER JOIN dbo.Auctus_DailyBomResult b ON a.ID = b.MasterBom
		WHERE a.RowNum = 1;

	--Bom ���ݴ������
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#BomDataMerge') AND TYPE='U') BEGIN DROP TABLE #BomDataMerge; END 
	;WITH 
		BomData AS 
		(
			SELECT a.Code, a.Name, a.SPECS, a.MateNo, a.ProCode, a.ProName, a.IsSmtOrLast, a.ParentQty, a.UsageQty, a.TreeMateCodeRelation, a.SupplierConfirmQtyTU, a.IssueStyle,
					a.TotalRecievedQtyTU,
					--�ж�SMT�������µ����ϣ������ϵ��¼�
					(SELECT MAX(1) FROM #BomData b WHERE LEN(REPLACE(a.TreeMateCodeRelation, b.TreeMateCodeRelation, '')) != LEN(a.TreeMateCodeRelation) AND b.IsSmtOrLast = 1) IsSmtMate 
			FROM #BomData a
		),
		BomData2 AS 
		(
			SELECT a.Code, a.Name, a.SPECS, a.MateNo, a.ProCode, a.ProName, a.IsSmtOrLast, a.ParentQty, a.UsageQty, a.TreeMateCodeRelation, a.IsSmtMate, SupplierConfirmQtyTU,
				CONVERT(FLOAT, (a.UsageQty/a.ParentQty)*a.SupplierConfirmQtyTU) AS BomNeedQty,
				CONVERT(FLOAT, (a.UsageQty/a.ParentQty)*a.TotalRecievedQtyTU) AS HavedReciveQty
			FROM BomData a
			WHERE (a.IsSmtMate IS NULL OR a.IsSmtOrLast = 1) AND a.IssueStyle != 4 --�ų�������
		),
		--��������Bom��׼����
		BomData3 AS 
		(
			SELECT a.Code, a.Name, a.SPECS, SUM(a.BomNeedQty)BomNeedQty, SUM(HavedReciveQty)HavedReciveQty
			FROM BomData2 a 
			GROUP BY a.Code, a.Name, a.SPECS
		),
		--��Ʒת��
		ProPivot AS 
		(
			SELECT b.Code, PnA, PnB, PnC, PnD, PnE--, PnF, PnG 
			FROM (SELECT Code, MateNo, BomNeedQty FROM BomData2) a
			--PIVOT(SUM(BomNeedQty) FOR MateNo IN (PnA, PnB, PnC, PnD, PnE, PnF, PnG)) b
			PIVOT(SUM(BomNeedQty) FOR MateNo IN (PnA, PnB, PnC, PnD, PnE)) b
		),
		--��Ʒת��
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

	--���۵���Ϣ
	;WITH 
		--�����������۵���Ϣ
		SoData AS 
		(
			SELECT a.DescFlexField_PrivateDescSeg1 AS SourcePo, a.DocNo +'-' + CONVERT(VARCHAR(10), b.DocLineNo) AS RelateSo, a.CustomerPONo--�ͻ��ɹ�����
				, a.OrderBy_ShortName, a.OrderBy_Code, b.ItemInfo_ItemCode AS SoMateCode, b.ItemInfo_ItemName AS SoMateName, 
				CONVERT(FLOAT, b.OrderByQtyTU) AS OrderByQtyTU, CONVERT(FLOAT, b.OrderPriceTC) AS OrderPriceTC,
				CONVERT(FLOAT, b.OrderByQtyTU) AS ShipQtyTUAmount
			FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID = b.SO 
			WHERE a.DescFlexField_PrivateDescSeg1 = @PoDocNo AND  a.Org = @Org AND a.DescFlexField_PrivateDescSeg1 IS NOT NULL AND a.DescFlexField_PrivateDescSeg1 !=''
		),
		--�ۼƻ���
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
			--���ݶԱ�
			SELECT a.Code, a.Name, a.SPECS, a.BomNeedQty , b.TotalShipCount,b.SoMateCode, b.SoMateName
			FROM #BomDataMerge a LEFT JOIN MergeSo b ON a.Code = b.SoMateCode
			UNION ALL
			--δ��Bom������
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

				
		DECLARE @count INT--��������ԴPO��BOM������SOLine��
		SELECT @count=COUNT(1)
		FROM dbo.SM_SO so INNER JOIN dbo.SM_SOLine soline ON so.ID=soline.SO
		LEFT JOIN #tempBom c ON soline.ItemInfo_ItemCode=c.Code
		--SELECT a.Code,a.Name,a.SPECS,a.BomNeedQty,a.TotalShipCount
		--FROM  FinalData a  			
		WHERE so.DocNo=@SODocNo
		AND ISNULL(c.BomNeedQty,-1)<>-1
		AND ISNULL(c.TotalShipCount,0)>ISNULL(c.BomNeedQty,0)

		IF @Count>0
		BEGIN--����������
			SET @Result=(
			SELECT '�кţ�'+CONVERT(VARCHAR(10),soline.DocLineNo)+'���Ϻţ�'+soline.ItemInfo_ItemCode+'������������'+CONVERT(VARCHAR(50),c.TotalShipCount-c.BomNeedQty)
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
		ELSE--��������
        BEGIN			
			SET @Result='0'
			--�ж�SO���Ƿ�����Ʒ����BOM��
			SET @Remark=(
			SELECT '�кţ�'+CONVERT(VARCHAR(10),soline.DocLineNo)+',�Ϻţ�'+soline.ItemInfo_ItemCode+';'
			FROM dbo.SM_SO so INNER JOIN dbo.SM_SOLine soline ON so.ID=soline.SO
			LEFT JOIN #tempBom c ON soline.ItemInfo_ItemCode=c.Code		
			WHERE so.DocNo=@SODocNo
			AND ISNULL(c.BomNeedQty,-1)=-1
			FOR XML PATH('')
			)
			IF ISNULL(@Remark,'')<>''
			BEGIN
				SET @Remark=LEFT(@Remark,LEN(@Remark)-1)+'����BOM��'
				UPDATE dbo.SM_SO SET DescFlexField_PrivateDescSeg2=@Remark WHERE DocNo=@SODocNo--��ע��Ϣ�ŵ���չ�ֶ�2��
			END 
		END 		

		
END


