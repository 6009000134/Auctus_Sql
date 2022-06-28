/*
需求人：葛笑节
需求：
1、取查询月份的所有出货单的“出货确认时间”
2、取出货单对应的SO交期或完工时间较晚的(SO行对应多个MO时，取最晚的完工报告与SO交期对比)
3、成品出货时间=条件1-条件2
*/
ALTER PROC sp_Auctus_ShipmentCostDays
(
@SD DATETIME='2022-04-01'
,@ED DATETIME='2022-04-30'
,@Org VARCHAR(1000)
)
AS
BEGIN 

--DECLARE @SD DATETIME='2022-04-01'
--,@ED DATETIME='2022-04-30'
--,@Org VARCHAR(1000)
IF ISNULL(@Org,'')=''
SET @Org=(SELECT CONVERT(VARCHAR(20),ID)+',' FROM dbo.Base_Organization FOR XML PATH(''))

;
WITH 
SMData AS
(
SELECT --TOP 10
a.ID,a.DocNo,b.DocLineNo,b.DemandCode
,a.ShipConfirmDate,b.ItemInfo_ItemCode,b.QtyPriceAmount
,CONVERT(DECIMAL(18,2),CASE WHEN a.Org=1001712010015192 THEN CONVERT(DECIMAL(18,10),dbo.fn_CustGetCurrentRate(a.AC,1,b.ShipConfirmDate,2)*b.FinallyPrice) 
	WHEN a.AC=1 THEN CONVERT(DECIMAL(18,10),b.FinallyPrice/(1+b.TaxRate)) 
	ELSE CONVERT(DECIMAL(18,10),a.ACToFCExRate*b.FinallyPrice)
	END*b.QtyPriceAmount) TotalAmount
,b.SrcDocNo SODocNo,b.SrcDocLineNo SODocLineNo,b.SrcDocSubLineNo SODocSubLineNo
FROM dbo.SM_Ship  a INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
WHERE a.ShipConfirmDate BETWEEN @SD AND @ED
AND PATINDEX('1%',b.ItemInfo_ItemCode)>0
AND a.Org IN (SELECT strid FROM dbo.fun_Cust_StrToTable(@Org))
),
MOData AS
(
SELECT a.DemandCode,MAX(rpt.CompleteDate)CompleteDate FROM dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster m ON a.Itemmaster=m.ID 
INNER JOIN dbo.MO_CompleteRpt rpt ON a.ID=rpt.MO
WHERE a.DemandCode IN (SELECT a.DemandCode FROM SMData a WHERE a.DemandCode!=-1)
AND PATINDEX('1%',m.Code)>0
GROUP BY a.DemandCode
)
,SOData AS
(
SELECT sm.*
,CASE WHEN c.DemandType=-1 OR ISNULL(mo.CompleteDate,'')='' THEN c.RequireDate 
WHEN DATEDIFF(HOUR,mo.CompleteDate,c.RequireDate)>0 THEN c.RequireDate ELSE mo.CompleteDate END ActualRequireDate
,c.RequireDate,mo.CompleteDate
,b.OrderByQtyTU 
,o1.Name OrgName
FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO
INNER JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
INNER JOIN SMData sm ON a.DocNo=sm.SODocNo AND b.DocLineNo=sm.SODocLineNo
AND c.DocSubLineNo=sm.SODocSubLineNo
LEFT JOIN MOData mo ON c.DemandType=mo.DemandCode
LEFT JOIN Base_Organization o ON a.Org=o.ID LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
)
SELECT 
a.OrgName,a.SODocNo+'-'+CONVERT(VARCHAR(10),a.SODocLineNo)+'-'+CONVERT(VARCHAR(10),a.SODocSubLineNo)SONo,a.SODocNo,a.SODocLineNo,a.SODocSubLineNo,a.OrderByQtyTU SOQty
,a.DocNo+'-'+CONVERT(VARCHAR(10),a.DocLineNo) SMDocNo,a.QtyPriceAmount SMQty,a.TotalAmount,a.ShipConfirmDate
,a.ActualRequireDate,a.RequireDate,a.CompleteDate,DATEDIFF(HOUR,a.ActualRequireDate,a.ShipConfirmDate)/24.00 UseDays
FROM SOData a
 
END