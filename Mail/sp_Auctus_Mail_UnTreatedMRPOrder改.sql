USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_Mail_UnTreatedMRPOrder]    Script Date: 2022/9/19 16:55:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
1、抓计划订单 未转单数据
2、抓重排建议执行
3、1和2的结果集和分MRP和MPS
4、发送MPS为转单单据、MPS重排建议
5、发送MRP未转单据、MRP重排建议

ADD(2018-11-23)
1、MRP待转单只展示需求日期2个月之内的
2、重排建议 不显示仅日期变更的

ADD（2018-12-08）
1、MPS重排建议只展示8周之内的

ADD(2018-12-10)
MRP重排建议操作类型为“取消”的，0单价（即PO的赠品）数据不显示

ADD(2019-2-15)
MPS未释放单据取8周以内，暂时使用 开始时间与8周内做比较

ADD（2019-3-1）
MRP重排建议过滤
1、重排建议邮件推送按领导指示如果原始数量、重排数量差异小于等于最小包量在邮件中过滤
2、如果最小包装量是小于100的不体现在邮件推送中。
3、取消的重排建议全部放出来，不适用以上两条

ADD(2019-3-12)
1、最小包装量取料品档案的采购页签下的“采购倍量”(之前是从供应商-料品交叉档案取采购倍量)

ADD(2019-3-14)
1、MPS\MPR重排建议增加一列建议处理方式
2、MRP重排建议小于MPQ的取消行不展示
3、MRP重排建议重拍日期与原始日期差异15天之内的建议不处理，其他建议处理
ADD(2019-3-21)
MRP重排建议手工创建的PR单不展示
*/

ALTER PROC [dbo].[sp_Auctus_Mail_UnTreatedMRPOrder]
(
@Is6 BIT--是否6点推送
)
as
BEGIN 
DECLARE @html NVARCHAR(MAX)
DECLARE @htmlMC NVARCHAR(MAX)
DECLARE @html_MPS_PlanOrder NVARCHAR(MAX)
DECLARE @html_MRP_PlanOrder NVARCHAR(MAX)
DECLARE @html_MRP_MPSDetail NVARCHAR(MAX)
DECLARE @html_MPS_Reschedule NVARCHAR(MAX)
DECLARE @html_MRP_Reschedule NVARCHAR(MAX)
DECLARE @html_MRP_RescheduleMC NVARCHAR(MAX)

DECLARE @Date DATETIME 
SET @Date=DATEADD(day,56,GETDATE())



