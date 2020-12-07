USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_FullSetCheckDetail]    Script Date: 2020/9/14 9:37:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
标题：3天齐套率考核明细
需求：高李琼
开发：liufei
时间：2018-12-08

ADD（2019-5-7）
内部生产料号不参与考核

ADD(2019-5-14)
试产工单、功放工单单独拿出来计算

update(2020-4-7)
内部生产拆分为：包装、组装、后焊、功放、前加工

*/
CREATE PROC [dbo].[sp_Auctus_FullSetCheckDetail_Mes]
(
@Org BIGINT,
@SD DATETIME,
@ED DATETIME
)
AS
BEGIN
SET @ED=DATEADD(DAY,1,@ED)
select   a.DocNo,a.DocLineNo,a.PickLineNo,a.DocType,a.ProductCode,a.ProductName,a.ProductQty
,a.Code,a.Name,a.SPEC,a.SafetyStockQty,a.ReqQty,CONVERT(date,a.ActualReqDate)ActualReqDate,a.LackAmount,a.WhavailiableAmount
,CASE WHEN PATINDEX('%试产%',DocType)>0 THEN '试产工单' 
WHEN PATINDEX('%功放%',ProductLine)>0 THEN '功放工单'
ELSE buyer END buyer
,a.MRPCategory,a.CopyDate
,CASE WHEN FixedLT<3 AND ResultFlag='缺料' AND DATEADD(DAY,(-1)*FixedLT,ActualReqQty)>CopyDate THEN '齐套'
ELSE ResultFlag END ResultFlag2  from   dbo.Auctus_Mes_FullSetCheckResult3 a
WHERE  a.MRPCategory NOT IN ('包装','组装','后焊','功放','前加工','前加工委外')
AND CASE WHEN (MRPCategory='包材' OR a.MRPCategory='配件')AND ActualReqDate>CopyDate  THEN 1 ELSE 0 END<>1
ORDER BY a.CopyDate,a.DocNo

END





