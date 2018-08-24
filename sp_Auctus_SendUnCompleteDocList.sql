USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_SendUnCompleteDocList]    Script Date: 2018/8/24 17:24:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
1、请购单 要求交货日期并无采购单
2、采购单 需求交期未收货
3、生产工单  计划完工日未完工
4、生产订单备料单未齐套
5、委外备料单未齐套
*/
 
--exec sp_Auctus_SendUnCompleteDocList

ALTER PROC [dbo].[sp_Auctus_SendUnCompleteDocList]
AS
BEGIN 
 
 

 
 
DECLARE @html NVARCHAR(MAX)
DECLARE @html_PR NVARCHAR(MAX)
DECLARE @html_PO NVARCHAR(MAX)
DECLARE @html_MO NVARCHAR(MAX)
DECLARE @html_MOPickList NVARCHAR(MAX)
DECLARE @html_WPOPiclList NVARCHAR(MAX)
DECLARE @Org BIGINT=1001708020135665
--请购单

;
WITH PR AS
(
SELECT a.ID,a.CreatedBy,b.ID Line_ID,a.DocNo,a.BusinessDate,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,CONVERT(VARCHAR(50),b.RequiredDeliveryDate,120)RequiredDeliveryDate,b.ApprovedQtyTU 
,c1.Name
FROM dbo.PR_PR a 
INNER JOIN dbo.PR_PRLine b ON a.ID=b.PR LEFT JOIN PR_PRDocType c ON a.PRDocType=c.ID LEFT JOIN dbo.PR_PRDocType_Trl c1 ON c.ID=c1.ID
WHERE a.Status IN (0,1,2) AND b.Status IN (0,1,2)
AND b.RequiredDeliveryDate<=GETDATE()
AND c1.SysMLFlag='zh-cn'
AND a.Org=@Org
),
PO AS
(
	SELECT a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.PRID,b.PRLineID FROM dbo.PM_PurchaseOrder a 
	INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
	WHERE b.PRLineID<>0
) 
SELECT @html_PR=N'<H2 bgcolor="#7CFC00">请购单要求交货日期逾期未转采购单据</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th>请购单号</th><th>行号</th><th>创建人</th><th>业务日期</th><th>料号</th><th>品名</th><th>核准数量1</th><th>要求交货日期</th><th>单据类型</th></tr>'
+CAST((SELECT td=a.DocNo,'',td=a.DocLineNo,'',td=a.CreatedBy,'',td=convert(varchar(10),a.BusinessDate,120),'',td=a.ItemInfo_ItemCode,''
,td=a.ItemInfo_ItemName,'',td=CONVERT(DECIMAL(18,0),a.ApprovedQtyTU),'',td=convert(varchar(10), a.RequiredDeliveryDate,120),'',td=a.Name   
FROM PR a 
LEFT JOIN PO b ON a.Line_ID=b.PRLineID
WHERE b.DocNo IS NULL
ORDER BY a.RequiredDeliveryDate,a.DocNo  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'


--采购单
;
WITH PO2 AS
(
	SELECT a.DocNo,b.DocLineNo,c.SubLineNo,a.CreatedBy,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,CONVERT(VARCHAR(50),c.DeliveryDate,120) DeliveryDate
	,c.TotalRecievedQtyTU,c.ReqQtyTU ,d1.Name
	FROM dbo.PM_PurchaseOrder a 
	INNER JOIN PM_POLine b ON a.ID=b.PurchaseOrder 
	INNER JOIN dbo.PM_POShipLine c ON c.POLine=b.ID LEFT JOIN PM_PODocType d ON a.DocumentType=d.ID LEFT JOIN dbo.PM_PODocType_Trl d1 ON d.ID=d1.ID
	WHERE a.Status IN (0,1,2) AND b.Status IN (0,1,2) AND c.status IN (0,1,2)
	AND c.DeliveryDate<=GETDATE()
	AND c.ReqQtyCU>c.TotalRecievedQtyTU
	AND d1.SysMLFlag='zh-cn'
	AND a.Cancel_Canceled=0 AND b.Cancel_Canceled=0 AND c.Cancel_Canceled=0
	AND ISNULL(c.HoldUser,'')=''
	AND a.Org=@Org
)
SELECT @html_PO=N'<H2 bgcolor="#7CFC00">采购单交期逾期未交货单据</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th>采购单号</th><th>行号</th><th>子行号</th><th>创建人</th><th>料号</th><th>品名</th><th>需求数量1</th><th>已收数量</th><th>要求交货日期</th><th>单据类型</th></tr>'
+CAST((SELECT td=a.DocNo,'',td=a.DocLineNo,'',td=a.SubLineNo,'',td=a.CreatedBy,'',td=a.ItemInfo_ItemCode,'',td=a.ItemInfo_ItemName,''
,td=CONVERT(DECIMAL(18,0),a.ReqQtyTU),'',td=CONVERT(DECIMAL(18,0),a.TotalRecievedQtyTU),'',td=convert(varchar(10),a.DeliveryDate ,120)
,'',td=a.Name
FROM PO2 a
ORDER BY a.DeliveryDate  FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'


--生产订单
;
WITH MO AS
(
SELECT a.DocNo,a.ItemMaster,a.CreatedBy,a.ProductQty,SUM(ISNULL(b.CompleteQty,0))CompleteQty,CONVERT(VARCHAR(50),a.CompleteDate,120) CompleteDate
,c1.Name
FROM dbo.MO_MO a LEFT JOIN dbo.MO_CompleteRpt b ON a.ID=b.MO LEFT JOIN dbo.MO_MODocType c ON a.MODocType=c.ID LEFT JOIN dbo.MO_MODocType_Trl c1 ON c.Id=c1.ID
WHERE a.DocState<>3
AND a.Cancel_Canceled=0
AND a.IsHoldRelease=0
AND a.CompleteDate<GETDATE()
AND c1.SysMLFlag='zh-cn'
AND a.Org=@Org
GROUP BY a.DocNo,a.ItemMaster,a.ProductQty,a.CompleteDate,a.CreatedBy,c1.Name
)
SELECT @html_MO=N'<H2 bgcolor="#7CFC00">生产订单计划完工日期逾期未完工单据</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th>生产订单号</th><th>创建人</th><th>料号</th><th>品名</th><th>生产数量</th><th>完工数量</th><th>计划完工日</th><th>单据类型</th></tr>'
+CAST((SELECT td=a.DocNo,'',td=a.CreatedBy,'',td=b.Code,'',td=b.Name,'',td=CONVERT(DECIMAL(18,0),a.ProductQty),'',td=CONVERT(DECIMAL(18,0),a.CompleteQty),''
,td=convert(varchar(10), a.CompleteDate,120),'',td=a.Name
FROM MO a LEFT JOIN dbo.CBO_ItemMaster b ON a.ItemMaster=b.ID
WHERE a.ProductQty>a.CompleteQty
ORDER BY a.CompleteDate FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'

--生产订单备料单
SELECT @html_MOPickList=N'<H2 bgcolor="#7CFC00">生产订单备料未齐套单据</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th>生产订单号</th><th>创建人</th><th>行号</th><th>料号</th><th>品名</th><th>已发放数量</th><th>实际需求量</th><th>BOM需求数量</th>
<th>计划需求日</th><th>实际需求日</th><th>单据类型</th></tr>'
+CAST((SELECT td=a.DocNo,'',td=a.CreatedBy,'',td=b.DocLineNO,'',td=c.Code,'',td=c.Name,'',td=CONVERT(DECIMAL(18,0),b.IssuedQty)
,'',td=CONVERT(DECIMAL(18,0),b.ActualReqQty),'',td=CONVERT(DECIMAL(18,0),b.BOMReqQty),'',td=CONVERT(VARCHAR(50),b.PlanReqDate,120)
,'',td=CONVERT(VARCHAR(50),b.ActualReqDate,120),'',td=d1.Name
FROM dbo.MO_MO a LEFT JOIN dbo.MO_MOPickList b ON a.ID=b.MO LEFT JOIN dbo.CBO_ItemMaster c ON b.ItemMaster=c.ID
LEFT JOIN dbo.MO_MODocType d ON a.MODocType=d.ID LEFT join dbo.MO_MODocType_Trl d1 ON d.ID=d1.ID
WHERE a.Org=@Org
AND b.IssuedQty<b.ActualReqDate
AND a.Cancel_Canceled=0
AND a.DocState<>3
AND a.IsHoldRelease=0
AND b.ActualReqDate<GETDATE()
AND b.ActualReqQty>0
ORDER BY b.ActualReqDate,a.DocNo,b.DocLineNO FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'


--委外备料单
SELECT @html_WPOPiclList=N'<H2 bgcolor="#7CFC00">委外备料未齐套单据</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#1C86EE"><th>委外单号</th><th>行号</th><th>备料单行号</th><th>创建人</th><th>料号</th><th>品名</th><th>已发放数量</th>
<th>实际需求量</th><th>BOM需求数量</th><th>计划需求日</th><th>实际需求日</th><th>单据类型</th></tr>'
+CAST((SELECT td=a.DocNo,'',td=b.DocLineNo,'',td=d.PickLineNo,'',td=a.CreatedBy
,'',td=d.ItemInfo_ItemCode,'',td=d.ItemInfo_ItemName,'',td=CONVERT(DECIMAL(18,0),d.IssuedQty)
,'',td=CONVERT(DECIMAL(18,0),d.ActualReqQty),'',td=CONVERT(DECIMAL(18,0),d.BOMReqQty),''
,td=CONVERT(VARCHAR(50),d.PlanReqDate,120),'',td=CONVERT(VARCHAR(50),d.ActualReqDate,120),'',td=f1.Name
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
LEFT JOIN dbo.PM_PODocType f ON a.DocumentType=f.ID LEFT JOIN dbo.PM_PODocType_Trl f1 ON f.ID=f1.ID
WHERE a.Status in(0,1,2) and b.Status in (0,1,2) 
AND a.Org=@Org 
AND d.ActualReqDate<GETDATE()
AND d.IssuedQty<d.ActualReqQty
AND a.Cancel_Canceled=0
AND a.IsHolded=0
AND d.IssueStyle<>2
and  exists  (select 1 from PM_POShipLine b1  where e.ID=b1.ID   )
AND d.ActualReqQty>0
AND c.ID IS NOT NULL 
ORDER BY d.ActualReqDate,a.DocNo,b.DocLineNo,d.PickLineNo FOR XML PATH('tr'),TYPE)AS nvarchar(MAX))+N'</table><br/>'



SET @html=@html_PR+@html_PO+@html_MO+@html_MOPickList+@html_WPOPiclList
--SET @html=@html_MOPickList--+@html_WPOPiclList
declare @strbody varchar(800)
declare @style Varchar(200)
SET @style=	'<style>table,table tr th, table tr td { border:1px solid #4F94CD; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
set @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是截止'+convert(varchar(11),getdate(),121)+'各业务模块逾期未处理单据，请相关人员急时处理。谢谢！</H2>'
set @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'
 
 EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=db_Automail, 
	@recipients='heqh@auctus.cn;lihj@auctus.cn;caidy@auctus.cn;yaorm@auctus.cn;wengyt@auctus.cn;fuzg@auctus.cn;linbh@auctus.cn;yangling@auctus.cn;lisd@auctus.cn;', 
	@copy_recipients='zougl@auctus.cn;hudz@auctus.cn;jigy@auctus.cn;xiongls@auctus.cn', 
	--@recipients='liufei@auctus.cn', 
	--@copy_recipients='hudz@auctus.cn', 
	@subject ='单据逾期未处理列表',
	@body = @html,
	@body_format = 'HTML'; 

END 