--所有计划订单
;
WITH PlanOrder AS
(
--MRP分类，料号、品名、规格、需求日期、数量、已发放量、释放量、安全库存量、开工日期
SELECT dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.ScheduleMethodEnum',c.PlanMethod,'zh-cn')PlanMethod
,b.ID PlanVersion
,h.Name MRPCategory
,a.DocNo
,a.DemandCode
,e.Code,e.Name,e.SPECS
,a.DemandDate,a.StartDate--开工日期
,a.Qty,a.ReleasedQty--已发放数量
,a.MRPQty-a.ReleasedQty ReleaseQty--MRP调整后数量-已发放数量=释放量
,f.SafetyStockQty--安全库存量
,g.FixedLT--固定提前期（天）
,d.ID IsRelease--计划订单是否释放
FROM dbo.MRP_PlanOrder a LEFT JOIN dbo.MRP_PlanVersion b ON a.SrcPlanVersion=b.ID 
LEFT JOIN dbo.MRP_PlanName c ON b.PlanName=c.ID
LEFT JOIN dbo.MRP_PlanOrderConsumption d ON a.ID=d.PlanOrder 
LEFT JOIN dbo.CBO_ItemMaster e ON a.Item=e.ID 
LEFT JOIN dbo.CBO_InventoryInfo f ON e.InventoryInfo=f.ID
LEFT JOIN dbo.CBO_MrpInfo g ON e.MrpInfo=g.ID 
LEFT JOIN dbo.vw_MRPCategory h ON e.DescFlexField_PrivateDescSeg22=h.Code AND h.MRPCategory='MRPCategory'
WHERE c.Org=(SELECT ID FROM dbo.Base_Organization WHERE Code='300')
AND e.Effective_IsEffective=1
AND a.MRPQty-a.ReleasedQty>0--释放量（余量）>0展示出来
AND a.DemandDate<= @Date
--Add By daniel    未释放量不考虑小于安全库存、安全库存小于50且不为0的计划订单
and   not exists   (select 1 from   CBO_InventoryInfo s
                     where  s.ItemMaster=a.Item 
	                      and  (a.MRPQty-a.ReleasedQty) <  s.SafetyStockQty  
                          and s.SafetyStockQty <=50 and s.SafetyStockQty !=0)

),
MRP AS--MRP计划订单未释放
(
SELECT *,ROW_NUMBER() OVER(ORDER BY a.MRPCategory,a.DemandDate)RN FROM PlanOrder a WHERE a.PlanMethod='MRP' AND a.IsRelease IS NULL 
),
MPS AS--MPS计划订单未释放
(
SELECT *,ROW_NUMBER() OVER(ORDER BY a.MRPCategory,a.DemandDate)RN FROM PlanOrder a WHERE a.PlanMethod='MPS'  AND a.IsRelease IS NULL--MPS
)
SELECT @html_MPS_PlanOrder=N'<H2 bgcolor="#7CFC00">MPS计划订单未处理列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">需求分类号</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">需求日期</th><th nowrap="nowrap">开工日期</th><th nowrap="nowrap">数量</th><th nowrap="nowrap">已发放数量</th>
<th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">固定提前期(天)</th></tr>'
+ISNULL(CAST((SELECT td=ISNULL(a.MRPCategory,''),'',td=a.DocNo,'',td=ISNULL((select Code from UBF_Sys_ExtEnumValue where  ExtEnumType=1001101157664810 AND EValue=a.DemandCode),''),'',td=a.Code,'',td=a.Name,'',td=a.SPECS,'',td=CONVERT(DATE,a.DemandDate),'',td=CONVERT(DATE,a.StartDate),'',td=CONVERT(DECIMAL(18,0),a.Qty),''
,td=CONVERT(DECIMAL(18,0),a.ReleasedQty),'',td=CONVERT(DECIMAL(18,0),a.SafetyStockQty),'',td=CONVERT(DECIMAL(18,2),a.FixedLT) 
FROM MPS a 
ORDER BY a.RN FOR XML PATH('tr') ,type)AS NVARCHAR(MAX)),'')+N'</table><br/>'
,@html_MRP_PlanOrder=N'<H2 bgcolor="#7CFC00">MRP计划订单未处理列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">需求分类号</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">需求日期</th><th nowrap="nowrap">开工日期</th><th nowrap="nowrap">数量</th><th nowrap="nowrap">已发放数量</th><th nowrap="nowrap">释放量（余量）</th>
<th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">固定提前期(天)</th></tr>'
+CAST((SELECT td=ISNULL(a.MRPCategory,''),'',td=a.DocNo,'',td=ISNULL((select Code from UBF_Sys_ExtEnumValue where  ExtEnumType=1001101157664810 AND EValue=a.DemandCode),''),'',td=a.Code,'',td=a.Name,'',td=a.SPECS,'',td=CONVERT(DATE,a.DemandDate),'',td=CONVERT(DATE,a.StartDate),'',td=CONVERT(DECIMAL(18,0),a.Qty),''
,td=CONVERT(DECIMAL(18,0),a.ReleasedQty),'',td=CONVERT(DECIMAL(18,0),a.ReleaseQty),'',td=CONVERT(DECIMAL(18,0),a.SafetyStockQty),'',td=CONVERT(DECIMAL(18,2),a.FixedLT) 
FROM MRP a  WHERE ISNULL(a.MRPCategory,'')<>'生产辅料'
ORDER BY a.RN FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))+N'</table><br/>'
--MRP分类，料号、品名、规格、需求日期、数量、已发放量、释放量、安全库存量、开工日期

	  SET @html_MRP_MPSDetail=N'<H2 bgcolor="#7CFC00">MPS未转工单列表</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">需求分类号</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">开始日期</th><th nowrap="nowrap">结束日期</th><th nowrap="nowrap">数量</th><th nowrap="nowrap">已执行数量</th>
