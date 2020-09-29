/*
标题:收货单BE
需求：信息部
作者:liufei
开发时间：2018-12-10
上线时间:
备注说明：
采购或委外收货时按物料分类限制提前收货期：包材3天、结构、SMT 10天。若超过提前天数，则需要走审批流.

ADD(2018-12-11)
修改逻辑：DescFlexField_PrivateDescSeg1  0-不走高级审批流 1-电子料审批流（季总审批） 2-包材、结构、结构委外、SMT（罗总审批）
电子料30天提前期，包材从3天改为4天

ADD(2018-12-12)
修改逻辑：在收货单提收货时的时候增加提前收货料品总金额，根据金额（2万以下，2-5万，5万以上）数量走另一个审批流程，先走提前流程，再走金额流程

ADD(2019-3-5)
1、包材从提前4天改成提前10天
2、结构\PCBA从提前10天改成15天
3、流程修改为：
	1、正常：账务员制单-->IQC-->仓管员-->知会采购
    2、提前进料5万以下：账务员制单-->供应链经理  + IQC-->仓管员-->知会采购
    3、提前进料5万以上：账务员制单--> 供应链经理 -->生产总监-->总经理  + IQC-->仓管员-->知会采购、总经理；	

ADD(2019-4-22)蔡总
提前时间改成：电子料30天、结构15天、包材7天，单据金额从5万改成1万,SMT板不管控
ADD(2019-8-21)
原逻辑：电子提前30天以上、结构\结构委外提前15天以上、包材提前7天以上需要汇总金额走对应的审批流程
    现修改逻辑如下：
    当料品有维护“可进料提前天数”时，取料品维护的档案，若没有维护料品数据，则按原逻辑进行提前天数比较！
    例如：电子料A有维护“可进料提前天数”为10天，当此料号提前10天以上进行收货时，需走审批流
               电子料B没有维护“可进料提前天数”，则电子料B按原逻辑，提前30天以上进行收货时，需走审批流

Update(2019-9-25)需求逻辑修改
1、当料号A制作收货单时，计算“当前收货总数”=料号A当天总收货数量+在检数量
    2、计算料号A需求日期：“需求日期”=当天日期+料号A“可提前天数”或“采购后提前期”，优先取“可提前天数”，当两个数据都没有维护时，则根据MRP分类来抓取可提前天数：电子30天，结构、结构委外15天，包材7天。
    3、根据当天推送的8周欠料邮件数据，汇总料号A在"需求日期"内“欠料数量”，“若欠料数量”>“当前收货总数”，则不需要进行提前收货审批，反之则需进行提前收货审批。

举例：今天（2019-09-20）料号A收货10K，在检数量5K，料号A可提前进料天数为10天时，根据8周欠料邮件数据汇总得出2019-09-30（2019-09-20+10天）号之前料号A欠料20K，10K+5K<20K，料号A不算提前收货。

update(2019-10-15)逻辑修改
收货的“需求日期”=当前日期+可提前天数
若收货超过需求，超出部分在1个mpq之内，则允许。例如：收货10K，欠料9.5K，料品MPQ为1K，则欠料9.5K要是MPQ的倍数，进一法即允许收货10K。

update(2019-11-29)
将具体提前收货的料品信息更新到收货行
*/
ALTER PROC [dbo].[sp_Auctus_OA_Receivement]
(
@DocNo VARCHAR(50)
)
AS


BEGIN

SET NOCOUNT ON--此句不能取消，否转影响OA调用

DECLARE @Org BIGINT=1001708020135665
--DECLARE @DocNo VARCHAR(50)=''
DECLARE @IsAdvance INT=0--是否提前了：0-未提前,1-提前了
DECLARE @TotalMoney DECIMAL(18,2)--是否提前了：0-未提前,1-提前了

--关闭功能308010656
--RETURN ;

DECLARE @IsReceivement INT=0 --是否为标准收货单或者委外收货单
SELECT @IsReceivement=
CASE WHEN a.ReceivementType=0 AND a.BizType IN (316, 322, 328, 321) AND a.IsInitEvaluation=0 THEN 1--标准收货
WHEN a.ReceivementType=0 AND a.BizType IN ((-1), 325, 326)  THEN 1--委外收货
else 0 END 
FROM dbo.PM_Receivement a WHERE a.DocNo=@DocNo
IF @IsReceivement=0--非标准收货或委外收货直接返回
BEGIN
	SELECT '0' Result,'未提前' Msg
	RETURN;
END 
	

