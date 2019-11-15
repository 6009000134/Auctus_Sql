﻿/*
创建时间：2019-01-10
创建只修改时间的采购订单变更单

2019-3-14
变更交期相差小于7天的排除
ADD(2019-7-31)
原逻辑：变更交期相差小于7天的排除
修改成
现逻辑：原始日期和重排日期在同一自然周内的不处理（周一至周日）； 
*/
ALTER PROC [dbo].[sp_Auctus_UI_CreatePOModify]
(
@UserName NVARCHAR(100),
@Result NVARCHAR(10) OUT--0\失败  1\成功
)
AS
BEGIN

BEGIN TRAN tran_Test
DECLARE @tran_Error INT=0
BEGIN TRY 
--SET NOCOUNT on
DECLARE @Org BIGINT=1001708020135665
DECLARE @POModifyDocType BIGINT=1001901260018062

--MRP重排建议（取未执行、更新操作、只改时间的）
IF	OBJECT_ID('tempdb.dbo.#tempReschedule') IS NULL
CREATE TABLE #tempReschedule(
ID BIGINT,
DocNo VARCHAR(50),
Linenum INT,
PlanLineNum INT,
SMQty INT,
RescheduleQty INT,
SupplierConfirmQtyTU INT,
PlanArriveQtyTU INT,
OriginalDate DATETIME,
RescheduleDate DATETIME,
POID BIGINT,
BusinessDate DATETIME,
POLineID BIGINT,
POShipLineID BIGINT,
DeliveryDate DATETIME,
PlanArriveDate DATETIME,
NeedPODate DATETIME,
ItemInfo_ItemID BIGINT,
PlanarriveDateDiff INT,
NeedPODateDiff INT,
RN INT,
PlanArriveDate2 DATETIME,
NeedPODate2 DATETIME
)
ELSE
TRUNCATE TABLE #tempReschedule

;
WITH data1 as
(
SELECT 
a.ID,a.DocNo,a.Linenum,a.PlanLineNum,a.SMQty,a.RescheduleQty
,poship.SupplierConfirmQtyTU,poship.PlanArriveQtyTU
,a.OriginalDate,a.RescheduleDate
,po.ID POID,po.BusinessDate,poline.ID POLineID,poship.ID POShipLineID
,poship.DeliveryDate,poship.PlanArriveDate,poship.NeedPODate
,poship.ItemInfo_ItemID
--,s.InspectLeadTime,s.OrderLeadTime,mi.PurForwardProcessLT,mi.PurProcessLT,mi.PurBackwardProcessLT
,CASE WHEN ISNULL(s.InspectLeadTime,0)=0 THEN ISNULL(mi.PurBackwardProcessLT,0) ELSE ISNULL(s.InspectLeadTime,0) END PlanarriveDateDiff
,CASE WHEN ISNULL(s.InspectLeadTime,0)=0 AND ISNULL(s.OrderLeadTime,0)=0 THEN ISNULL(mi.PurBackwardProcessLT,0)+ISNULL(mi.PurForwardProcessLT,0)+ISNULL(mi.PurProcessLT,0) 
WHEN ISNULL(s.InspectLeadTime,0)=0 AND ISNULL(s.OrderLeadTime,0)<>0 THEN ISNULL(mi.PurBackwardProcessLT,0)+s.OrderLeadTime+ISNULL(mi.PurProcessLT,0) 
WHEN ISNULL(s.InspectLeadTime,0)<>0 AND ISNULL(s.OrderLeadTime,0)=0 THEN s.InspectLeadTime+ISNULL(mi.PurForwardProcessLT,0)+ISNULL(mi.PurProcessLT,0) 
ELSE s.InspectLeadTime+s.OrderLeadTime+ISNULL(mi.PurProcessLT,0) END NeedPODateDiff
,DENSE_RANK()OVER(ORDER BY a.DocNo) RN
FROM dbo.MRP_Reschedule a INNER JOIN dbo.PM_PurchaseOrder po ON a.DocNo=po.DocNo
INNER JOIN dbo.PM_POLine poline ON po.ID=poline.PurchaseOrder AND a.Linenum=poline.DocLineNo
INNER JOIN dbo.PM_POShipLine poship ON poline.ID=poship.POLine AND a.PlanLineNum=poship.SubLineNo
LEFT JOIN dbo.MRP_PlanVersion b ON a.PlanVersion=b.ID
LEFT JOIN dbo.MRP_PlanName c ON b.PlanName=c.ID
LEFT JOIN dbo.CBO_ItemMaster d ON a.Item=d.ID
LEFT JOIN dbo.CBO_MrpInfo mi ON poship.ItemInfo_ItemID=mi.ItemMaster
LEFT JOIN dbo.CBO_SupplierItem s ON a.Supplier=s.SupplierInfo_Supplier AND poship.ItemInfo_ItemID=s.ItemInfo_ItemID
LEFT JOIN dbo.PM_POModify pomodify ON a.DocNo=pomodify.PODocNo AND pomodify.Status IN(0,1)
WHERE 1=1 
AND a.SupplyType=3--采购订单
AND a.Org=1001708020135665--300组织
AND po.Status=2--已审核的采购单
AND poship.Status NOT IN (3,4,5)
AND po.Org=1001708020135665
AND c.PlanMethod='1'--MRP计划
AND a.ConfirmType=0--未执行
AND a.RType='1'--MRP更新操作
AND a.SMQty=poship.SupplierConfirmQtyTU AND a.SMQty=a.RescheduleQty
AND PATINDEX('%WPO%',a.DocNo)=0
--AND poship.SupplierConfirmQtyTU=poship.DeficiencyQtyTU--未发生收货
--AND poship.SupplierConfirmQtyTU=poship.PlanArriveQtyTU--数量不变，只变时间
AND pomodify.DocNo IS NULL--没有未审核的变更单
--AND a.DocNo='PO30180627020' AND a.Linenum=60 AND a.PlanLineNum=60
--AND ABS(DATEDIFF(DAY,a.OriginalDate,a.RescheduleDate))>7
AND (a.RescheduleDate<CONVERT(DATE,DATEADD(DAY,(-1)*(CASE WHEN DATEPART(dw,a.OriginalDate)=1 THEN 8 ELSE DATEPART(dw,a.OriginalDate)end-2),a.OriginalDate)) 
OR a.RescheduleDate>=CONVERT(DATE,DATEADD(DAY,7+(-1)*(CASE WHEN DATEPART(dw,a.OriginalDate)=1 THEN 8 ELSE DATEPART(dw,a.OriginalDate)end-2),a.OriginalDate)))
),
data2 AS
(
SELECT *
,CASE WHEN DATEADD(DAY,(-1)*a.PlanarriveDateDiff,a.RescheduleDate)>a.BusinessDate THEN DATEADD(DAY,(-1)*a.PlanarriveDateDiff,a.RescheduleDate)
ELSE a.BusinessDate END PlanArriveDate2
,CASE WHEN DATEADD(DAY,(-1)*a.NeedPODateDiff,a.RescheduleDate)>a.BusinessDate THEN DATEADD(DAY,(-1)*a.NeedPODateDiff,a.RescheduleDate)
ELSE a.BusinessDate END NeedPODate2
FROM data1 a
--WHERE a.RN=1
)
INSERT INTO #tempReschedule
SELECT * FROM data2