<th nowrap="nowrap">未转工单数量</th><th nowrap="nowrap">安全库存量</th><th nowrap="nowrap">固定提前期(天)</th>
</tr>'
+CAST((SELECT td=ISNULL(e.Name,''),'',td=a.SourceDocNo,'',td=isnull((select Code from UBF_Sys_ExtEnumValue where  ExtEnumType=1001101157664810 AND EValue=a.DemandCode),''),'',td=c.Code,'',td=c.Name,'',td=c.SPECS,'',td=CONVERT(DATE,a.SupplyDate),'',td=CONVERT(DATE,a.EndSupplyDate)
,'',td=CONVERT(DECIMAL(18,0),a.TUQty)--数量
,'',td=CONVERT(DECIMAL(18,0),a.ExecQty)--已执行数量
,'',td=CONVERT(DECIMAL(18,0),a.TUQty-a.ExecQty)--未转工单数量（余量）
,'',td=CONVERT(DECIMAL(18,0),c2.SafetyStockQty)--安全库存量
,'',td=CONVERT(DECIMAL(18,2),c1.FixedLT)--固定提前期（天）
FROM dbo.MRP_MPSDetail a INNER JOIN MRP_MPS b ON a.MPS=b.ID 
LEFT JOIN cbo_itemmaster c ON b.item=c.ID LEFT JOIN dbo.CBO_MrpInfo c1 ON c.ID=c1.ItemMaster LEFT JOIN dbo.CBO_InventoryInfo c2 ON c.ID=c2.ItemMaster
	  LEFT JOIN mrp_planversion d ON b.planversion=d.id LEFT JOIN dbo.MRP_PlanName d1 ON d.PlanName=d1.ID
	  LEFT JOIN dbo.vw_MRPCategory e ON c.DescFlexField_PrivateDescSeg22=e.Code AND e.MRPCategory='MRPCategory'
	  WHERE --d.id=1001808310027273 
	  a.TUQty>a.ExecQty  AND  dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.ScheduleMethodEnum',d1.PlanMethod,'zh-cn')='MPS'
	  AND b.ModifiedOn=b.CreatedOn--MO转PO有bug导致回写数量，所以加上此条件
	  AND a.SupplyDate<@Date
	  AND d1.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')  ORDER BY e.Name,a.SupplyDate FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))+N'</table><br/>'






--重排建议
;
WITH MRPReschedule AS
(
SELECT 
c.PlanCode
,dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.ScheduleMethodEnum',c.PlanMethod,'zh-cn')PlanMethod
,d1.Name MRPCategory
,dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.ConfirmType',a.ConfirmType,'zh-cn')ConfirmType--确认状态
,dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.RescheduleACDType',a.RType,'zh-cn')RType
,a.DocNo,a.Linenum,a.PlanLineNum
,dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.SupplyTypeEnum',a.SupplyType,'zh-cn')SupplyType--供应性质
,d.Code,d.Name,d.SPECS,a.SMQty--库存主单位数量
,CONVERT(DATE,a.OriginalDate)OriginalDate--原始日期
,a.TradeBaseQty
,a.RescheduleQty,CONVERT(DATE,a.RescheduleDate)RescheduleDate
,ISNULL(pr.SourceType,0)SourceType--来源类别，4为手工创建
--,CASE WHEN a.RType IN (1,2) AND (a.SMQty-a.RescheduleQty)>0 AND (a.SMQty-a.RescheduleQty)<ISNULL(g.PurchaseBatchQty,0) THEN '1'
--ELSE '0' END IsPurchaseBatchQty--是否超过最小包装量(1：重排事件不变，取消或者更新的数量小于MPQ)
--,CASE WHEN a.RType=1 AND a.RescheduleQty>=ISNULL(g.MinOrderQty,0) THEN '1'
--WHEN a.RType=2 AND a.SMQty>=ISNULL(g.MinOrderQty,0) THEN '1'
--ELSE '0' END IsMinOrderQty
--,CASE WHEN a.RType=1 AND (a.SMQty-a.RescheduleQty)>100 AND (a.SMQty-a.RescheduleQty)>ISNULL(g.MinOrderQty,0) THEN '1'
--WHEN a.RType=2 AND a.SMQty>=ISNULL(g.MinOrderQty,0) AND a.SMQty>100 THEN '1'
--ELSE '0' END IsMinOrderQty--是否超过最小包装量(1：重排事件不变，取消或者更新的数量小于MPQ)
,CASE WHEN a.RType=1 AND (a.SMQty-a.RescheduleQty)>100 AND (a.SMQty-a.RescheduleQty)>ISNULL(g.PurchaseBatchQty,0) THEN '1'
--WHEN a.RType=2 AND a.SMQty>=ISNULL(g.MinOrderQty,0) AND a.SMQty>100 THEN '1'
WHEN a.RType=2 AND a.SMQty>=ISNULL(g.PurchaseBatchQty,0) THEN '1'
ELSE '0' END MRP_IsPurchaseBatchQty--是否超过最小包装量(1：重排事件不变，取消或者更新的数量小于MPQ)
,CONVERT(DECIMAL(18,0),ISNULL(g.PurchaseBatchQty,0))PurchaseBatchQty
FROM dbo.MRP_Reschedule a LEFT JOIN dbo.MRP_PlanVersion b ON a.PlanVersion=b.ID
LEFT JOIN dbo.MRP_PlanName c ON b.PlanName=c.ID 
LEFT JOIN dbo.CBO_ItemMaster d ON a.Item=d.ID LEFT JOIN dbo.vw_MRPCategory d1 ON d.DescFlexField_PrivateDescSeg22=d1.Code AND d1.MRPCategory='MRPCategory'
LEFT JOIN dbo.PR_PR pr ON a.DocNo=pr.DocNo
--LEFT JOIN dbo.PM_PurchaseOrder f ON a.DocNo=f.DocNo
--LEFT JOIN dbo.CBO_SupplierItem g ON f.Supplier_Supplier=g.SupplierInfo_Supplier AND a.Item=g.ItemInfo_ItemID AND g.Org=1001708020135665
LEFT  JOIN dbo.CBO_PurchaseInfo g ON d.ID=g.ItemMaster
WHERE c.Org=(SELECT ID FROM dbo.Base_Organization WHERE Code='300')
--AND a.SMQty<>a.RescheduleQty--重排建议 不显示仅日期变更的
AND a.ConfirmType<>'1'
AND d1.Code<>'MRP111'
AND d1.Code<>'MRP109'
),
PO AS
(
SELECT a.DocNo,b.DocLineNo,b.FinallyPriceFC,c.SubLineNo,b.ItemInfo_ItemCode,b.IsPresent,c.Status,s1.Name SupplierName ,c.DeliveryDate,c.PlanArriveDate,c.NeedPODate,c.SupplierConfirmQtyTU
,(SELECT t.SourceType FROM dbo.PR_PR t WHERE t.DocNo=b.SrcDocInfo_SrcDocNo) PRType
,(c.SupplierConfirmQtyTU-ISNULL((SELECT SUM(CASE WHEN t.ReceivementType=0 THEN t1.RcvQtyTU WHEN t.ReceivementType=1 THEN (-1)*t1.RejectQtyTU ELSE t1.RcvQtyTU END) FROM dbo.PM_Receivement t INNER JOIN dbo.PM_RcvLine t1 ON t.ID=t1.Receivement WHERE t1.SrcPO_SrcDocNo=a.DocNo AND t1.SrcPO_SrcDocLineNo=b.DocLineNo
AND t1.SrcPO_SrcDocSubLineNo=c.SubLineNo),0))UnRcvQty
FROM dbo.PM_PurchaseOrder a INNER JOIN pm_poline b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
LEFT JOIN CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID AND ISNULL(s1.SysMLFlag,'zh-cn')='zh-cn'
WHERE --b.IsPresent=1 AND 
a.org=(SELECT ID FROM dbo.Base_Organization WHERE Code='300')
),
MO AS
(
SELECT a.DocNo,a.DocState,a.Cancel_Canceled,a.IsHoldRelease,a.CompleteDate,(a.ProductQty-isnull((SELECT SUM(ISNULL(t.CompleteQty,0)) FROM dbo.MO_CompleteRpt t WHERE t.MO=a.ID),0))UnCompleteQty FROM dbo.MO_MO a  WHERE a.Org=(SELECT ID FROM dbo.Base_Organization WHERE Code='300')
),
PPRData AS 
(
 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
							ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode ORDER BY a2.Org DESC,a1.FromDate DESC) AS rowNum						--倒序排生效日
				FROM    PPR_PurPriceLine a1 
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
						--	a2.Org IN( @Org,1001708020135435)
						a2.Org=1001708020135665
						AND a1.FromDate <= GETDATE())
						t WHERE t.rowNum=1
 ),
