/*
计算未交SO\FO原材料毛需求
显示对应在途、在检、在库数量
*/
ALTER PROC sp_Auctus_GetGrossDemandQty
(
@Org BIGINT
)
AS

--DECLARE @Org BIGINT=1001708020135665
 IF object_id('tempdb.dbo.#tempDoc') is NULL
 BEGIN
	CREATE TABLE #tempDoc
	(
	DocNo VARCHAR(20),
	DocType VARCHAR(100),
	Status INT,
	StatusName VARCHAR(20),
	DocLineNo INT,
	LineStatus INT,
	LineStatusName VARCHAR(20),
	ItemInfo_ItemID BIGINT,
	OrderByQty INT,
	UnDeliveryQty int
	)
 END 
 ELSE
 BEGIN
	TRUNCATE TABLE #tempDoc
 END 
 IF object_id('tempdb.dbo.#tempReqInfo') is NULL
 BEGIN
	CREATE TABLE #tempReqInfo
	(
	MID BIGINT,
	UseCode VARCHAR(100),
	ReqQty INT
	)
 END 
 ELSE
 BEGIN
	TRUNCATE TABLE #tempReqInfo
 END 
;
WITH 
SOData AS
(
SELECT a.DocNo,a.DocumentType,a.Org,a.Cancel_Canceled,a.Status,b.DocLineNo,b.Status LineStatus,b.ItemInfo_ItemID,b.OrderByQtyTU 
,b.SrcDocNo,b.SrcDocLineNo,b.SrcDocType--预测订单：10
FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO
INNER JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
WHERE 1=1
AND a.Org=1001708020135665
--AND a.Org=@Org
),
ShipData AS
(
SELECT a.ID,a.DocNo,a.Org,b.DocLineNo,b.ItemInfo_ItemID,b.QtyPriceAmount,b.SrcDocNo,b.SrcDocLineNo 
FROM dbo.SM_Ship a INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship
),
SO AS--未交销售订单
(
SELECT a.DocNo,sd1.Name DocType,a.Status,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',a.Status,'zh-cn')StatusName 
,a.DocLineNo,a.LineStatus,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',a.LineStatus,'zh-cn')LineStatusName
,a.ItemInfo_ItemID,a.OrderByQtyTU,a.OrderByQtyTU-ISNULL((SELECT SUM(sm.QtyPriceAmount) FROM ShipData sm WHERE a.DocNo=sm.SrcDocNo AND a.DocLineNo=sm.SrcDocLineNo ),0) UnDeliverQty
FROM SOData a LEFT JOIN dbo.SM_SODocType_Trl sd1 ON a.DocumentType=sd1.ID AND sd1.SysMLFlag='zh-cn'
WHERE a.OrderByQtyTU>ISNULL((SELECT SUM(sm.QtyPriceAmount) FROM ShipData sm WHERE a.DocNo=sm.SrcDocNo AND a.DocLineNo=sm.SrcDocLineNo ),0)
and a.Status IN (1,2,3) AND a.LineStatus IN (1,2,3)--3：审核
AND a.Cancel_Canceled=0
--AND a.Org=@Org
AND a.Org=1001708020135665
--AND b.ItemInfo_ItemCode='101010214'
--SELECT sd1.Name,a.DocNo,a.Org,a.Cancel_Canceled,a.Status,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',a.Status,'zh-cn')StatusName,
--b.DocLineNo,b.Status LineStatus,dbo.F_GetEnumName('UFIDA.U9.SM.SO.SODocStatusEnum',b.Status,'zh-cn')LineStatusName,b.ItemInfo_ItemID,b.OrderByQtyTU 
--,b.OrderByQtyTU -ISNULL((SELECT SUM(sm.QtyPriceAmount) FROM ShipData sm WHERE a.DocNo=sm.SrcDocNo AND b.DocLineNo=sm.SrcDocLineNo ),0)UnShipQty
--FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO INNER JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
--LEFT JOIN dbo.SM_SODocType_Trl sd1 ON a.DocumentType=sd1.ID AND sd1.SysMLFlag='zh-cn'
--WHERE b.OrderByQtyTU>ISNULL((SELECT SUM(sm.QtyPriceAmount) FROM ShipData sm WHERE a.DocNo=sm.SrcDocNo AND b.DocLineNo=sm.SrcDocLineNo ),0)
--and a.Status IN (1,2,3) AND b.Status IN (1,2,3)--3：审核
--AND a.Cancel_Canceled=0
----AND a.Org=@Org
--AND a.Org=1001708020135665
----AND b.ItemInfo_ItemCode='101010214'
),
FO AS
(
SELECT a.DocNo,d1.Name DocType,a.Status,dbo.F_GetEnumName('UFIDA.U9.SM.ForecastOrder.ForecastOrderStatusEnum',a.Status,'zh-cn')StatusName,b.DocLineNo,b.Status LineStatus,dbo.F_GetEnumName('UFIDA.U9.SM.ForecastOrder.ForecastOrderStatusEnum',b.Status,'zh-cn')LineStatusName ,b.ItemInfo_ItemID
,b.Num,b.Num-ISNULL((SELECT SUM(s.OrderByQtyTU) FROM SOData s WHERE s.SrcDocNo=a.DocNo AND s.SrcDocLineNo=b.DocLineNo AND s.SrcDocType=10),0)UnTurnSOQty
FROM dbo.SM_ForecastOrder a INNER JOIN dbo.SM_ForecastOrderLine b ON a.ID=b.ForecastOrder
LEFT JOIN dbo.SM_ForecastOrderDocType_Trl d1 ON a.DocmentType=d1.ID AND d1.SysMLFlag='zh-cn'
WHERE 
b.Num-ISNULL((SELECT SUM(s.OrderByQtyTU) FROM SOData s WHERE s.SrcDocNo=a.DocNo AND s.SrcDocLineNo=b.DocLineNo AND s.SrcDocType=10),0)>0
AND a.Status=2
AND b.Status=2
AND a.Cancel_Canceled=0
AND a.Org=@Org
) INSERT INTO #tempDoc
        ( DocNo ,
          DocType ,
          Status ,
          StatusName ,
          DocLineNo ,
          LineStatus ,
          LineStatusName ,
          ItemInfo_ItemID ,
          OrderByQty ,
          UnDeliveryQty
        )