IF (SELECT COUNT(1) FROM #tempReschedule)>0
BEGIN
--游标cur变量
DECLARE @DocNo VARCHAR(50),@POID BIGINT,@RN INT
--游标curData变量
DECLARE @ID bigint,@DocLineNo int,@SubLineNo INT,@DeliveryDate DATETIME,@PlanArriveDate DATETIME,@NeedPODate datetime,@RescheduleDate DATETIME,@POLineID BIGINT,@POShipLineID BIGINT,@ItemInfo_ItemID BIGINT
	DECLARE @p3 dbo.tvp_PM_POModify
	DECLARE @p31 dbo.tvp_PM_POModify_Trl
	DECLARE @p4 dbo.tvp_PM_POShiplineModify;
	declare @p5 dbo.tvp_PM_POShiplineModify_Trl
	declare @p6 dbo.tvp_PM_POModifyLine
	DECLARE @Count INT
	DECLARE @DocNoIndex VARCHAR(10)
	DECLARE @DocStr VARCHAR(50)='SPOM30'+RIGHT(CONVERT(VARCHAR(50),GETDATE(),112),6)
	SELECT @Count=ISNULL(MAX(CONVERT(INT,RIGHT(a.DocNo,3))),0) FROM dbo.PM_POModify a WHERE PATINDEX('%'+@DocStr+'%',a.DocNo)>0	
	--变更单ID
	DECLARE @POModifyID BIGINT=1000000000000000+CONVERT(BIGINT,RIGHT(CONVERT(VARCHAR(50),GETDATE(),112),6))*10000000+DATEPART(HOUR,GETDATE())*60*60*100+DATEPART(MINUTE,GETDATE())*60*100+DATEPART(SECOND,GETDATE())*1000
DECLARE cur CURSOR
FOR 
SELECT DISTINCT DocNo,POID,rn FROM #tempReschedule
OPEN cur
FETCH NEXT FROM	cur INTO @DocNo,@POID,@RN
	WHILE @@FETCH_STATUS=0
	BEGIN -- Start While1
	
	--生成变更单
	--生成变更单号
	SET @Count=@Count+1
	IF @Count<10
	SET @DocNoIndex='00'+CONVERT(VARCHAR(10),@Count)
	ELSE IF @Count<100
	SET @DocNoIndex='0'+CONVERT(VARCHAR(10),@Count)
	ELSE 
	SET @DocNoIndex=CONVERT(VARCHAR(10),@Count)
	DECLARE @POModifyDocNo VARCHAR(50)=@DocStr+@DocNoIndex
	--SELECT @POModifyDocNo
	--变更次数
	DECLARE @modifyIndex INT=(SELECT ISNULL(MAX(a.ModifyIndex),0)+1 FROM dbo.PM_POModify a WHERE a.PODocNo=@DocNo)
	--插入变更单数据
	INSERT  INTO @p3
	VALUES  ( '00000000-0000-0000-0000-000000000000', -1, -1, 0, 0, 0,
          '00000000-0000-0000-0000-000000000000', N'', NULL, NULL, 0,
          @DocNo, @POID, @Org, 2002--ModifyReason:2002为系统交期重排
		  , @modifyIndex,
          GETDATE(), @UserName, NULL, 0, @POModifyID, N'', NULL,NULL, NULL
		  , @POModifyDocType, @POModifyDocNo, N'', N'', N'', N'',
          N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'',
          N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'',
          N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'',
          N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'',
          N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'',
          N'', N'', N'', N'', N'',@POID--私有字段1
		  , N'', GETDATE(), @UserName,NULL, N'', N'', N'', 0, NULL, GETDATE(), NULL, N'', 0 );
	--POModify_Trl
	INSERT INTO @p31 VALUES('zh-CN',@POModifyID,'','系统生成单据')

		--生成采购计划行变更变更，以及变更的字段
		DECLARE @tempID BIGINT =@POModifyID 
		DECLARE @PlanarriveDate2 DATETIME,@NeedPODate2 DATETIME
		DECLARE curData CURSOR
		FOR
		SELECT ID ,Linenum,PlanLineNum,DeliveryDate,PlanArriveDate,NeedPODate,RescheduleDate,PlanarriveDate2,NeedPODate2,POLineID,POShipLineID,ItemInfo_ItemID  FROM #tempReschedule WHERE RN=@RN
		OPEN curData
		FETCH NEXT FROM curData INTO @ID ,@DocLineNo ,@SubLineNo ,@DeliveryDate ,@PlanArriveDate,@NeedPODate,@RescheduleDate,@PlanarriveDate2,@NeedPODate2,@POLineID ,@POShipLineID,@ItemInfo_ItemID
		WHILE @@FETCH_STATUS=0
		BEGIN--Start While2		
			--生成采购计划行变更数据PM_POShipLineModify
			SET @tempID=@tempID+1
			DECLARE @POModifyShiplineID BIGINT=@tempID+1
			DECLARE @POModifyLineID BIGINT=@tempID+2			
		
			--PM_POShiplineModify
			INSERT INTO @p4
			select [Wh], [WeightUOM], [Weight], [VoucherType], [VoucherID], [VoucherCode], [VolumeUOM], [Volume], [TUToTBURateB], [TUToTBURate], [TradeUOMB], [TradeUOM], [TradeBaseUOMB], [TradeBaseUOM], [TotalTaxTC], [TotalTaxFC], [TotalTaxAC], [TotalRtnFillQtyTU], [TotalRtnFillQtyTBU], [TotalRtnFillQtySU], [TotalRtnFillQtyPU], [TotalRtnFillQtyCU], [TotalRtnDeductQtyTU], [TotalRtnDeductQtyTBU], [TotalRtnDeductQtySU], [TotalRtnDeductQtyPU], [TotalRtnDeductQtyCU], [TotalRefilledQtyTU], [TotalRefilledQtyTBU], [TotalRefilledQtySU], [TotalRefilledQtyPU], [TotalRefilledQtyCU], [TotalRecievedQtyTU], [TotalRecievedQtyTBU], [TotalRecievedQtySU], [TotalRecievedQtyPU], [TotalRecievedQtyCU], [TotalPrePayedQtyTU], [TotalPrePayedQtyTBU], [TotalPrePayedQtySU], [TotalPrePayedQtyPU], [TotalPrePayedQtyCU], [TotalPrePayedMnyTC], [TotalPrePayedMnyFC], [TotalPrePayedMnyAC], [TotalPayedQtyTU], [TotalPayedQtyTBU], [TotalPayedQtySU], [TotalPayedQtyPU], [TotalPayedQtyCU], [TotalPayedMnyTC], [TotalPayedMnyFC], [TotalPayedMnyAC], [TotalMnyTC], [TotalMnyFC], [TotalMnyAC], [TotalMatchedTaxMnyTC], [TotalMatchedTaxMnyFC], [TotalMatchedTaxMnyAC], [TotalMatchedQtyTU], [TotalMatchedQtyTBU], [TotalMatchedQtySU], [TotalMatchedQtyPU], [TotalMatchedQtyCU], [TotalMatchedNetMnyTC], [TotalMatchedNetMnyFC], [TotalMatchedNetMnyAC], [TotalMatchedMnyTC], [TotalMatchedMnyFC], [TotalMatchedMnyAC], [TotalFeeTC], [TotalFeeFC], [TotalFeeAC], [TotalConfirmedTaxMnyTC], [TotalConfirmedTaxMnyFC], [TotalConfirmedTaxMnyAC], [TotalConfirmedQtyTU], [TotalConfirmedQtyTBU], [TotalConfirmedQtySU], [TotalConfirmedQtyPU], [TotalConfirmedQtyCU], [TotalConfirmedNetMnyTC], [TotalConfirmedNetMnyFC], [TotalConfirmedNetMnyAC], [TotalConfirmedMnyTC], [TotalConfirmedMnyFC], [TotalConfirmedMnyAC], [TotalArriveQtyTU], [TotalArriveQtyTBU], [TotalArriveQtySU], [TotalArriveQtyPU], [TotalArriveQtyCU], [TBUToPBURate], [TBUToCBURate], [TaskOutput_EntityType], [TaskOutput_EntityID], [TaskDate], [Task], [SysVersion], [SupplierLot], [SupplierConfirmQtyTU], [SupplierConfirmQtyTBU], [SupplierConfirmQtySU], [SupplierConfirmQtyPU], [SupplierConfirmQtyCU], [SuppierItemCode], [SubLineNo], [StoreUOM], [Status], [StateMachineID]
			, [SrcPOShipLineNo], [SrcPOShipLine], [SrcPOLineNo], [SrcPOLine], [SrcPODocNo], [SrcPO], @POShipLineID, [SrcDocVersion], [SrcDocType], [SrcDocPROrg], [SrcDocPRLineNo], [SrcDocPRLine], [SrcDocPRDocNo], [SrcDocPR], [SrcDocInfo_SrcDocVer], [SrcDocInfo_SrcDocTransType_EntityType], [SrcDocInfo_SrcDocTransType_EntityID], [SrcDocInfo_SrcDocSubLineNoStr], [SrcDocInfo_SrcDocSubLineNo], [SrcDocInfo_SrcDocSubLine_EntityType], [SrcDocInfo_SrcDocSubLine_EntityID], 
			[SrcDocInfo_SrcDocOrg], [SrcDocInfo_SrcDocNo], [SrcDocInfo_SrcDocLineNo], [SrcDocInfo_SrcDocLine_EntityType], [SrcDocInfo_SrcDocLine_EntityID], [SrcDocInfo_SrcDocDate], [SrcDocInfo_SrcDocBusiType], [SrcDocInfo_SrcDoc_EntityType], [SrcDocInfo_SrcDoc_EntityID], [SrcDocCentralizePOShipLine], 
			[SrcDocCentralizePOOrg], [SrcDocCentralizePOLine], [SrcDocCentralizePO], [SrcCooperateType], [SrcCooperateShipLine], [SrcCooperateOrg], [SrcBudgetOrg], [SrcBudgetLine], [SrcBudgetDocType], [SplitedOutQtyTU], [SplitedOutQtyTBU], [SplitedOutQtyPU], [SplitBeforeQty], [SnCode], [ShiptoSite_SupplierSite], 
			[ShiptoSite_Code], [ShipToCustomSize_CustomerSite], [ShipToCustomSize_Code], [ShipperOrg], [SeiBanCode], [SeiBan], [RUToRBURateB], [RUToRBURate], [RoutingNo], [Routing_EntityType], [Routing_EntityID], [RFQVer], [RFQLineKey_EntityType], [RFQLineKey_EntityID], [RFQKey_EntityType], [RFQKey_EntityID], [RFQID], 
			[ResrvQtySU], [ResrvExecQtySU], [ResrvConsumeQtySU], [ReservedRcvQtyTU], [ReservedRcvQtyTBU], [ReservedQtyTU], [ReservedQtyTBU], [ReqUOMB], [ReqUOM], [RequireOrg], [RequireMan], [RequireDept], [ReqQtyTU], [ReqQtyTBU], [ReqQtyRU], [ReqQtyRBU], [ReqQtyPU], [ReqQtyCU], [ReqBaseUOMB], [ReqBaseUOM], 
			[ReleaseUser], [ReleaseReason], [ReleaseDate], [RejectedQtyTU], [RejectedQtyTBU], [RejectedQtySU], [RejectedQtyPU], [RejectedQtyCU], [RcvShipBy], [RcvOrg], [RCVEstimateTaxAmountAC], [RCVEstimateAmountExcTaxAC], [PUToPBURate], [PromptInfo], [Project], [ProduceLineNo], [ProduceLineDate], 
			[ProduceLine_EntityType], [ProduceLine_EntityID], [ProcessUOMToProcessUOMBRate], [ProcessUOMB], [ProcessUOM], [ProcessRejectQty], [ProcessReFillQty], [ProcessReDeductQty], [ProcessRcvQty], [ProcessQty], [ProcessDeficiencyQty], [PriceUOM], [PriceBaseUOM], [PreOperationSupplier], [PreOperationNo], 
			[PreOperation_EntityType], [PreOperation_EntityID], [PreMaturityDate], @POModifyID, [PlanedQtyTU], [PlanedQtyTBU], [PlanedQtySU], [PlanedQtyPU], [PlanedQtyCU], [PlanArriveQtyTU], [PlanArriveQtyTBU], [PlanArriveQtySU], [PlanArriveQtyPU], [PlanArriveQtyCU]
			, @PlanarriveDate2--，PlanArriveDate
			, [Piece], [PerProcessQty], [PCNo], [PCLineNo], [PCLine_EntityType], [PCLine_EntityID], [PC_EntityType], [PC_EntityID], [ParentLineNo], [ParentLine], [ParentKITLineNO], [OperationNo_EntityType], [OperationNo_EntityID], [NotModifyAttributes], [NonLCQtyTU],  [NonLCQtyPU], [NonLCQtyCU], [NonLCMnyTC], [NonLCMnyFC], [NonLCMnyAC], [NextOperationSupplier], [NextOperationNo], [NextOperation_EntityType], [NextOperation_EntityID]
			, @POLineID, @DocLineNo, [NetMnyTC], [NetMnyFC], [NetMnyAC], [NetFeeTC], [NetFeeFC], [NetFeeAC]
			, @NeedPODate2--,NeedPODate
			, [MRPRequireDate], [MOKey_EntityType], [MOKey_EntityID], [ModifiedOn]
			, @UserName, [MO], [MnyBudgetProject], [Mfc], [MatchedQtyToRcvMnyTC], [MatchedQtyToRcvMnyFC], [MatchedQtyToRcvMnyAC], [LotInvalidation], [LCQtyTU],  [LCQtyPU], [LCQtyCU], [LCMnyTC], [LCMnyFC], [LCMnyAC], [ItemLotCode], [ItemLot_LotValidDate], [ItemLot_LotMaster], [ItemLot_LotCode], [ItemLot_DisabledDatetime], [ItemInfo_ItemVersion], [ItemInfo_ItemPotency], [ItemInfo_ItemOpt9], [ItemInfo_ItemOpt8], [ItemInfo_ItemOpt7], [ItemInfo_ItemOpt6], [ItemInfo_ItemOpt5], [ItemInfo_ItemOpt4], [ItemInfo_ItemOpt3], [ItemInfo_ItemOpt2], [ItemInfo_ItemOpt10], [ItemInfo_ItemOpt1], [ItemInfo_ItemName], [ItemInfo_ItemID], [ItemInfo_ItemGrade], [ItemInfo_ItemCode], [IsTUCanChange], [IsTransferedToGL], [IsSUCanChange], [IsSplited], [IsSeiBanEditable], [IsRFQDiscount], [IsRelationCompany], [IsPUCanChange], [IsFirm], [IsFIClose], [IsCUCanChange], [InitRtnFillQtyTU], [InitRtnFillQtyTBU], [InitRtnDeductQtyTU], [InitRtnDeductQtyTBU], [InitRecievedQtyTU], [InitRecievedQtyTBU], [InitPrePayedQtyPU], [InitPrePayedMnyTC], [InitPayedQtyPU], [InitPayedMnyTC], [InitMatchedTaxTC], [InitMatchedQtyPU], [InitMatchedNetMnyTC], [InitMatchedMnyTC], [InitConfirmedTaxMnyTC], [InitConfirmedQtyPU], [InitConfirmedNetMnyTC], [InitConfirmedMnyTC], @POModifyShiplineID, [HoldUser], [HoldReason], [HoldDate], [HasCreateBudgetData], [FIAccountPeriod], [FeeTaxTC], [FeeTaxFC], [FeeTaxAC], [EstimatePriceMnyTC], [EstimatePriceMnyFC], [EstimatePriceMnyAC], [EstimatePriceACPU], [EstimatePriceACCU], [DIID], [DescFlexSegments_PubDescSeg9], 
			[DescFlexSegments_PubDescSeg8], [DescFlexSegments_PubDescSeg7], [DescFlexSegments_PubDescSeg6], [DescFlexSegments_PubDescSeg50], [DescFlexSegments_PubDescSeg5], [DescFlexSegments_PubDescSeg49], [DescFlexSegments_PubDescSeg48], [DescFlexSegments_PubDescSeg47], [DescFlexSegments_PubDescSeg46], 
			[DescFlexSegments_PubDescSeg45], [DescFlexSegments_PubDescSeg44], [DescFlexSegments_PubDescSeg43], [DescFlexSegments_PubDescSeg42], [DescFlexSegments_PubDescSeg41], [DescFlexSegments_PubDescSeg40], [DescFlexSegments_PubDescSeg4], [DescFlexSegments_PubDescSeg39], [DescFlexSegments_PubDescSeg38], 
			[DescFlexSegments_PubDescSeg37], [DescFlexSegments_PubDescSeg36], [DescFlexSegments_PubDescSeg35], [DescFlexSegments_PubDescSeg34], [DescFlexSegments_PubDescSeg33], [DescFlexSegments_PubDescSeg32], [DescFlexSegments_PubDescSeg31], [DescFlexSegments_PubDescSeg30], [DescFlexSegments_PubDescSeg3], 
			[DescFlexSegments_PubDescSeg29], [DescFlexSegments_PubDescSeg28], [DescFlexSegments_PubDescSeg27], [DescFlexSegments_PubDescSeg26], [DescFlexSegments_PubDescSeg25], [DescFlexSegments_PubDescSeg24], [DescFlexSegments_PubDescSeg23], [DescFlexSegments_PubDescSeg22], [DescFlexSegments_PubDescSeg21], 
			[DescFlexSegments_PubDescSeg20], [DescFlexSegments_PubDescSeg2], [DescFlexSegments_PubDescSeg19], [DescFlexSegments_PubDescSeg18], [DescFlexSegments_PubDescSeg17], [DescFlexSegments_PubDescSeg16], [DescFlexSegments_PubDescSeg15], [DescFlexSegments_PubDescSeg14], [DescFlexSegments_PubDescSeg13], 
			[DescFlexSegments_PubDescSeg12], [DescFlexSegments_PubDescSeg11], [DescFlexSegments_PubDescSeg10], [DescFlexSegments_PubDescSeg1], [DescFlexSegments_PrivateDescSeg9], [DescFlexSegments_PrivateDescSeg8], [DescFlexSegments_PrivateDescSeg7], [DescFlexSegments_PrivateDescSeg6], 
			[DescFlexSegments_PrivateDescSeg5], [DescFlexSegments_PrivateDescSeg4], [DescFlexSegments_PrivateDescSeg30], [DescFlexSegments_PrivateDescSeg3], [DescFlexSegments_PrivateDescSeg29], [DescFlexSegments_PrivateDescSeg28], [DescFlexSegments_PrivateDescSeg27], [DescFlexSegments_PrivateDescSeg26], [DescFlexSegments_PrivateDescSeg25], [DescFlexSegments_PrivateDescSeg24], [DescFlexSegments_PrivateDescSeg23], [DescFlexSegments_PrivateDescSeg22], [DescFlexSegments_PrivateDescSeg21], [DescFlexSegments_PrivateDescSeg20], [DescFlexSegments_PrivateDescSeg2], [DescFlexSegments_PrivateDescSeg19], [DescFlexSegments_PrivateDescSeg18], [DescFlexSegments_PrivateDescSeg17], [DescFlexSegments_PrivateDescSeg16], [DescFlexSegments_PrivateDescSeg15], [DescFlexSegments_PrivateDescSeg14], [DescFlexSegments_PrivateDescSeg13], [DescFlexSegments_PrivateDescSeg12], [DescFlexSegments_PrivateDescSeg11], [DescFlexSegments_PrivateDescSeg10], @ID, [DescFlexSegments_ContextValue], [DemondCode]
			, @RescheduleDate--deliverydate
			, [DeliverCheckQtyTU], [DeliverCheckQtyTBU], [DeliverCheckQtySU], [DeliverCheckQtyPU], [DeliverCheckQtyCU], [DeficiencyQtyTU], [DeficiencyQtyTBU], [DeficiencyQtySU], [DeficiencyQtyPU], [DeficiencyQtyCU], [CUToCBURate], [CurrentOrg], [CurOperationNo], [CreatedOn]
			, @UserName, [CostUOM], [CostPercent], [CostBaseUOM], [CooperateSO], [CooperateOrg], [Container], [CentralizedPurType], [CancelApprovedOn], [CancelApprovedBy], [Cancel_CancelUser], [Cancel_CancelReason], [Cancel_Canceled], [Cancel_CancelDate], [BudgetReplaceClue], [BomLineNo], [BizClosedOn], [BizBudgetProject], [Billsetcode], [BalanceRouteCode], [ApprovedOn], [ApprovedBy], 2, [ActionType] 
			FROM dbo.PM_POShipLine a WHERE a.ID=@POShipLineID			

			--PM_POShiplineModify_Trl			
			DECLARE @ShiptoSite_Name NVARCHAR(255)--出货位置
			SELECT @ShiptoSite_Name=b.Name FROM dbo.PM_POShipLine p LEFT JOIN  dbo.CBO_SupplierSite a ON p.ShiptoSite_SupplierSite=a.ID  LEFT JOIN dbo.CBO_SupplierSite_Trl b ON a.ID=b.ID
			WHERE p.ID=@POShipLineID
			insert into @p5 values(N'zh-CN',NULL,@ShiptoSite_Name,NULL,NULL,@POModifyShiplineID,NULL)

			--生成变更字段数据PM_POModifyLine
			insert into @p6 values(0,@POShipLineID,@SubLineNo,@POModifyID,@POLineID,@DocLineNo,N'',N'',GETDATE(),N'UFIDA.U9.PM.PO.POShipLine',N'UFIDA.U9.PM.PO.POShipLine',@POShipLineID,N'System.DateTime',N'要求交货日',N'DeliveryDate',@UserName,@POShipLineID,@ItemInfo_ItemID,@POModifyLineID,0,CONVERT(VARCHAR(50),@DeliveryDate,121),CONVERT(VARCHAR(50),@RescheduleDate,121),GETDATE(),@UserName,N'',N'',2)
			SET @POModifyLineID=@POModifyLineID+1
			insert into @p6 values(0,@POShipLineID,@SubLineNo,@POModifyID,@POLineID,@DocLineNo,N'',N'',GETDATE(),N'UFIDA.U9.PM.PO.POShipLine',N'UFIDA.U9.PM.PO.POShipLine',@POShipLineID,N'System.DateTime',N'计划到货日',N'PlanArriveDate',@UserName,@POShipLineID,@ItemInfo_ItemID,@POModifyLineID,0,CONVERT(VARCHAR(50),@PlanArriveDate,121),CONVERT(VARCHAR(50),@PlanarriveDate2,121),GETDATE(),@UserName,N'',N'',2)
			SET @POModifyLineID=@POModifyLineID+1
			insert into @p6 values(0,@POShipLineID,@SubLineNo,@POModifyID,@POLineID,@DocLineNo,N'',N'',GETDATE(),N'UFIDA.U9.PM.PO.POShipLine',N'UFIDA.U9.PM.PO.POShipLine',@POShipLineID,N'System.DateTime',N'应下订单日',N'NeedPODate',@UserName,@POShipLineID,@ItemInfo_ItemID,@POModifyLineID,0,CONVERT(VARCHAR(50),@NeedPODate,121),CONVERT(VARCHAR(50),@NeedPODate2,121),GETDATE(),@UserName,N'',N'',2)			
			SET @tempID=@POModifyLineID+1--设置新的POModify ID
			FETCH NEXT FROM curData INTO @ID ,@DocLineNo ,@SubLineNo ,@DeliveryDate ,@PlanArriveDate,@NeedPODate,@RescheduleDate,@PlanarriveDate2,@NeedPODate2,@POLineID ,@POShipLineID,@ItemInfo_ItemID
        END --End While2
		CLOSE curData
		DEALLOCATE curData--关闭游标curData
	SET @POModifyID=@tempID+1
	FETCH NEXT FROM cur INTO @DocNo,@POID,@RN
    END --End While1
CLOSE cur
DEALLOCATE cur


--------------------------------------------------------------------------------------
exec sp_executesql N'INSERT INTO PM_POModify ( [WorkFlowID], [WFOriginalState], [WFCurrentState], [Version], [SysVersion], [Status]
	,[StateMachineID], [ReleaseUser], [ReleaseReason], [ReleaseDate], [PrintAmount]
	,[PODocNo], [PO], [Org], [ModifyReason], [ModifyIndex]
	,[ModifiedOn], [ModifiedBy], [LatestPrintedDate], [IsModifyVersion], [ID], [HoldUser], [HoldReason], [HoldDate], [FlowInstance]
	,[DocumentType], [DocNo],[DescFlexField_PubDescSeg9], [DescFlexField_PubDescSeg8], [DescFlexField_PubDescSeg7], [DescFlexField_PubDescSeg6], [DescFlexField_PubDescSeg50], [DescFlexField_PubDescSeg5], [DescFlexField_PubDescSeg49], [DescFlexField_PubDescSeg48], [DescFlexField_PubDescSeg47], [DescFlexField_PubDescSeg46], [DescFlexField_PubDescSeg45], [DescFlexField_PubDescSeg44], [DescFlexField_PubDescSeg43], [DescFlexField_PubDescSeg42], [DescFlexField_PubDescSeg41], [DescFlexField_PubDescSeg40], [DescFlexField_PubDescSeg4], [DescFlexField_PubDescSeg39], [DescFlexField_PubDescSeg38], [DescFlexField_PubDescSeg37], [DescFlexField_PubDescSeg36], [DescFlexField_PubDescSeg35], [DescFlexField_PubDescSeg34], [DescFlexField_PubDescSeg33], [DescFlexField_PubDescSeg32], [DescFlexField_PubDescSeg31], [DescFlexField_PubDescSeg30], [DescFlexField_PubDescSeg3], [DescFlexField_PubDescSeg29], [DescFlexField_PubDescSeg28], [DescFlexField_PubDescSeg27], [DescFlexField_PubDescSeg26], [DescFlexField_PubDescSeg25], [DescFlexField_PubDescSeg24], [DescFlexField_PubDescSeg23], [DescFlexField_PubDescSeg22], [DescFlexField_PubDescSeg21], [DescFlexField_PubDescSeg20], [DescFlexField_PubDescSeg2], [DescFlexField_PubDescSeg19], [DescFlexField_PubDescSeg18], [DescFlexField_PubDescSeg17], [DescFlexField_PubDescSeg16], [DescFlexField_PubDescSeg15], [DescFlexField_PubDescSeg14], [DescFlexField_PubDescSeg13], [DescFlexField_PubDescSeg12], [DescFlexField_PubDescSeg11], [DescFlexField_PubDescSeg10], [DescFlexField_PubDescSeg1], [DescFlexField_PrivateDescSeg9], [DescFlexField_PrivateDescSeg8], [DescFlexField_PrivateDescSeg7], [DescFlexField_PrivateDescSeg6], [DescFlexField_PrivateDescSeg5], [DescFlexField_PrivateDescSeg4], [DescFlexField_PrivateDescSeg30], [DescFlexField_PrivateDescSeg3], [DescFlexField_PrivateDescSeg29], [DescFlexField_PrivateDescSeg28], [DescFlexField_PrivateDescSeg27], [DescFlexField_PrivateDescSeg26], [DescFlexField_PrivateDescSeg25], [DescFlexField_PrivateDescSeg24], [DescFlexField_PrivateDescSeg23], [DescFlexField_PrivateDescSeg22], [DescFlexField_PrivateDescSeg21], [DescFlexField_PrivateDescSeg20], [DescFlexField_PrivateDescSeg2], [DescFlexField_PrivateDescSeg19], [DescFlexField_PrivateDescSeg18], [DescFlexField_PrivateDescSeg17], [DescFlexField_PrivateDescSeg16], 
	[DescFlexField_PrivateDescSeg15], [DescFlexField_PrivateDescSeg14], [DescFlexField_PrivateDescSeg13], [DescFlexField_PrivateDescSeg12], [DescFlexField_PrivateDescSeg11], [DescFlexField_PrivateDescSeg10], [DescFlexField_PrivateDescSeg1], [DescFlexField_ContextValue], [CreatedOn], [CreatedBy], 
	[CancelApprovedOn], [CancelApprovedBy], [Cancel_CancelUser], [Cancel_CancelReason], [Cancel_Canceled], [Cancel_CancelDate], [BusinessDate], [ApprovedOn], [ApprovedBy], [ActionType] ) 
	select [WorkFlowID], [WFOriginalState], [WFCurrentState], [Version], [SysVersion], [Status], [StateMachineID], [ReleaseUser], 
	[ReleaseReason], [ReleaseDate], [PrintAmount], [PODocNo], [PO], [Org], [ModifyReason], [ModifyIndex], [ModifiedOn], [ModifiedBy], [LatestPrintedDate], [IsModifyVersion], [ID], [HoldUser], [HoldReason], [HoldDate], [FlowInstance], [DocumentType], [DocNo], [DescFlexField_PubDescSeg9], 
	[DescFlexField_PubDescSeg8], [DescFlexField_PubDescSeg7], [DescFlexField_PubDescSeg6], [DescFlexField_PubDescSeg50], [DescFlexField_PubDescSeg5], [DescFlexField_PubDescSeg49], [DescFlexField_PubDescSeg48], [DescFlexField_PubDescSeg47], [DescFlexField_PubDescSeg46], [DescFlexField_PubDescSeg45], 
	[DescFlexField_PubDescSeg44], [DescFlexField_PubDescSeg43], [DescFlexField_PubDescSeg42], [DescFlexField_PubDescSeg41], [DescFlexField_PubDescSeg40], [DescFlexField_PubDescSeg4], [DescFlexField_PubDescSeg39], [DescFlexField_PubDescSeg38], [DescFlexField_PubDescSeg37], [DescFlexField_PubDescSeg36], 
	[DescFlexField_PubDescSeg35], [DescFlexField_PubDescSeg34], [DescFlexField_PubDescSeg33], [DescFlexField_PubDescSeg32], [DescFlexField_PubDescSeg31], [DescFlexField_PubDescSeg30], [DescFlexField_PubDescSeg3], [DescFlexField_PubDescSeg29], [DescFlexField_PubDescSeg28], [DescFlexField_PubDescSeg27], 
	[DescFlexField_PubDescSeg26], [DescFlexField_PubDescSeg25], [DescFlexField_PubDescSeg24], [DescFlexField_PubDescSeg23], [DescFlexField_PubDescSeg22], [DescFlexField_PubDescSeg21], [DescFlexField_PubDescSeg20], [DescFlexField_PubDescSeg2], [DescFlexField_PubDescSeg19], [DescFlexField_PubDescSeg18], [DescFlexField_PubDescSeg17], [DescFlexField_PubDescSeg16], [DescFlexField_PubDescSeg15], [DescFlexField_PubDescSeg14], [DescFlexField_PubDescSeg13], [DescFlexField_PubDescSeg12], [DescFlexField_PubDescSeg11], [DescFlexField_PubDescSeg10], [DescFlexField_PubDescSeg1], [DescFlexField_PrivateDescSeg9], [DescFlexField_PrivateDescSeg8], [DescFlexField_PrivateDescSeg7], [DescFlexField_PrivateDescSeg6], [DescFlexField_PrivateDescSeg5], [DescFlexField_PrivateDescSeg4], [DescFlexField_PrivateDescSeg30], [DescFlexField_PrivateDescSeg3], [DescFlexField_PrivateDescSeg29], [DescFlexField_PrivateDescSeg28], [DescFlexField_PrivateDescSeg27], [DescFlexField_PrivateDescSeg26], [DescFlexField_PrivateDescSeg25], [DescFlexField_PrivateDescSeg24], [DescFlexField_PrivateDescSeg23], [DescFlexField_PrivateDescSeg22], [DescFlexField_PrivateDescSeg21], [DescFlexField_PrivateDescSeg20], [DescFlexField_PrivateDescSeg2], [DescFlexField_PrivateDescSeg19], [DescFlexField_PrivateDescSeg18], [DescFlexField_PrivateDescSeg17], [DescFlexField_PrivateDescSeg16], [DescFlexField_PrivateDescSeg15], [DescFlexField_PrivateDescSeg14], [DescFlexField_PrivateDescSeg13], [DescFlexField_PrivateDescSeg12], [DescFlexField_PrivateDescSeg11], [DescFlexField_PrivateDescSeg10], [DescFlexField_PrivateDescSeg1], [DescFlexField_ContextValue]
	,[CreatedOn], [CreatedBy], [CancelApprovedOn], [CancelApprovedBy], [Cancel_CancelUser], [Cancel_CancelReason], [Cancel_Canceled], [Cancel_CancelDate], [BusinessDate], [ApprovedOn], [ApprovedBy], [ActionType] from @tvp_PM_POModify',N'@tvp_PM_POModify [tvp_PM_POModify] READONLY',@tvp_PM_POModify=@p3
