USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_QuotaPerformanceInfo]    Script Date: 2018/8/14 10:15:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
1、按组织奖请购单行按料号汇总
2、取出配额比例料的集合
3、1和2连表，根据标准比例和实际采购数量求出标准采购数量
4、根据实际比例和标准比例对比结果判断记录是否合格
5、求出汇总浮动百分比
Add
1、根据请购单取出采购单金额数量
*/

ALTER PROC [dbo].[sp_Auctus_QuotaPerformanceInfo]
(
@Org BIGINT,
@StartDate DATETIME,
@EndDate DATETIME
)
AS
BEGIN
--DECLARE @Org BIGINT=1001708020135665
--DECLARE @StartDate DATETIME='2018-02-01'
--DECLARE @EndDate DATETIME='2018-05-01'
;WITH PRInfo AS--请购单
(
SELECT b.ItemInfo_ItemCode
--,SUM(b.ApprovedQtyPU)ApprovedQtyPU--核准数量
,SUM(b.TotalRecievedQtyTU)PR_ReceivedQty--已实收数量1（实际采购数量回写）
FROM dbo.PR_PR a LEFT JOIN dbo.PR_PRLine b ON a.ID=b.PR
WHERE a.Org=@Org
AND a.Status NOT IN(0,1)
--AND a.Status=2
--AND a.ApprovedOn BETWEEN '2018-04-01' AND GETDATE()
AND a.ApprovedOn BETWEEN @StartDate AND @EndDate
GROUP BY b.ItemInfo_ItemCode
),
PurInfo AS--采购单
(
SELECT  b.ItemInfo_ItemCode
,SUM(SupplierConfirmQtyPU)ConfirmQty--确认数量
--,SUM(b.NetMnyFC)NetMnyFC--未税金额（单价*确认数量）
,SUM(b.TotalRecievedQtyCU)Pur_ReceievedQty--已实收数量（实际收货回写）
,SUM(b.NetMnyFC*a.ACToFCExchRate*b.TotalRecievedQtyCU/SupplierConfirmQtyPU) Pur_ActualNetMnyFC--未税金额（单价*已实收数量）
FROM dbo.PM_PurchaseOrder a  LEFT JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
LEFT JOIN dbo.PM_PODocType c ON a.DocumentType=c.ID LEFT JOIN dbo.PM_PODocType_Trl c1 ON c.ID=c1.ID
WHERE a.Org=@Org
AND a.STATUS NOT IN (0,1)
AND c1.SysMLFlag='zh-CN'
AND PATINDEX('%内部%',c1.Name)=0
--AND a.ApprovedOn BETWEEN '2018-04-01' AND GETDATE()
AND a.ApprovedOn BETWEEN @StartDate AND @EndDate
GROUP BY b.ItemInfo_ItemCode
),
QuotaInfo1 AS
(
SELECT DISTINCT b.DocLineNo FROM PRInfo a LEFT JOIN SZCust_LTQuotasDocLine b ON a.ItemInfo_ItemCode=b.Component_Code
),
QuotaInfo2 AS 
(
SELECT DISTINCT b.DocLineNo FROM PurInfo a LEFT JOIN SZCust_LTQuotasDocLine b ON a.ItemInfo_ItemCode=b.Component_Code
),
QuotaDocLines AS
(
SELECT DocLineNo FROM QuotaInfo1 
UNION
SELECT DocLineNo FROM QuotaInfo2
),
QuotaO AS
(
SELECT a2.ID AS Org_ID,a2.Code AS Org_Code,a3.Name AS Org_Name,a.DocNo,a.IsEffective,
dbo.F_GetEnumName(N'Ufida.U9.SZCust.LT.QuotasBE.QuotasBE.DocStatusEnum',a.DocStatus,N'zh-cn') AS Status,
a1.DocLineNo,a1.SubLineNo,a1.GroupNo,
a1.BOMMaster_Code,a1.BOMMaster_Name,a1.BOMMaster_ItemSpecs,
a1.Component_Code,a1.Component_Name,a1.Component_ItemSpecs,
dbo.F_GetEnumName(N'UFIDA.U9.CBO.MFG.Enums.ComponentTypeEnum',a1.ComponentType,N'zh-cn') AS ComponentType,
a1.Quota,
a1.Effective_Date,
a1.Disable_Date,
a1.Price,
a4.Code AS SuppCode,
a5.Name AS SuppName
,ROW_NUMBER() OVER(PARTITION BY a1.DocLineNo,a1.SubLineNo ORDER BY a1.Disable_Date) rn
  from   dbo.SZCust_LTQuotasDoc AS a
INNER JOIN dbo.SZCust_LTQuotasDocLine AS a1 ON a1.LTQuotasDoc = a.ID
									AND a1.IsEffective = 1
INNER JOIN dbo.Base_Organization AS a2 ON a2.ID = a.Org
INNER JOIN dbo.Base_Organization_Trl AS a3 ON a3.ID = a2.ID AND a3.SysMLFlag = 'zh-cn'
LEFT JOIN dbo.CBO_Supplier AS a4 ON a4.ID = ISNULL(a1.Supplier,0)
LEFT JOIN dbo.CBO_Supplier_Trl AS a5 ON a5.ID = a4.ID AND a5.SysMLFlag = 'zh-cn'
 where  (DocNo = N'QO30180703001')--  order by   a.ID,a1.DocLineNo,a1.BizKey,a1.ComponentType,a1.GroupNo
 AND a1.DocLineNo IN (SELECT t.DocLineNo FROM QuotaDocLines t)
 --AND a1.Disable_Date BETWEEN @StartDate AND @EndDate
),
Quota AS
(
SELECT * FROM QuotaO WHERE QuotaO.rn=1
),
Quota_PR AS
(
SELECT a.DocLineNo,a.SubLineNo,a.Component_Code,a.Component_Name,a.ComponentType,a.Quota,a.Price,a.Effective_Date
--,ISNULL(b.ApprovedQtyPU ,0)ApprovedQtyPU
,ISNULL(b.PR_ReceivedQty,0)PR_ReceivedQty
,ISNULL(c.Pur_ReceievedQty,0)Pur_ReceievedQty
,ISNULL(c.Pur_ActualNetMnyFC,0)Pur_ActualNetMnyFC
FROM Quota a Left JOIN PRInfo b ON a.Component_Code=b.ItemInfo_ItemCode LEFT JOIN PurInfo c ON a.Component_Code=c.ItemInfo_ItemCode
--ORDER BY a.DocLineNo,a.ComponentType
),
PRGroup AS
(
SELECT a.DocLineNo,SUM(a.PR_ReceivedQty)SumQty FROM Quota_PR a GROUP BY a.DocLineNo
),
QuotaResult AS
(
SELECT a.*,b.SumQty,b.SumQty/100*a.Quota StandQty,a.Price*a.Pur_ReceievedQty StandMnyFC
FROM Quota_PR a LEFT JOIN PRGroup b ON a.DocLineNo=b.DocLineNo
),
Result AS
(
SELECT a.DocLineNo,a.SubLineNo,a.Component_Code,a.Component_Name,a.ComponentType,a.Quota,a.Effective_Date
--,a.ApprovedQtyPU
,a.PR_ReceivedQty,a.SumQty,a.StandQty
,a.Pur_ReceievedQty,a.Pur_ActualNetMnyFC,a.StandMnyFC
, CASE WHEN a.PR_ReceivedQty=a.StandQty THEN '合格' ELSE '不合格' END Result
FROM QuotaResult a
-- ORDER BY a.DocLineNo,a.SubLineNo
)
SELECT  a.DocLineNo,a.SubLineNo
,a.Component_Code
,a.Component_Name,a.ComponentType,a.Quota,a.Effective_Date
--,a.ApprovedQtyPU
,CONVERT(DECIMAL(18,2),a.PR_ReceivedQty)PR_ReceivedQty
,a.SumQty
,CONVERT(DECIMAL(18,2),a.StandQty)StandQty
,CONVERT(DECIMAL(18,2),a.Pur_ReceievedQty)Pur_ReceievedQty
,CONVERT(DECIMAL(18,2),a.Pur_ActualNetMnyFC)Pur_ActualNetMnyFC
,CONVERT(DECIMAL(18,2),a.StandMnyFC)StandMnyFC
,a.Result
--INTO #temp
FROM Result a ORDER BY a.DocLineNo,a.SubLineNo
End