MPS2 AS
(
SELECT a.*,ROW_NUMBER() OVER(ORDER BY a.RType,a.MRPCategory,a.OriginalDate)RN 
,CASE WHEN a.SupplyType='生产订单' THEN c.DocNo
WHEN a.SupplyType='采购订单' THEN b.DocNo END ActualDocNo
,CASE WHEN a.SupplyType='生产订单' AND c.Cancel_Canceled=0 THEN dbo.F_GetEnumName('UFIDA.U9.MO.Enums.MOStateEnum',c.DocState,'zh-cn')
WHEN a.SupplyType='生产订单' AND c.Cancel_Canceled=1 THEN dbo.F_GetEnumName('UFIDA.U9.MO.Enums.MOStateEnum',c.DocState,'zh-cn') +'(作废)'
WHEN a.SupplyType='采购订单' THEN dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn') END ActualStatus
,b.UnRcvQty,c.UnCompleteQty,b.PlanArriveDate,c.CompleteDate
FROM MRPReschedule a 
LEFT JOIN PO b ON a.DocNo=b.DocNo AND a.Linenum=b.DocLineNo AND a.PlanLineNum=b.SubLineNo LEFT JOIN MO c ON a.DocNo=c.DocNo
WHERE a.PlanMethod='MPS' and patindex('RMO%',a.docno)=0 and patindex('FMO%',a.docno)=0 AND a.OriginalDate<@Date--AND a.IsPurchaseBatchQty='0'
AND ISNULL(ISNULL(b.DocNo,c.DocNo),'')<>''--实际单据未删除
AND ISNULL(c.Cancel_Canceled,0)<>1
AND ISNULL(c.IsHoldRelease,0)<>1
AND ISNULL(b.Status,0) NOT IN (3,4,5)
AND ISNULL(c.DocState,0)!=3
),
MRP2 AS--数量变更MRP重排建议
(
SELECT a.*,ROW_NUMBER() OVER(ORDER BY a.MRPCategory,a.OriginalDate)RN,b.DocNo ActualDocNo,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn')ActualStatus
,b.SupplierName
,(a.SMQty-a.RescheduleQty)*CASE WHEN a.SupplyType='采购订单' THEN b.FinallyPriceFC ELSE (SELECT t.Price FROM PPRData t WHERE t.ItemInfo_ItemCode=a.Code)END DifMny,b.SupplierConfirmQtyTU,b.PlanArriveDate,b.NeedPODate,b.DeliveryDate,b.UnRcvQty
FROM MRPReschedule a LEFT JOIN PO b ON a.DocNo=b.DocNo AND a.PlanLineNum=b.SubLineNo AND a.Linenum=b.DocLineNo
WHERE a.PlanMethod='MRP' AND (ISNULL(b.IsPresent,'')=''  OR (ISNULL(b.IsPresent,'')='1' AND a.rtype<>'取消') )--建议取消的赠品不显示
AND a.MRP_IsPurchaseBatchQty='1'--AND a.IsPurchaseBatchQty='0'
AND a.SMQty<>a.RescheduleQty--重排建议 不显示仅日期变更的
AND a.SourceType<>4
AND ISNULL(b.DocNo,'')<>''--只取采购订单
AND b.Status NOT IN (3,4,5)
AND ISNULL(b.PRType,0)<>4
AND (CASE WHEN a.RType='更新' AND a.RescheduleQty=b.UnRcvQty THEN 0 ELSE 1 END )=1
),
MRP3 AS--交期变更重排建议
(
SELECT a.*,ROW_NUMBER() OVER(ORDER BY a.MRPCategory,a.OriginalDate)RN,b.DocNo ActualDocNo,dbo.F_GetEnumName('UFIDA.U9.PM.PO.PODOCStatusEnum',b.Status,'zh-cn')ActualStatus
,b.SupplierName,b.SupplierConfirmQtyTU,b.PlanArriveDate,b.NeedPODate,b.DeliveryDate,b.UnRcvQty
FROM MRPReschedule a LEFT JOIN PO b ON a.DocNo=b.DocNo AND a.PlanLineNum=b.SubLineNo AND a.Linenum=b.DocLineNo
WHERE a.PlanMethod='MRP' AND (ISNULL(b.IsPresent,'')=''  OR (ISNULL(b.IsPresent,'')='1' AND a.rtype<>'取消') )--建议取消的赠品不显示
AND a.SMQty=a.RescheduleQty--重排建议 不显示仅日期变更的
AND a.SourceType<>4
AND ISNULL(b.DocNo,'')<>''--只取采购订单
AND b.Status NOT IN (3,4,5)
AND ISNULL(b.PRType,0)<>4
)
SELECT @html_MPS_Reschedule=N'<H2 bgcolor="#7CFC00">MPS重排建议执行</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">确认状态</th>
<th nowrap="nowrap">重排操作类型</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">行号</th><th nowrap="nowrap">订单状态</th><th nowrap="nowrap">供应性质</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">原始订单数量</th><th nowrap="nowrap">原始日期</th><th nowrap="nowrap">重排后数量</th><th nowrap="nowrap">重排日期</th></tr>'
+CAST((SELECT 
--td=CASE WHEN a.RType='更新' AND ABS(DATEDIFF(DAY,a.RescheduleDate,a.OriginalDate))<15 THEN '不处理' ELSE '需处理' END,'', 
td=ISNULL(a.MRPCategory,''),'',td=a.ConfirmType,'',td=a.RType,'',td=a.DocNo,'',td=a.Linenum,'',td=ISNULL(a.ActualStatus,''),'',td=a.SupplyType,'',td=a.Code,'',td=a.Name,'',td=a.SPECS,''
,td=CONVERT(DECIMAL(18,0),a.SMQty),'',td=a.OriginalDate,'',td=CONVERT(DECIMAL(18,0),a.RescheduleQty),'',td=a.RescheduleDate
FROM MPS2 a 
WHERE a.SMQty!=a.RescheduleQty 
AND  (CASE WHEN a.RType='更新' AND a.RescheduleQty=(ISNULL(a.UnRcvQty,ISNULL(a.UnCompleteQty,0))) THEN 0 ELSE 1 END) =1
ORDER BY a.RN FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))+N'</table><br/>'
--+N'<H2 bgcolor="#7CFC00">MPS重排建议执行(交期)</H2>'
--+N'<table border="1">'
--+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">确认状态</th>
--<th nowrap="nowrap">重排操作类型</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">行号</th><th nowrap="nowrap">订单状态</th><th nowrap="nowrap">供应性质</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">原始订单数量</th><th nowrap="nowrap">原始日期</th><th nowrap="nowrap">重排后数量</th><th nowrap="nowrap">重排日期</th></tr>'
--+CAST((SELECT 
----td=CASE WHEN a.RType='更新' AND ABS(DATEDIFF(DAY,a.RescheduleDate,a.OriginalDate))<15 THEN '不处理' ELSE '需处理' END,'', 
--td=ISNULL(a.MRPCategory,''),'',td=a.ConfirmType,'',td=a.RType,'',td=a.DocNo,'',td=a.Linenum,'',td=ISNULL(a.ActualStatus,''),'',td=a.SupplyType,'',td=a.Code,'',td=a.Name,'',td=a.SPECS,''
--,td=CONVERT(DECIMAL(18,0),a.SMQty),'',td=a.OriginalDate,'',td=CONVERT(DECIMAL(18,0),a.RescheduleQty),'',td=a.RescheduleDate
--FROM MPS2 a 
--WHERE a.SMQty=a.RescheduleQty AND FORMAT(a.RescheduleDate,'yyyy-MM-dd')!=ISNULL(FORMAT(a.PlanArriveDate,'yyyy-MM-dd'),FORMAT(a.CompleteDate,'yyyy-MM-dd'))
--ORDER BY a.RN FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))+N'</table><br/>'
,@html_MRP_Reschedule=N'<H2 bgcolor="#7CFC00">MRP重排建议执行（数量）</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">确认状态</th>
<th nowrap="nowrap">重排操作类型</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">行号</th><th nowrap="nowrap">供应商</th><th nowrap="nowrap">订单状态</th><th nowrap="nowrap">供应性质</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">基准</th><th nowrap="nowrap">原始订单数量</th><th nowrap="nowrap">原始日期</th><th nowrap="nowrap">重排后数量</th><th nowrap="nowrap">重排日期</th><th nowrap="nowrap">最小包装量</th><th nowrap="nowrap">金额</th></tr>'
+CAST((SELECT 
--td=CASE WHEN a.RType='更新' AND ABS(DATEDIFF(DAY,a.RescheduleDate,a.OriginalDate))<15 THEN '不处理' ELSE '需处理' END ,'',
 td=ISNULL(a.MRPCategory,''),'',td=a.ConfirmType,'',td=a.RType,'',td=a.DocNo,'',td=a.Linenum,'',td=ISNULL(a.SupplierName,''),'',td=ISNULL(a.ActualStatus,''),'',td=a.SupplyType,'',td=a.Code,'',td=a.Name,'',td=a.SPECS,''
,td=CONVERT(INT,a.TradeBaseQty),'',td=CONVERT(DECIMAL(18,0),a.SMQty),'',td=a.OriginalDate,'',td=CONVERT(DECIMAL(18,0),a.RescheduleQty),'',td=a.RescheduleDate,'',td=a.PurchaseBatchQty,'',td=CONVERT(DECIMAL(18,2),a.DifMny)
FROM MRP2 a
WHERE 1=1
ORDER BY a.DifMny desc FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))
+CAST((SELECT 
--td=CASE WHEN a.RType='更新' AND ABS(DATEDIFF(DAY,a.RescheduleDate,a.OriginalDate))<15 THEN '不处理' ELSE '需处理' END ,'',
 td='合计','',td='','',td='','',td='','',td='','',td='','',td='','',td='','',td='','',td='','',td='',''
,td='','',td='','',td='','',td='','',td='','',td='','',td=CONVERT(DECIMAL(18,2),SUM(ISNULL(a.DifMny,0)))
-- td=ISNULL(a.MRPCategory,''),'',td=a.ConfirmType,'',td=a.RType,'',td=a.DocNo,'',td=a.Linenum,'',td=ISNULL(a.SupplierName,''),'',td=ISNULL(a.ActualStatus,''),'',td=a.SupplyType,'',td=a.Code,'',td=a.Name,'',td=a.SPECS,''
--,td=CONVERT(DECIMAL(18,0),a.SMQty),'',td=a.OriginalDate,'',td=CONVERT(DECIMAL(18,0),a.RescheduleQty),'',td=a.RescheduleDate,'',td=a.PurchaseBatchQty,'',td=CONVERT(DECIMAL(18,2),a.DifMny)
FROM MRP2 a
WHERE 1=1
FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))+N'</table><br/>'
+N'<H2 bgcolor="#7CFC00">MRP重排建议执行(交期)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">确认状态</th>
<th nowrap="nowrap">重排操作类型</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">行号</th><th nowrap="nowrap">供应商</th><th nowrap="nowrap">订单状态</th><th nowrap="nowrap">供应性质</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">基准</th><th nowrap="nowrap">原始订单数量</th><th nowrap="nowrap">原始日期</th><th nowrap="nowrap">重排后数量</th><th nowrap="nowrap">重排日期</th><th nowrap="nowrap">最小包装量</th></tr>'
+CAST((SELECT 
--td=CASE WHEN a.RType='更新' AND ABS(DATEDIFF(DAY,a.RescheduleDate,a.OriginalDate))<15 THEN '不处理' ELSE '需处理' END ,'',
 td=ISNULL(a.MRPCategory,''),'',td=a.ConfirmType,'',td=a.RType,'',td=a.DocNo,'',td=a.Linenum,'',td=ISNULL(a.SupplierName,''),'',td=ISNULL(a.ActualStatus,''),'',td=a.SupplyType,'',td=a.Code,'',td=a.Name,'',td=a.SPECS,''
,td=CONVERT(INT,a.TradeBaseQty),'',td=CONVERT(DECIMAL(18,0),a.SMQty),'',td=a.OriginalDate,'',td=CONVERT(DECIMAL(18,0),a.RescheduleQty),'',td=a.RescheduleDate,'',td=a.PurchaseBatchQty
FROM MRP3 a
WHERE FORMAT(a.RescheduleDate,'yyyy-MM-dd')!=FORMAT(a.PlanArriveDate,'yyyy-MM-dd')
ORDER BY a.RN FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))+N'</table><br/>'
,@html_MRP_RescheduleMC=N'<H2 bgcolor="#7CFC00">MRP重排建议执行（数量）</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">确认状态</th>
<th nowrap="nowrap">重排操作类型</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">行号</th><th nowrap="nowrap">供应商</th><th nowrap="nowrap">订单状态</th><th nowrap="nowrap">供应性质</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">基准</th><th nowrap="nowrap">原始订单数量</th><th nowrap="nowrap">原始日期</th><th nowrap="nowrap">重排后数量</th><th nowrap="nowrap">重排日期</th><th nowrap="nowrap">最小包装量</th></tr>'
+CAST((SELECT 
--td=CASE WHEN a.RType='更新' AND ABS(DATEDIFF(DAY,a.RescheduleDate,a.OriginalDate))<15 THEN '不处理' ELSE '需处理' END ,'',
 td=ISNULL(a.MRPCategory,''),'',td=a.ConfirmType,'',td=a.RType,'',td=a.DocNo,'',td=a.Linenum,'',td=ISNULL(a.SupplierName,''),'',td=ISNULL(a.ActualStatus,''),'',td=a.SupplyType,'',td=a.Code,'',td=a.Name,'',td=a.SPECS,''
,td=CONVERT(INT,a.TradeBaseQty),'',td=CONVERT(DECIMAL(18,0),a.SMQty),'',td=a.OriginalDate,'',td=CONVERT(DECIMAL(18,0),a.RescheduleQty),'',td=a.RescheduleDate,'',td=a.PurchaseBatchQty,''
FROM MRP2 a
WHERE 1=1
ORDER BY a.DifMny desc FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))+N'</table><br/>'
+N'<H2 bgcolor="#7CFC00">MRP重排建议执行(交期)</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th nowrap="nowrap">MRP分类</th><th nowrap="nowrap">确认状态</th>
<th nowrap="nowrap">重排操作类型</th><th nowrap="nowrap">单号</th><th nowrap="nowrap">行号</th><th nowrap="nowrap">供应商</th><th nowrap="nowrap">订单状态</th><th nowrap="nowrap">供应性质</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">基准</th><th nowrap="nowrap">原始订单数量</th><th nowrap="nowrap">原始日期</th><th nowrap="nowrap">重排后数量</th><th nowrap="nowrap">重排日期</th><th nowrap="nowrap">最小包装量</th></tr>'
+CAST((SELECT 
--td=CASE WHEN a.RType='更新' AND ABS(DATEDIFF(DAY,a.RescheduleDate,a.OriginalDate))<15 THEN '不处理' ELSE '需处理' END ,'',
 td=ISNULL(a.MRPCategory,''),'',td=a.ConfirmType,'',td=a.RType,'',td=a.DocNo,'',td=a.Linenum,'',td=ISNULL(a.SupplierName,''),'',td=ISNULL(a.ActualStatus,''),'',td=a.SupplyType,'',td=a.Code,'',td=a.Name,'',td=a.SPECS,''
,td=CONVERT(INT,a.TradeBaseQty),'',td=CONVERT(DECIMAL(18,0),a.SMQty),'',td=a.OriginalDate,'',td=CONVERT(DECIMAL(18,0),a.RescheduleQty),'',td=a.RescheduleDate,'',td=a.PurchaseBatchQty
FROM MRP3 a
WHERE FORMAT(a.RescheduleDate,'yyyy-MM-dd')!=FORMAT(a.PlanArriveDate,'yyyy-MM-dd')
ORDER BY a.RN FOR XML PATH('tr') ,type)AS NVARCHAR(MAX))+N'</table><br/>'