--DECLARE @Today DATE=DATEADD(DAY,-1,GETDATE());
--DECLARE @Today DATE='2019-09-09';
DECLARE @Today DATE=CONVERT(DATE,GETDATE());

IF OBJECT_ID(N'tempdb.dbo.#tempResult',N'U') IS NULL
BEGIN
	CREATE TABLE #tempResult 
	(Itemmaster bigint,TotalRcvQty int,MRPFlag INT,TotalLackAmount INT,TotalTodayRcv INT,TotalCheckingRcv INT,TotalReturnRcv INT,SafeQty INT)
END 
ELSE
BEGIN
	TRUNCATE TABLE #tempResult
END 

--以下With中统一按料号汇总收货数量
;
WITH currentRcv AS--当前订单
(
SELECT b.ItemInfo_ItemID,MIN(ISNULL(b.ConfirmDate,GETDATE()))ConfirmDate,SUM(b.RcvQtyTU)TotalRcvQty
,MIN(m.DescFlexField_PrivateDescSeg22)MRPCategory
,MIN(ISNULL(b.ConfirmDate,GETDATE())+CONVERT(INT,m.DescFlexField_PrivateDescSeg29))DeadLine
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
LEFT JOIN dbo.CBO_ItemMaster m ON b.ItemInfo_ItemID=m.ID
LEFT JOIN dbo.CBO_MrpInfo mrp ON b.ItemInfo_ItemID=mrp.ItemMaster
WHERE a.ReceivementType=0
AND a.DocNo=@DocNo 
GROUP BY b.ItemInfo_ItemID
),
LackData AS
(
SELECT a.ItemMaster,a.ActualReqDate,a.LackAmount*(-1)LackAmount FROM dbo.Auctus_FullSetCheckResult8 a WHERE CONVERT(DATE,a.CopyDate)=@Today AND a.IsLack='缺料'
),
CurrentData AS
(
SELECT a.ItemInfo_ItemID,a.TotalRcvQty
,MIN(a.MRPCategory)MRPCategory
,SUM(ISNULL(c.LackAmount,0))TotalLackAmount
--,c.*
FROM currentRcv a
LEFT JOIN LackData c ON a.ItemInfo_ItemID=c.ItemMaster AND c.ActualReqDate<a.DeadLine
GROUP BY a.ItemInfo_ItemID,a.TotalRcvQty
),
todayRcv AS--今日确认收货单（排除当前@DocNo订单）
(
SELECT b.ItemInfo_ItemID,SUM(b.RcvQtyTU)TotalTodayRcv
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement INNER JOIN currentRcv c ON b.ItemInfo_ItemID=c.ItemInfo_ItemID
WHERE CONVERT(DATE,b.ConfirmDate)=@Today 
AND a.ReceivementType=0 
AND a.DocNo<>@DocNo
GROUP BY b.ItemInfo_ItemID
),
CheckingRcv AS--在检收货单
(
SELECT b.ItemInfo_ItemID,SUM(b.RcvQtyTU)TotalCheckingRcv
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement INNER JOIN currentRcv c ON b.ItemInfo_ItemID=c.ItemInfo_ItemID
WHERE a.Status IN (0,3) 
AND a.ReceivementType=0
AND a.DocNo<>@DocNo
GROUP BY b.ItemInfo_ItemID
),
ReturnRcv AS--当天退货的数量(审核后才会扣减库存可用量)
(
SELECT b.ItemInfo_ItemID,SUM(b.RcvQtyTU)TotalReturnRcv
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement INNER JOIN currentRcv c ON b.ItemInfo_ItemID=c.ItemInfo_ItemID
WHERE a.ReceivementType=1 AND CONVERT(DATE,b.ConfirmDate)=@Today
AND a.Status=5 AND b.status=5
GROUP BY b.ItemInfo_ItemID
)
INSERT INTO #tempResult
        ( Itemmaster ,
          TotalRcvQty ,
          MRPFlag ,
          TotalLackAmount ,
          TotalTodayRcv ,
          TotalCheckingRcv ,
          TotalReturnRcv,
		  SafeQty
        )