SELECT * FROM SO
UNION ALL
SELECT * FROM FO

;
WITH BOMData AS
(
SELECT a.*,c.MasterCode,c.pid,c.mid,c.Code UseCode,c.ThisUsageQty 
FROM #tempDoc a
INNER JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID AND m.Org=1001708020135665 --AND m.Org=@Org 
INNER JOIN (SELECT * FROM dbo.Auctus_NewestBom a WHERE a.Org=1001708020135665 
AND NOT EXISTS(SELECT 1 FROM dbo.Auctus_NewestBom t WHERE t.PID=a.mid AND t.MasterCode=a.MasterCode)
AND a.ComponentType=0
) c ON m.Code=c.MasterCode
),
ReqInfo AS
(
SELECT a.MID,a.UseCode,SUM(a.unDeliveryQty*a.ThisUsageQty)ReqQty
FROM BOMData a GROUP BY a.UseCode,a.MID
)
INSERT INTO #tempReqInfo
        ( MID, UseCode, ReqQty )
SELECT * FROM ReqInfo
;
WITH WH AS
(
SELECT
a.Orgcode,a.Code,SUM(a.BalQty)BalQty
FROM dbo.v_Cust_InvInfo4OA a 
WHERE a.StorageType='可用' 
AND a.OrgID=1001708020135665
AND a.OrgID=@Org
AND a.BalQty>0
GROUP BY a.OrgCode,a.Code
),
PurchaseInfo AS
(
SELECT 
a.ID,a.DocNo,b.DocLineNo,b.ItemInfo_ItemID,b.SupplierConfirmQtyTU,c.DeficiencyQtyTU
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE a.org=1001708020135665 --a.Org=@Org
AND b.Status=2
),
RCVInfo AS
(
SELECT
a.ID,a.DocNo,b.DocLineNo,b.ItemInfo_ItemID,CASE WHEN a.ReceivementType=0 THEN b.RcvQtyTU ELSE (-1)*a.ReceivementType END RcvQtyTU 
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement 
WHERE a.org=1001708020135665 --a.Org=@Org
AND a.Status!=5
)
SELECT 
mrp.Name MRP分类
,cat.Code 主分类编码
,cat1.Name 主分类
,m.Code 料号
,m.Name 品名
,CONVERT(INT,a.ReqQty)需求数量 
,CONVERT(INT,b.DeficiencyQtyTU)欠交数量 
,CONVERT(INT,c.RcvQtyTU)在检数量
,CONVERT(INT,d.BalQty)库存可用量
FROM #tempReqInfo a 
LEFT JOIN (SELECT t.ItemInfo_ItemID,SUM(t.DeficiencyQtyTU)DeficiencyQtyTU FROM PurchaseInfo t GROUP BY t.ItemInfo_ItemID) b ON a.mid=b.ItemInfo_ItemID
LEFT JOIN (SELECT t.ItemInfo_ItemID,SUM(t.RcvQtyTU)RcvQtyTU FROM RCVInfo t GROUP BY t.ItemInfo_ItemID) c ON a.MID=c.ItemInfo_ItemID
LEFT JOIN WH d ON a.UseCode=d.Code
LEFT JOIN dbo.CBO_ItemMaster m ON a.MID=m.ID
LEFT JOIN dbo.vw_MRPCategory mrp ON m.DescFlexField_PrivateDescSeg22=mrp.Code
LEFT JOIN CBO_Category cat ON m.MainItemCategory=cat.ID LEFT JOIN dbo.CBO_Category_Trl cat1 ON cat.ID=cat1.ID AND cat1.SysMLFlag='zh-cn'
--WHERE a.MID=ISNULL(@ItemID,a.MID)
--欠交数量不包含在检数量 RcvQty

/*
102020012
102020013
102020050
*/