declare @strbody varchar(800)
declare @style Varchar(200)
SET @html=ISNULL(@html_MPS_PlanOrder,'')+ISNULL(@html_MRP_MPSDetail,'')+ISNULL(@html_MPS_Reschedule,'')+ISNULL(@html_MRP_PlanOrder,'')+ISNULL(@html_MRP_Reschedule,'')
SET @style=	'<style>table,table tr th, table tr td { border:1px solid #4F94CD; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
SET @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是截止'+convert(varchar(11),getdate(),121)+',MRP\MPS未处理单据，请相关人员急时处理。谢谢！</H2>'
SET @html=@strbody+ISNULL(@html,'')+N'</br><H2>以上由系统发出无需回复!</H2>'

SET @htmlMC=ISNULL(@html_MPS_PlanOrder,'')+ISNULL(@html_MRP_MPSDetail,'')+ISNULL(@html_MPS_Reschedule,'')+ISNULL(@html_MRP_PlanOrder,'')+ISNULL(@html_MRP_RescheduleMC,'')
SET @style=	'<style>table,table tr th, table tr td { border:1px solid #4F94CD; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
SET @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是截止'+convert(varchar(11),getdate(),121)+',MRP\MPS未处理单据，请相关人员急时处理。谢谢！</H2>'
SET @htmlMC=@strbody+ISNULL(@htmlMC,'')+N'</br><H2>以上由系统发出无需回复!</H2>'
	
	--带金额邮件
	 EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=db_Automail,
	--@recipients='yangm@auctus.cn;huangxh@auctus.cn;buyermd01@auctus.cn;yanjing@auctus.com;mall@auctus.com;ningzh@auctus.cn;tonghui@auctus.cn;chenyong@auctus.com;lihb@auctus.cn;liuyy@auctus.cn;zougl@auctus.cn;liufei@auctus.com;', 
	--@recipients='andy@auctus.cn;zougl@auctus.cn;perla_yu@auctus.cn', 
	@recipients='umrp@auctus.cn;', 
	--@copy_recipients='zougl@auctus.cn;', 
	@blind_copy_recipients='liufei@auctus.cn;',
	@subject ='MRP\MPS未处理单据',
	@body = @html,
	@body_format = 'HTML';  
	--不带金额邮件
	EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=db_Automail,
	--@recipients='yangm@auctus.cn;huangxh@auctus.cn;buyermd01@auctus.cn;yanjing@auctus.com;mall@auctus.com;ningzh@auctus.cn;tonghui@auctus.cn;chenyong@auctus.com;lihb@auctus.cn;liuyy@auctus.cn;zougl@auctus.cn;liufei@auctus.com;', 
	--@recipients='andy@auctus.cn;zougl@auctus.cn;perla_yu@auctus.cn', 
	@recipients='umrpmc@auctus.cn;', 
	--@copy_recipients='zougl@auctus.cn;', 
	@blind_copy_recipients='liufei@auctus.cn;',
	@subject ='MRP\MPS未处理单据',
	@body = @htmlMC,
	@body_format = 'HTML'; 


END 