SELECT a.ItemInfo_ItemID,a.TotalRcvQty,
CASE WHEN a.MRPCategory='MRP104' THEN 1 --电子
WHEN (a.MRPCategory='MRP106' OR a.MRPCategory='107')  THEN 2--结构、结构委外
WHEN a.MRPCategory='MRP105'  THEN 3--包材
ELSE 0 END 
,ISNULL(a.TotalLackAmount,0)
,ISNULL(b.TotalTodayRcv,0)TotalTodayRcv,ISNULL(c.TotalCheckingRcv,0)TotalCheckingRcv,ISNULL(d.TotalReturnRcv,0)TotalReturnRcv
,ISNULL(e.SafetyStockQty,0)
--,m.Code,m.Name
FROM CurrentData a LEFT JOIN todayRcv b ON a.ItemInfo_ItemID=b.ItemInfo_ItemID LEFT JOIN CheckingRcv c ON a.ItemInfo_ItemID=c.ItemInfo_ItemID
LEFT JOIN ReturnRcv d ON a.ItemInfo_ItemID=d.ItemInfo_ItemID
LEFT JOIN dbo.CBO_ItemMaster m ON a.ItemInfo_ItemID=m.ID
LEFT JOIN dbo.CBO_InventoryInfo e ON a.ItemInfo_ItemID=e.ItemMaster
LEFT JOIN dbo.CBO_PurchaseInfo p ON a.ItemInfo_ItemID=p.ItemMaster
--当前订单收货数量+今日已收货数量+在检数量>缺料数量+退货数量+安全库存。若收货超过需求，超出部分在1个mpq之内，则允许
WHERE (a.TotalRcvQty+ISNULL(b.TotalTodayRcv,0)+ISNULL(c.TotalCheckingRcv,0))>(ISNULL(a.TotalLackAmount,0)+ISNULL(d.TotalReturnRcv,0))+ISNULL(e.SafetyStockQty,0)
+((ISNULL(a.TotalLackAmount,0)+ISNULL(d.TotalReturnRcv,0))+ISNULL(e.SafetyStockQty,0))%(CASE WHEN ISNULL(p.PurchaseBatchQty,0)=0 THEN 1 ELSE p.PurchaseBatchQty END)

SELECT @IsAdvance=ISNULL(max(c.MRPFlag),0),@TotalMoney=ISNULL(SUM(ISNULL(b.TotalNetMnyFC,0)),0)
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement INNER JOIN #tempResult c ON b.ItemInfo_ItemID=c.Itemmaster
AND a.DocNo=@DocNo

IF ISNULL(@IsAdvance,0)=0--正常
BEGIN
SET @IsAdvance=0
SET @TotalMoney=0
SELECT '0' Result,'未提前' Msg
return
END 
ELSE
BEGIN--将提前收货信息更新到收货行
DECLARE @Result CHAR(1)=''
IF @IsAdvance=1 AND ISNULL(@TotalMoney,0)<=1000--提前收料，且金额小于10000
SET @Result='1'
IF @IsAdvance=1 AND ISNULL(@TotalMoney,0)>1000 AND ISNULL(@TotalMoney,0)<=10000--提前收料，且金额小于10000
SET @Result='2'
ELSE IF @IsAdvance=1 AND ISNULL(@TotalMoney,0)>10000--提前收料，且金额大于等于10000
SET @Result='3'
ELSE IF @IsAdvance=2 AND ISNULL(@TotalMoney,0)<=1000
SET @Result='4'
ELSE IF @IsAdvance=2 AND ISNULL(@TotalMoney,0)>1000 AND ISNULL(@TotalMoney,0)<=10000
SET @Result='5'
ELSE IF @IsAdvance=2 AND ISNULL(@TotalMoney,0)>10000
SET @Result='6'
ELSE IF @IsAdvance=3 AND ISNULL(@TotalMoney,0)<=1000
SET @Result='7'
ELSE IF @IsAdvance=3 AND ISNULL(@TotalMoney,0)>1000 AND ISNULL(@TotalMoney,0)<=10000
SET @Result='8'
ELSE IF @IsAdvance=3 AND ISNULL(@TotalMoney,0)>10000
SET @Result='9'

SELECT @Result Result,
(SELECT '料号：'+b.ItemInfo_ItemCode+'当前收货数量：'+CONVERT(VARCHAR(20),c.TotalRcvQty)+',8周需求：'+CONVERT(VARCHAR(20),c.TotalLackAmount)+',当日收货数量：'+CONVERT(VARCHAR(20),c.TotalTodayRcv)+',当前在检数量：'+CONVERT(VARCHAR(20),c.TotalCheckingRcv)+',当日退货数量:'+CONVERT(VARCHAR(20),c.TotalReturnRcv)+',安全库存：'+CONVERT(VARCHAR(20),c.SafeQty) 
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement INNER JOIN #tempResult c ON b.ItemInfo_ItemID=c.Itemmaster
WHERE a.DocNo=@DocNo FOR XML PATH('')) Msg

END 



END