EXEC sp_Executesql N'INSERT INTO dbo.PM_POModify_Trl
	        ( ID ,SysMLFlag ,DescFlexField_CombineName ,Demo)SELECT ID ,SysMLFlag ,DescFlexField_CombineName ,Demo from @tvp_PM_POModify_Trl',N'@tvp_PM_POModify_Trl [tvp_PM_POModify_Trl] READONLY',@tvp_PM_POModify_Trl=@p31
	exec sp_executesql N'INSERT INTO PM_POShiplineModify ( [Wh], [WeightUOM], [Weight], [VoucherType], [VoucherID], [VoucherCode], [VolumeUOM], [Volume], [TUToTBURateB], [TUToTBURate], [TradeUOMB], [TradeUOM], [TradeBaseUOMB], [TradeBaseUOM], [TotalTaxTC], [TotalTaxFC], [TotalTaxAC], [TotalRtnFillQtyTU], [TotalRtnFillQtyTBU], [TotalRtnFillQtySU], [TotalRtnFillQtyPU], [TotalRtnFillQtyCU], [TotalRtnDeductQtyTU], [TotalRtnDeductQtyTBU], [TotalRtnDeductQtySU], [TotalRtnDeductQtyPU], [TotalRtnDeductQtyCU], [TotalRefilledQtyTU], [TotalRefilledQtyTBU], [TotalRefilledQtySU], [TotalRefilledQtyPU], [TotalRefilledQtyCU], [TotalRecievedQtyTU], [TotalRecievedQtyTBU], [TotalRecievedQtySU], [TotalRecievedQtyPU], [TotalRecievedQtyCU], [TotalPrePayedQtyTU], [TotalPrePayedQtyTBU], [TotalPrePayedQtySU], [TotalPrePayedQtyPU], [TotalPrePayedQtyCU], [TotalPrePayedMnyTC], [TotalPrePayedMnyFC], [TotalPrePayedMnyAC], [TotalPayedQtyTU], [TotalPayedQtyTBU], [TotalPayedQtySU], [TotalPayedQtyPU], [TotalPayedQtyCU], [TotalPayedMnyTC], [TotalPayedMnyFC], [TotalPayedMnyAC], [TotalMnyTC], [TotalMnyFC], [TotalMnyAC], [TotalMatchedTaxMnyTC], [TotalMatchedTaxMnyFC], [TotalMatchedTaxMnyAC], [TotalMatchedQtyTU], [TotalMatchedQtyTBU], [TotalMatchedQtySU], [TotalMatchedQtyPU], [TotalMatchedQtyCU], [TotalMatchedNetMnyTC], [TotalMatchedNetMnyFC], [TotalMatchedNetMnyAC], [TotalMatchedMnyTC], [TotalMatchedMnyFC], [TotalMatchedMnyAC], [TotalFeeTC], [TotalFeeFC], [TotalFeeAC], [TotalConfirmedTaxMnyTC], [TotalConfirmedTaxMnyFC], [TotalConfirmedTaxMnyAC], [TotalConfirmedQtyTU], [TotalConfirmedQtyTBU], [TotalConfirmedQtySU], [TotalConfirmedQtyPU], [TotalConfirmedQtyCU], [TotalConfirmedNetMnyTC], [TotalConfirmedNetMnyFC], [TotalConfirmedNetMnyAC], [TotalConfirmedMnyTC], [TotalConfirmedMnyFC], [TotalConfirmedMnyAC], [TotalArriveQtyTU], [TotalArriveQtyTBU], [TotalArriveQtySU], [TotalArriveQtyPU], [TotalArriveQtyCU], [TBUToPBURate], [TBUToCBURate], [TaskOutput_EntityType], [TaskOutput_EntityID], [TaskDate], [Task], [SysVersion], [SupplierLot], [SupplierConfirmQtyTU], [SupplierConfirmQtyTBU], [SupplierConfirmQtySU], [SupplierConfirmQtyPU], [SupplierConfirmQtyCU], [SuppierItemCode], [SubLineNo], [StoreUOM], [Status], [StateMachineID], [SrcPOShipLineNo], [SrcPOShipLine], [SrcPOLineNo], [SrcPOLine], [SrcPODocNo], [SrcPO], [SrcID], [SrcDocVersion], [SrcDocType], [SrcDocPROrg], [SrcDocPRLineNo], [SrcDocPRLine], [SrcDocPRDocNo], [SrcDocPR], [SrcDocInfo_SrcDocVer], [SrcDocInfo_SrcDocTransType_EntityType], [SrcDocInfo_SrcDocTransType_EntityID], [SrcDocInfo_SrcDocSubLineNoStr], [SrcDocInfo_SrcDocSubLineNo], [SrcDocInfo_SrcDocSubLine_EntityType], [SrcDocInfo_SrcDocSubLine_EntityID], [SrcDocInfo_SrcDocOrg], [SrcDocInfo_SrcDocNo], [SrcDocInfo_SrcDocLineNo], [SrcDocInfo_SrcDocLine_EntityType], [SrcDocInfo_SrcDocLine_EntityID], [SrcDocInfo_SrcDocDate], [SrcDocInfo_SrcDocBusiType], [SrcDocInfo_SrcDoc_EntityType], [SrcDocInfo_SrcDoc_EntityID], [SrcDocCentralizePOShipLine], [SrcDocCentralizePOOrg], [SrcDocCentralizePOLine], [SrcDocCentralizePO], [SrcCooperateType], [SrcCooperateShipLine], [SrcCooperateOrg], [SrcBudgetOrg], [SrcBudgetLine], [SrcBudgetDocType], [SplitedOutQtyTU], [SplitedOutQtyTBU], [SplitedOutQtyPU], [SplitBeforeQty], [SnCode], [ShiptoSite_SupplierSite], [ShiptoSite_Code], [ShipToCustomSize_CustomerSite], [ShipToCustomSize_Code], [ShipperOrg], [SeiBanCode], [SeiBan], [RUToRBURateB], [RUToRBURate], [RoutingNo], [Routing_EntityType], [Routing_EntityID], [RFQVer], [RFQLineKey_EntityType], [RFQLineKey_EntityID], [RFQKey_EntityType], [RFQKey_EntityID], [RFQID], [ResrvQtySU], [ResrvExecQtySU], [ResrvConsumeQtySU], [ReservedRcvQtyTU], [ReservedRcvQtyTBU], [ReservedQtyTU], [ReservedQtyTBU], [ReqUOMB], [ReqUOM], [RequireOrg], [RequireMan], [RequireDept], [ReqQtyTU], [ReqQtyTBU], [ReqQtyRU], [ReqQtyRBU], [ReqQtyPU], [ReqQtyCU], [ReqBaseUOMB], [ReqBaseUOM], [ReleaseUser], [ReleaseReason], [ReleaseDate], [RejectedQtyTU], [RejectedQtyTBU], [RejectedQtySU], [RejectedQtyPU], [RejectedQtyCU], [RcvShipBy], [RcvOrg], [RCVEstimateTaxAmountAC], [RCVEstimateAmountExcTaxAC], [PUToPBURate], [PromptInfo], [Project], [ProduceLineNo], [ProduceLineDate], [ProduceLine_EntityType], [ProduceLine_EntityID], [ProcessUOMToProcessUOMBRate], [ProcessUOMB], [ProcessUOM], [ProcessRejectQty], [ProcessReFillQty], [ProcessReDeductQty], [ProcessRcvQty], [ProcessQty], [ProcessDeficiencyQty], [PriceUOM], [PriceBaseUOM], [PreOperationSupplier], [PreOperationNo], [PreOperation_EntityType], [PreOperation_EntityID], [PreMaturityDate], [POModify], [PlanedQtyTU], [PlanedQtyTBU], [PlanedQtySU], [PlanedQtyPU], [PlanedQtyCU], [PlanArriveQtyTU], [PlanArriveQtyTBU], [PlanArriveQtySU], [PlanArriveQtyPU], [PlanArriveQtyCU], [PlanArriveDate], [Piece], [PerProcessQty], [PCNo], [PCLineNo], [PCLine_EntityType], [PCLine_EntityID], [PC_EntityType], [PC_EntityID], [ParentLineNo], [ParentLine], [ParentKITLineNO], [OperationNo_EntityType], [OperationNo_EntityID], [NotModifyAttributes], [NonLCQtyTU],  [NonLCQtyPU], [NonLCQtyCU], [NonLCMnyTC], [NonLCMnyFC], [NonLCMnyAC], [NextOperationSupplier], [NextOperationNo], [NextOperation_EntityType], [NextOperation_EntityID], [NewPOLine], [NewDocLineNo], [NetMnyTC], [NetMnyFC], [NetMnyAC], [NetFeeTC], [NetFeeFC], [NetFeeAC], [NeedPODate], [MRPRequireDate], [MOKey_EntityType], [MOKey_EntityID], [ModifiedOn], [ModifiedBy], [MO], [MnyBudgetProject], [Mfc], [MatchedQtyToRcvMnyTC], [MatchedQtyToRcvMnyFC], [MatchedQtyToRcvMnyAC], [LotInvalidation], [LCQtyTU],  [LCQtyPU], [LCQtyCU], [LCMnyTC], [LCMnyFC], [LCMnyAC], [ItemLotCode], [ItemLot_LotValidDate], [ItemLot_LotMaster], [ItemLot_LotCode], [ItemLot_DisabledDatetime], [ItemInfo_ItemVersion], [ItemInfo_ItemPotency], [ItemInfo_ItemOpt9], [ItemInfo_ItemOpt8], [ItemInfo_ItemOpt7], [ItemInfo_ItemOpt6], [ItemInfo_ItemOpt5], [ItemInfo_ItemOpt4], [ItemInfo_ItemOpt3], [ItemInfo_ItemOpt2], [ItemInfo_ItemOpt10], [ItemInfo_ItemOpt1], [ItemInfo_ItemName], [ItemInfo_ItemID], [ItemInfo_ItemGrade], [ItemInfo_ItemCode], [IsTUCanChange], [IsTransferedToGL], [IsSUCanChange], [IsSplited], [IsSeiBanEditable], [IsRFQDiscount], [IsRelationCompany], [IsPUCanChange], [IsFirm], [IsFIClose], [IsCUCanChange], [InitRtnFillQtyTU], [InitRtnFillQtyTBU], [InitRtnDeductQtyTU], [InitRtnDeductQtyTBU], [InitRecievedQtyTU], [InitRecievedQtyTBU], [InitPrePayedQtyPU], [InitPrePayedMnyTC], [InitPayedQtyPU], [InitPayedMnyTC], [InitMatchedTaxTC], [InitMatchedQtyPU], [InitMatchedNetMnyTC], [InitMatchedMnyTC], [InitConfirmedTaxMnyTC], [InitConfirmedQtyPU], [InitConfirmedNetMnyTC], [InitConfirmedMnyTC], [ID], [HoldUser], [HoldReason], [HoldDate], [HasCreateBudgetData], [FIAccountPeriod], [FeeTaxTC], [FeeTaxFC], [FeeTaxAC], [EstimatePriceMnyTC], [EstimatePriceMnyFC], [EstimatePriceMnyAC], [EstimatePriceACPU], [EstimatePriceACCU], [DIID], [DescFlexSegments_PubDescSeg9], [DescFlexSegments_PubDescSeg8], [DescFlexSegments_PubDescSeg7], [DescFlexSegments_PubDescSeg6], [DescFlexSegments_PubDescSeg50], [DescFlexSegments_PubDescSeg5], [DescFlexSegments_PubDescSeg49], [DescFlexSegments_PubDescSeg48], [DescFlexSegments_PubDescSeg47], [DescFlexSegments_PubDescSeg46], [DescFlexSegments_PubDescSeg45], [DescFlexSegments_PubDescSeg44], [DescFlexSegments_PubDescSeg43], [DescFlexSegments_PubDescSeg42], [DescFlexSegments_PubDescSeg41], [DescFlexSegments_PubDescSeg40], [DescFlexSegments_PubDescSeg4], [DescFlexSegments_PubDescSeg39], [DescFlexSegments_PubDescSeg38], [DescFlexSegments_PubDescSeg37], [DescFlexSegments_PubDescSeg36], [DescFlexSegments_PubDescSeg35], [DescFlexSegments_PubDescSeg34], [DescFlexSegments_PubDescSeg33], [DescFlexSegments_PubDescSeg32], [DescFlexSegments_PubDescSeg31], [DescFlexSegments_PubDescSeg30], [DescFlexSegments_PubDescSeg3], [DescFlexSegments_PubDescSeg29], [DescFlexSegments_PubDescSeg28], [DescFlexSegments_PubDescSeg27], [DescFlexSegments_PubDescSeg26], [DescFlexSegments_PubDescSeg25], [DescFlexSegments_PubDescSeg24], [DescFlexSegments_PubDescSeg23], [DescFlexSegments_PubDescSeg22], [DescFlexSegments_PubDescSeg21], [DescFlexSegments_PubDescSeg20], [DescFlexSegments_PubDescSeg2], [DescFlexSegments_PubDescSeg19], [DescFlexSegments_PubDescSeg18], [DescFlexSegments_PubDescSeg17], [DescFlexSegments_PubDescSeg16], [DescFlexSegments_PubDescSeg15], [DescFlexSegments_PubDescSeg14], [DescFlexSegments_PubDescSeg13], [DescFlexSegments_PubDescSeg12], [DescFlexSegments_PubDescSeg11], [DescFlexSegments_PubDescSeg10], [DescFlexSegments_PubDescSeg1], [DescFlexSegments_PrivateDescSeg9], [DescFlexSegments_PrivateDescSeg8], [DescFlexSegments_PrivateDescSeg7], [DescFlexSegments_PrivateDescSeg6], [DescFlexSegments_PrivateDescSeg5], [DescFlexSegments_PrivateDescSeg4], [DescFlexSegments_PrivateDescSeg30], [DescFlexSegments_PrivateDescSeg3], [DescFlexSegments_PrivateDescSeg29], [DescFlexSegments_PrivateDescSeg28], [DescFlexSegments_PrivateDescSeg27], [DescFlexSegments_PrivateDescSeg26], [DescFlexSegments_PrivateDescSeg25], [DescFlexSegments_PrivateDescSeg24], [DescFlexSegments_PrivateDescSeg23], [DescFlexSegments_PrivateDescSeg22], [DescFlexSegments_PrivateDescSeg21], [DescFlexSegments_PrivateDescSeg20], [DescFlexSegments_PrivateDescSeg2], [DescFlexSegments_PrivateDescSeg19], [DescFlexSegments_PrivateDescSeg18], [DescFlexSegments_PrivateDescSeg17], [DescFlexSegments_PrivateDescSeg16], [DescFlexSegments_PrivateDescSeg15], [DescFlexSegments_PrivateDescSeg14], [DescFlexSegments_PrivateDescSeg13], [DescFlexSegments_PrivateDescSeg12], [DescFlexSegments_PrivateDescSeg11], [DescFlexSegments_PrivateDescSeg10], [DescFlexSegments_PrivateDescSeg1], [DescFlexSegments_ContextValue], [DemondCode], [DeliveryDate], [DeliverCheckQtyTU], [DeliverCheckQtyTBU], [DeliverCheckQtySU], [DeliverCheckQtyPU], [DeliverCheckQtyCU], [DeficiencyQtyTU], [DeficiencyQtyTBU], [DeficiencyQtySU], [DeficiencyQtyPU], [DeficiencyQtyCU], [CUToCBURate], [CurrentOrg], [CurOperationNo], [CreatedOn], [CreatedBy], [CostUOM], [CostPercent], [CostBaseUOM], [CooperateSO], [CooperateOrg], [Container], [CentralizedPurType], [CancelApprovedOn], [CancelApprovedBy], [Cancel_CancelUser], [Cancel_CancelReason], [Cancel_Canceled], [Cancel_CancelDate], [BudgetReplaceClue], [BomLineNo], [BizClosedOn], [BizBudgetProject], [Billsetcode], [BalanceRouteCode], [ApprovedOn], [ApprovedBy], [ActiveType], [ActionType] ) select [Wh], [WeightUOM], [Weight], [VoucherType], [VoucherID], [VoucherCode], [VolumeUOM], [Volume], [TUToTBURateB], [TUToTBURate], [TradeUOMB], [TradeUOM], [TradeBaseUOMB], [TradeBaseUOM], [TotalTaxTC], [TotalTaxFC], [TotalTaxAC], [TotalRtnFillQtyTU], [TotalRtnFillQtyTBU], [TotalRtnFillQtySU], [TotalRtnFillQtyPU], [TotalRtnFillQtyCU], [TotalRtnDeductQtyTU], [TotalRtnDeductQtyTBU], [TotalRtnDeductQtySU], [TotalRtnDeductQtyPU], [TotalRtnDeductQtyCU], [TotalRefilledQtyTU], [TotalRefilledQtyTBU], [TotalRefilledQtySU], [TotalRefilledQtyPU], [TotalRefilledQtyCU], [TotalRecievedQtyTU], [TotalRecievedQtyTBU], [TotalRecievedQtySU], [TotalRecievedQtyPU], [TotalRecievedQtyCU], [TotalPrePayedQtyTU], [TotalPrePayedQtyTBU], [TotalPrePayedQtySU], [TotalPrePayedQtyPU], [TotalPrePayedQtyCU], [TotalPrePayedMnyTC], [TotalPrePayedMnyFC], [TotalPrePayedMnyAC], [TotalPayedQtyTU], [TotalPayedQtyTBU], [TotalPayedQtySU], [TotalPayedQtyPU], [TotalPayedQtyCU], [TotalPayedMnyTC], [TotalPayedMnyFC], [TotalPayedMnyAC], [TotalMnyTC], [TotalMnyFC], [TotalMnyAC], [TotalMatchedTaxMnyTC], [TotalMatchedTaxMnyFC], [TotalMatchedTaxMnyAC], [TotalMatchedQtyTU], [TotalMatchedQtyTBU], [TotalMatchedQtySU], [TotalMatchedQtyPU], [TotalMatchedQtyCU], [TotalMatchedNetMnyTC], [TotalMatchedNetMnyFC], [TotalMatchedNetMnyAC], [TotalMatchedMnyTC], [TotalMatchedMnyFC], [TotalMatchedMnyAC], [TotalFeeTC], [TotalFeeFC], [TotalFeeAC], [TotalConfirmedTaxMnyTC], [TotalConfirmedTaxMnyFC], [TotalConfirmedTaxMnyAC], [TotalConfirmedQtyTU], [TotalConfirmedQtyTBU], [TotalConfirmedQtySU], [TotalConfirmedQtyPU], [TotalConfirmedQtyCU], [TotalConfirmedNetMnyTC], [TotalConfirmedNetMnyFC], [TotalConfirmedNetMnyAC], [TotalConfirmedMnyTC], [TotalConfirmedMnyFC], [TotalConfirmedMnyAC], [TotalArriveQtyTU], [TotalArriveQtyTBU], [TotalArriveQtySU], [TotalArriveQtyPU], [TotalArriveQtyCU], [TBUToPBURate], [TBUToCBURate], [TaskOutput_EntityType], [TaskOutput_EntityID], [TaskDate], [Task], [SysVersion], [SupplierLot], [SupplierConfirmQtyTU], [SupplierConfirmQtyTBU], [SupplierConfirmQtySU], [SupplierConfirmQtyPU], [SupplierConfirmQtyCU], [SuppierItemCode], [SubLineNo], [StoreUOM], [Status], [StateMachineID], [SrcPOShipLineNo], [SrcPOShipLine], [SrcPOLineNo], [SrcPOLine], [SrcPODocNo], [SrcPO], [SrcID], [SrcDocVersion], [SrcDocType], [SrcDocPROrg], [SrcDocPRLineNo], [SrcDocPRLine], [SrcDocPRDocNo], [SrcDocPR], [SrcDocInfo_SrcDocVer], [SrcDocInfo_SrcDocTransType_EntityType], [SrcDocInfo_SrcDocTransType_EntityID], [SrcDocInfo_SrcDocSubLineNoStr], [SrcDocInfo_SrcDocSubLineNo], [SrcDocInfo_SrcDocSubLine_EntityType], [SrcDocInfo_SrcDocSubLine_EntityID], 
			[SrcDocInfo_SrcDocOrg], [SrcDocInfo_SrcDocNo], [SrcDocInfo_SrcDocLineNo], [SrcDocInfo_SrcDocLine_EntityType], [SrcDocInfo_SrcDocLine_EntityID], [SrcDocInfo_SrcDocDate], [SrcDocInfo_SrcDocBusiType], [SrcDocInfo_SrcDoc_EntityType], [SrcDocInfo_SrcDoc_EntityID], [SrcDocCentralizePOShipLine], 
			[SrcDocCentralizePOOrg], [SrcDocCentralizePOLine], [SrcDocCentralizePO], [SrcCooperateType], [SrcCooperateShipLine], [SrcCooperateOrg], [SrcBudgetOrg], [SrcBudgetLine], [SrcBudgetDocType], [SplitedOutQtyTU], [SplitedOutQtyTBU], [SplitedOutQtyPU], [SplitBeforeQty], [SnCode], [ShiptoSite_SupplierSite], 
			[ShiptoSite_Code], [ShipToCustomSize_CustomerSite], [ShipToCustomSize_Code], [ShipperOrg], [SeiBanCode], [SeiBan], [RUToRBURateB], [RUToRBURate], [RoutingNo], [Routing_EntityType], [Routing_EntityID], [RFQVer], [RFQLineKey_EntityType], [RFQLineKey_EntityID], [RFQKey_EntityType], [RFQKey_EntityID], [RFQID], 
			[ResrvQtySU], [ResrvExecQtySU], [ResrvConsumeQtySU], [ReservedRcvQtyTU], [ReservedRcvQtyTBU], [ReservedQtyTU], [ReservedQtyTBU], [ReqUOMB], [ReqUOM], [RequireOrg], [RequireMan], [RequireDept], [ReqQtyTU], [ReqQtyTBU], [ReqQtyRU], [ReqQtyRBU], [ReqQtyPU], [ReqQtyCU], [ReqBaseUOMB], [ReqBaseUOM], 
			[ReleaseUser], [ReleaseReason], [ReleaseDate], [RejectedQtyTU], [RejectedQtyTBU], [RejectedQtySU], [RejectedQtyPU], [RejectedQtyCU], [RcvShipBy], [RcvOrg], [RCVEstimateTaxAmountAC], [RCVEstimateAmountExcTaxAC], [PUToPBURate], [PromptInfo], [Project], [ProduceLineNo], [ProduceLineDate], 
			[ProduceLine_EntityType], [ProduceLine_EntityID], [ProcessUOMToProcessUOMBRate], [ProcessUOMB], [ProcessUOM], [ProcessRejectQty], [ProcessReFillQty], [ProcessReDeductQty], [ProcessRcvQty], [ProcessQty], [ProcessDeficiencyQty], [PriceUOM], [PriceBaseUOM], [PreOperationSupplier], [PreOperationNo], 
			[PreOperation_EntityType], [PreOperation_EntityID], [PreMaturityDate], [POModify], [PlanedQtyTU], [PlanedQtyTBU], [PlanedQtySU], [PlanedQtyPU], [PlanedQtyCU], [PlanArriveQtyTU], [PlanArriveQtyTBU], [PlanArriveQtySU], [PlanArriveQtyPU], [PlanArriveQtyCU], [PlanArriveDate], [Piece], [PerProcessQty], [PCNo], [PCLineNo], [PCLine_EntityType], [PCLine_EntityID], [PC_EntityType], [PC_EntityID], [ParentLineNo], [ParentLine], [ParentKITLineNO], [OperationNo_EntityType], [OperationNo_EntityID], [NotModifyAttributes], [NonLCQtyTU],  [NonLCQtyPU], [NonLCQtyCU], [NonLCMnyTC], [NonLCMnyFC], [NonLCMnyAC], [NextOperationSupplier], [NextOperationNo], [NextOperation_EntityType], [NextOperation_EntityID], [NewPOLine], [NewDocLineNo], [NetMnyTC], [NetMnyFC], [NetMnyAC], [NetFeeTC], [NetFeeFC], [NetFeeAC], [NeedPODate], [MRPRequireDate], [MOKey_EntityType], [MOKey_EntityID], [ModifiedOn], [ModifiedBy], [MO], [MnyBudgetProject], [Mfc], [MatchedQtyToRcvMnyTC], [MatchedQtyToRcvMnyFC], [MatchedQtyToRcvMnyAC], [LotInvalidation], [LCQtyTU],  [LCQtyPU], [LCQtyCU], [LCMnyTC], [LCMnyFC], [LCMnyAC], [ItemLotCode], [ItemLot_LotValidDate], [ItemLot_LotMaster], [ItemLot_LotCode], [ItemLot_DisabledDatetime], [ItemInfo_ItemVersion], [ItemInfo_ItemPotency], [ItemInfo_ItemOpt9], [ItemInfo_ItemOpt8], [ItemInfo_ItemOpt7], [ItemInfo_ItemOpt6], [ItemInfo_ItemOpt5], [ItemInfo_ItemOpt4], [ItemInfo_ItemOpt3], [ItemInfo_ItemOpt2], [ItemInfo_ItemOpt10], [ItemInfo_ItemOpt1], [ItemInfo_ItemName], [ItemInfo_ItemID], [ItemInfo_ItemGrade], [ItemInfo_ItemCode], [IsTUCanChange], [IsTransferedToGL], [IsSUCanChange], [IsSplited], [IsSeiBanEditable], [IsRFQDiscount], [IsRelationCompany], [IsPUCanChange], [IsFirm], [IsFIClose], [IsCUCanChange], [InitRtnFillQtyTU], [InitRtnFillQtyTBU], [InitRtnDeductQtyTU], [InitRtnDeductQtyTBU], [InitRecievedQtyTU], [InitRecievedQtyTBU], [InitPrePayedQtyPU], [InitPrePayedMnyTC], [InitPayedQtyPU], [InitPayedMnyTC], [InitMatchedTaxTC], [InitMatchedQtyPU], [InitMatchedNetMnyTC], [InitMatchedMnyTC], [InitConfirmedTaxMnyTC], [InitConfirmedQtyPU], [InitConfirmedNetMnyTC], [InitConfirmedMnyTC], [ID], [HoldUser], [HoldReason], [HoldDate], [HasCreateBudgetData], [FIAccountPeriod], [FeeTaxTC], [FeeTaxFC], [FeeTaxAC], [EstimatePriceMnyTC], [EstimatePriceMnyFC], [EstimatePriceMnyAC], [EstimatePriceACPU], [EstimatePriceACCU], [DIID], [DescFlexSegments_PubDescSeg9], 
			[DescFlexSegments_PubDescSeg8], [DescFlexSegments_PubDescSeg7], [DescFlexSegments_PubDescSeg6], [DescFlexSegments_PubDescSeg50], [DescFlexSegments_PubDescSeg5], [DescFlexSegments_PubDescSeg49], [DescFlexSegments_PubDescSeg48], [DescFlexSegments_PubDescSeg47], [DescFlexSegments_PubDescSeg46], 
			[DescFlexSegments_PubDescSeg45], [DescFlexSegments_PubDescSeg44], [DescFlexSegments_PubDescSeg43], [DescFlexSegments_PubDescSeg42], [DescFlexSegments_PubDescSeg41], [DescFlexSegments_PubDescSeg40], [DescFlexSegments_PubDescSeg4], [DescFlexSegments_PubDescSeg39], [DescFlexSegments_PubDescSeg38], 
			[DescFlexSegments_PubDescSeg37], [DescFlexSegments_PubDescSeg36], [DescFlexSegments_PubDescSeg35], [DescFlexSegments_PubDescSeg34], [DescFlexSegments_PubDescSeg33], [DescFlexSegments_PubDescSeg32], [DescFlexSegments_PubDescSeg31], [DescFlexSegments_PubDescSeg30], [DescFlexSegments_PubDescSeg3], 
			[DescFlexSegments_PubDescSeg29], [DescFlexSegments_PubDescSeg28], [DescFlexSegments_PubDescSeg27], [DescFlexSegments_PubDescSeg26], [DescFlexSegments_PubDescSeg25], [DescFlexSegments_PubDescSeg24], [DescFlexSegments_PubDescSeg23], [DescFlexSegments_PubDescSeg22], [DescFlexSegments_PubDescSeg21], 
			[DescFlexSegments_PubDescSeg20], [DescFlexSegments_PubDescSeg2], [DescFlexSegments_PubDescSeg19], [DescFlexSegments_PubDescSeg18], [DescFlexSegments_PubDescSeg17], [DescFlexSegments_PubDescSeg16], [DescFlexSegments_PubDescSeg15], [DescFlexSegments_PubDescSeg14], [DescFlexSegments_PubDescSeg13], 
			[DescFlexSegments_PubDescSeg12], [DescFlexSegments_PubDescSeg11], [DescFlexSegments_PubDescSeg10], [DescFlexSegments_PubDescSeg1], [DescFlexSegments_PrivateDescSeg9], [DescFlexSegments_PrivateDescSeg8], [DescFlexSegments_PrivateDescSeg7], [DescFlexSegments_PrivateDescSeg6], 
			[DescFlexSegments_PrivateDescSeg5], [DescFlexSegments_PrivateDescSeg4], [DescFlexSegments_PrivateDescSeg30], [DescFlexSegments_PrivateDescSeg3], [DescFlexSegments_PrivateDescSeg29], [DescFlexSegments_PrivateDescSeg28], [DescFlexSegments_PrivateDescSeg27], [DescFlexSegments_PrivateDescSeg26], [DescFlexSegments_PrivateDescSeg25], [DescFlexSegments_PrivateDescSeg24], [DescFlexSegments_PrivateDescSeg23], [DescFlexSegments_PrivateDescSeg22], [DescFlexSegments_PrivateDescSeg21], [DescFlexSegments_PrivateDescSeg20], [DescFlexSegments_PrivateDescSeg2], [DescFlexSegments_PrivateDescSeg19], [DescFlexSegments_PrivateDescSeg18], [DescFlexSegments_PrivateDescSeg17], [DescFlexSegments_PrivateDescSeg16], [DescFlexSegments_PrivateDescSeg15], [DescFlexSegments_PrivateDescSeg14], [DescFlexSegments_PrivateDescSeg13], [DescFlexSegments_PrivateDescSeg12], [DescFlexSegments_PrivateDescSeg11], [DescFlexSegments_PrivateDescSeg10], [DescFlexSegments_PrivateDescSeg1], [DescFlexSegments_ContextValue], [DemondCode], [DeliveryDate], [DeliverCheckQtyTU], [DeliverCheckQtyTBU], [DeliverCheckQtySU], [DeliverCheckQtyPU], [DeliverCheckQtyCU], [DeficiencyQtyTU], [DeficiencyQtyTBU], [DeficiencyQtySU], [DeficiencyQtyPU], [DeficiencyQtyCU], [CUToCBURate], [CurrentOrg], [CurOperationNo], [CreatedOn], [CreatedBy], [CostUOM], [CostPercent], [CostBaseUOM], [CooperateSO], [CooperateOrg], [Container], [CentralizedPurType], [CancelApprovedOn], [CancelApprovedBy], [Cancel_CancelUser], [Cancel_CancelReason], [Cancel_Canceled], [Cancel_CancelDate], [BudgetReplaceClue], [BomLineNo], [BizClosedOn], [BizBudgetProject], [Billsetcode], [BalanceRouteCode], [ApprovedOn], [ApprovedBy], [ActiveType], [ActionType] from @tvp_PM_POShiplineModify',N'@tvp_PM_POShiplineModify [tvp_PM_POShiplineModify] READONLY',@tvp_PM_POShiplineModify=@p4

			exec sp_executesql N'INSERT INTO PM_POShiplineModify_trl ( a.[SysMLFlag], a.[SrcDocInfo_SrcDocTransTypeName], a.[ShiptoSite_Name], a.[ShipToCustomSize_Name], a.[RequireOrgItemName], a.[ID], a.[DescFlexSegments_CombineName] ) select a.[SysMLFlag], a.[SrcDocInfo_SrcDocTransTypeName], a.[ShiptoSite_Name], a.[ShipToCustomSize_Name], a.[RequireOrgItemName], a.[ID], a.[DescFlexSegments_CombineName] from @tvp_PM_POShiplineModify_trl a',N'@tvp_PM_POShiplineModify_trl [tvp_PM_POShiplineModify_trl] READONLY',@tvp_PM_POShiplineModify_trl=@p5

			EXEC sp_executesql N'INSERT INTO PM_POModifyLine ( [SysVersion], [POShipLineID], [POShipLineDocLineNo], [POModify], [POLineID], [POLineDocLineNo], [NameBeforeModifeid], [NameAfterModifeid], [ModifiedOn], [ModifiedEntityName], [ModifiedEntity_EntityType], [ModifiedEntity_EntityID], [ModifiedDataType], [ModifiedDataName], [ModifiedData], [ModifiedBy], [LineID], [ItemInfo], [ID], [DocLineNo], [DataBeforeModified], [DataAfterModified], [CreatedOn], [CreatedBy], [CodeBeforeModified], [CodeAfterModified], [ChangeType] ) select [SysVersion], [POShipLineID], [POShipLineDocLineNo], [POModify], [POLineID], [POLineDocLineNo], [NameBeforeModifeid], [NameAfterModifeid], [ModifiedOn], [ModifiedEntityName], [ModifiedEntity_EntityType], [ModifiedEntity_EntityID], [ModifiedDataType], [ModifiedDataName], [ModifiedData], [ModifiedBy], [LineID], [ItemInfo], [ID], [DocLineNo], [DataBeforeModified], [DataAfterModified], [CreatedOn], [CreatedBy], [CodeBeforeModified], [CodeAfterModified], [ChangeType] from @tvp_PM_POModifyLine',N'@tvp_PM_POModifyLine [tvp_PM_POModifyLine] READONLY',@tvp_PM_POModifyLine=@p6			


-----------------------------------------------------------------------------------------

END 
END TRY--
BEGIN CATCH	
SET @tran_Error=@tran_Error+ISNULL(@@ERROR,0)
END CATCH
IF @tran_Error>0
BEGIN
SET @Result='创建变更单失败，数据回滚'
ROLLBACK TRAN
END 
ELSE
BEGIN  
SET @Result='1'
COMMIT TRAN 
END 
--PRINT @Result
END 

