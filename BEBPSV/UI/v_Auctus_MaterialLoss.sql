/*
物料耗损
*/
CREATE VIEW v_Auctus_MaterialLoss
AS

WITH MRPPlan AS--MRP计划
(
SELECT a.ID PlanName,a.PlanCode,b.ID PlanVersion,b.Version ,a.PlanMethod
FROM dbo.MRP_PlanName a 
INNER JOIN dbo.MRP_PlanVersion b ON a.ID=b.PlanName
WHERE a.PlanCode='30-MRP'
),
ItemInfo AS
(
SELECT a.ID,a.Code,a.Name
,CASE WHEN a.DescFlexField_PrivateDescSeg25='' THEN 0 ELSE a.DescFlexField_PrivateDescSeg25 END  LossRate
FROM dbo.CBO_ItemMaster a WHERE a.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
AND a.Effective_IsEffective=1
--AND a.DescFlexField_PubDescSeg25>0
),
MRPReschedule AS --MRP重排建议未执行
(
SELECT m.ID ItemID,m.Code,m.Name,m.LossRate
,a.SMQty,a.RescheduleQty
,a.SMQty-a.RescheduleQty CancelQty
--,100 CancelQty
,a.RType,dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.RescheduleACDType',a.RType,'zh-cn') RTTypeName
,a.DocNo,a.PlanLineNum
,a.SupplyType,dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.SupplyTypeEnum',a.RType,'zh-cn') SupplyTypeName
,b.*
FROM dbo.MRP_Reschedule a INNER JOIN MRPPlan b ON a.PlanVersion=b.PlanVersion
INNER JOIN ItemInfo m ON a.Item=m.ID
WHERE a.ConfirmType=0
),
PlanOrder AS
(
--MRP分类，料号、品名、规格、需求日期、数量、已发放量、释放量、安全库存量、开工日期
SELECT dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.ScheduleMethodEnum',b.PlanMethod,'zh-cn')PlanMethod
,b.PlanVersion,b.PlanName,b.PlanCode
,a.DocNo
--,a.DemandCode
,e.ID ItemID,e.Code,e.Name,e.LossRate
,a.Qty
,a.ReleasedQty--已发放数量
,a.MRPQty-a.ReleasedQty ReleaseQty--MRP调整后数量-已发放数量=释放量
--,d.ID IsRelease--计划订单是否释放
FROM dbo.MRP_PlanOrder a INNER JOIN MRPPlan b ON a.SrcPlanVersion=b.PlanVersion
--LEFT JOIN dbo.MRP_PlanOrderConsumption d ON a.ID=d.PlanOrder 
INNER JOIN ItemInfo e ON a.Item=e.ID
),
PlanOrderSum AS
(
SELECT 
a.PlanCode,a.PlanVersion,a.PlanName,a.ItemID,a.Code,a.Name,SUM(a.Qty)TotalQty,CEILING(SUM(a.Qty*a.LossRate)) TotalLossQty
FROM PlanOrder a GROUP BY a.PlanName,a.PlanCode,a.PlanVersion,a.ItemID,a.Code,a.Name
),
MRPSum AS
(
SELECT 
a.ItemID,SUM(ISNULL(a.CancelQty,0))TotalCancelQty
FROM MRPReschedule a
GROUP BY a.ItemID
)
SELECT
a.*,ISNULL(b.TotalCancelQty,0)TotalCancelQty
FROM PlanOrderSum a LEFT JOIN MRPSum b ON a.ItemID=b.ItemID
--WHERE ISNULL(b.TotalCancelQty,0)>0--正式运行要注释




