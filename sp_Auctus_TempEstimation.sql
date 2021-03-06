USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_TempEstimation]    Script Date: 2018/8/14 10:15:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
暂估报表
查询全组织未立应付单据收货(包括委外)、退货单
*/
--EXEC sp_Auctus_TempEstimation @Org='',@StartDate='',@EndDate=''
ALTER PROC [dbo].[sp_Auctus_TempEstimation]
(
@Org varchar(500),
@StartDate DATETIME,
@EndDate DATETIME
)
AS
BEGIN 
--实收数量为0
--DECLARE @Org VARCHAR(500)
SET @Org=REPLACE(@Org,';',',')
IF ISNULL(@Org,'')=''
BEGIN
SELECT @Org=(SELECT (CAST(ID AS VARCHAR(50))+',') FROM dbo.Base_Organization  FOR XML PATH('')) FROM dbo.Base_Organization
SET @Org=LEFT(@Org,LEN(@Org)-1)
--SELECT @Org
END 
;
--交货数量，对应订单号码 ， 单价， 金额都导出来
WITH RCV AS--收货单明细 TODO：添加查询条件
(
SELECT a.DocNo,b.DocLineNo,a.ID,b.ID Line_ID
,a.CreatedOn,a.ApprovedOn,b.ConfirmDate
,dbo.F_GetEnumName('UFIDA.U9.PM.Rcv.RcvStatusEnum',a.Status,'zh-cn')Status 
,dbo.F_GetEnumName('UFIDA.U9.PM.Rcv.RcvStatusEnum',b.Status,'zh-cn')Line_Status
,a.Org,a.Supplier_Supplier
,b.ItemInfo_ItemID,b.ItemInfo_ItemName,b.ItemInfo_ItemCode
,b.ConfirmTerm --立账条件
,b.FreeType
,b.RcvQtyTU,b.TaxRate ,b.ACToFCExchRate 
,a.TC,b.FinallyPriceTC ,b.ArriveTotalNetMnyTC ,b.ArriveTotalMnyTC 
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
WHERE  a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Org))AND 
((a.IsInitEvaluation=0 AND (a.biztype IN (316,322,321))) OR (a.IsInitEvaluation=0 AND a.BizType IN (316,322,328,321))
OR (a.BizType IN ((-(1)), 325, 326)))
AND b.RcvQtyTU<>0 AND b.FreeType NOT IN (0,1)
--AND a.docno='RCV30170905001'
),
APBill AS--应付单  TODO：添加查询条件
(
SELECT a.DocNo,b.LineNum,b.SrcBillID,b.SrcBillNum,b.SrcBillLineID,b.SrcBillLineNum ,c.OppDataTag
FROM dbo.AP_APBillHead a INNER JOIN dbo.AP_APBillLine b ON a.ID=b.APBillHead
LEFT JOIN  dbo.AP_APMatchLine c ON b.ID=c.SelfDataTag
WHERE a.Org IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Org))
--AND b.SrcBillNum='RCV30170905001'
),
Result AS
(
SELECT o1.Name 公司,s1.Name 供应商,d1.Name 立账条件,a.DocNo 单号,a.DocLineNo 行号
,a.ItemInfo_ItemID,a.ItemInfo_ItemCode 料号,a.ItemInfo_ItemName 品名,c.SPECS 规格
,a.Status 收货单状态,a.Line_Status 收获行状态
,a.CreatedOn 单据创建时间,a.ApprovedOn 审核时间,a.ConfirmDate 入库确认日
,a.Line_ID
,a.RcvQtyTU 实到数量,a.TaxRate 税率,a.ACToFCExchRate 汇率
,a.TC,a.FinallyPriceTC 最终价,a.ArriveTotalNetMnyTC 实到未税额,a.ArriveTotalMnyTC 实到税价合计
--,b.*
FROM RCV a LEFT JOIN APBill b ON a.Line_ID=b.OppDataTag 
LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemInfo_ItemID=c.ID
LEFT JOIN CBO_APConfirmTerm d ON a.ConfirmTerm=d.ID LEFT JOIN dbo.CBO_APConfirmTerm_Trl d1 ON d.ID=d1.ID
LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
LEFT JOIN dbo.CBO_Supplier s ON a.Supplier_Supplier=s.ID LEFT JOIN dbo.CBO_Supplier_Trl s1 ON s.ID=s1.ID
WHERE b.OppDataTag IS NULL
AND o1.SysMLFlag='zh-cn' AND s1.SysMLFlag='zh-cn' AND d1.SysMLFlag='zh-cn'
--AND o.Code='500' 
)
--SELECT * FROM APBill WHERE SrcBillNum='RCV30170905001'
--SELECT * FROM Result WHERE 单号='RCV30170905001'
SELECT a.*,c1.Name 币种 FROM Result a LEFT JOIN APBILL b ON a.单号=b.srcbillnum AND a.Line_ID=b.SrcBillLineID
LEFT JOIN dbo.Base_Currency c ON a.TC=c.ID LEFT JOIN dbo.Base_Currency_Trl c1 ON c.ID=c1.ID
WHERE b.srcbillnum IS NULL --AND a.单号='RCV30170905001'
AND c1.SysMLFlag='zh-cn'
ORDER BY a.公司,a.单号,a.行号,a.单据创建时间

/*
SELECT * FROM dbo.AP_APBillLine WHERE SrcBillNum='RCV30170905001'
SELECT b.ID FROM dbo.PM_Receivement a LEFT JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
WHERE a.DocNo='RCV30170905001'
SELECT * FROM dbo.AP_APMatchLine WHERE OppDataTag IN (SELECT b.ID FROM dbo.PM_Receivement a LEFT JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
WHERE a.DocNo='RCV30170905001')

SELECT a.DocNo,b.LineNum,b.SrcBillID,b.SrcBillNum,b.SrcBillLineID,b.SrcBillLineNum ,c.OppDataTag
FROM dbo.AP_APBillHead a INNER JOIN dbo.AP_APBillLine b ON a.ID=b.APBillHead
LEFT JOIN  dbo.AP_APMatchLine c ON b.ID=c.SelfDataTag
WHERE c.OppDataTag IN (SELECT b.ID FROM dbo.PM_Receivement a LEFT JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
WHERE a.DocNo='RCV30170905001')
*/



END