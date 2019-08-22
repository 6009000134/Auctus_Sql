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
*/
ALTER PROC [dbo].[sp_Auctus_BE_Receivement]
(
@DocNo VARCHAR(50)
)
AS
BEGIN
DECLARE @Org BIGINT=1001708020135665
--DECLARE @DocNo VARCHAR(50)
--SET @DocNo='RCV30180420009'
DECLARE @IsAdvance INT=0--是否提前了：0-未提前,1-提前了
DECLARE @TotalMoney DECIMAL(18,2)--是否提前了：0-未提前,1-提前了

--关闭功能
--RETURN ;

DECLARE @IsReceivement INT=0 --是否为标准收货单或者委外收货单
SELECT @IsReceivement=
CASE WHEN a.ReceivementType=0 AND a.BizType IN (316, 322, 328, 321) AND a.IsInitEvaluation=0 THEN 1--标准收货
WHEN a.ReceivementType=0 AND a.BizType IN ((-1), 325, 326)  THEN 1--委外收货
else 0 END 
FROM dbo.PM_Receivement a WHERE a.DocNo=@DocNo

IF @IsReceivement=0--非标准收货或委外收货直接返回
RETURN;

--SELECT * FROM dbo.auctus_test
INSERT INTO auctus_test VALUES(@DocNo)

;
WITH Receivement AS--收货单
(
SELECT a.DocNo,a.BusinessDate,a.ApprovedOn,b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo
,c.DescFlexField_PrivateDescSeg22 MRPCategory,CONVERT(INT,ISNULL(c.DescFlexField_PrivateDescSeg29,0)) AdvaceDays
,b.FinallyPriceAC*b.RcvQtyTU*a.ACToFCExRate/(1+b.TaxRate) TotalNetMnyAC--单价*实收数量*汇率
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement
LEFT JOIN dbo.CBO_ItemMaster c ON b.ItemInfo_ItemID=c.ID
WHERE a.DocNo=@DocNo
AND a.Org=@Org
),
PO AS--采购单
(
SELECT a.DocNo,b.DocLineNo,c.SubLineNo,c.DeliveryDate
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder INNER JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
WHERE a.Org=@Org
),
Result AS--收货单与采购单关联
(
SELECT a.*,ISNULL(b.DeliveryDate,a.BusinessDate)DeliveryDate
,DATEDIFF(HOUR,a.BusinessDate,ISNULL(b.DeliveryDate,a.BusinessDate))/24.00 Duration--提前时间
FROM Receivement a LEFT JOIN PO b ON a.SrcDoc_SrcDocNo=b.DocNo AND a.SrcDoc_SrcDocLineNo=b.DocLineNo AND a.SrcDoc_SrcDocSubLineNo=b.SubLineNo
),
Result2 AS
(
SELECT *
,CASE WHEN a.Duration>CASE WHEN a.AdvaceDays=0 THEN 30 ELSE a.AdvaceDays END AND a.MRPCategory='MRP104' THEN 1 --电子
WHEN  A.Duration>CASE WHEN a.AdvaceDays=0 THEN 15 ELSE a.AdvaceDays END AND (a.MRPCategory='MRP106' OR a.MRPCategory='107')  THEN 2--结构、结构委外
WHEN a.Duration>CASE WHEN a.AdvaceDays=0 THEN 7 ELSE a.AdvaceDays END  AND a.MRPCategory='MRP105'  THEN 3--包材
ELSE 0 END IsAdvance--提前标识：0\未提前，1\电子料提前，2\结构、结构委外,3\包材
FROM Result a
)
SELECT @IsAdvance=MAX(a.IsAdvance),@TotalMoney=SUM(a.TotalNetMnyAC) FROM Result2 a
WHERE a.IsAdvance>0

IF ISNULL(@IsAdvance,0)=0--正常
BEGIN
SET @IsAdvance=0
SET @TotalMoney=0
UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1=@IsAdvance,DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
END 
ELSE IF @IsAdvance=1 AND ISNULL(@TotalMoney,0)<10000--提前收料，且金额小于10000
UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='1',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
ELSE IF @IsAdvance=1 AND ISNULL(@TotalMoney,0)>=10000--提前收料，且金额大于等于10000
UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='2',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
ELSE IF @IsAdvance=2 AND ISNULL(@TotalMoney,0)<10000
UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='3',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
ELSE IF @IsAdvance=2 AND ISNULL(@TotalMoney,0)>=10000
UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='4',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
ELSE IF @IsAdvance=3 AND ISNULL(@TotalMoney,0)<10000
UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='5',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
ELSE IF @IsAdvance=3 AND ISNULL(@TotalMoney,0)>=10000
UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='6',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo


--2019-4-22之前的逻辑Start
--IF ISNULL(@IsAdvance,0)=0--正常
--BEGIN
--SET @IsAdvance=0
--SET @TotalMoney=0
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1=@IsAdvance,DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
--END 
--ELSE IF (ISNULL(@IsAdvance,0)=1 OR ISNULL(@IsAdvance,0)=2) AND ISNULL(@TotalMoney,0)<10000--提前收料，且金额小于等于50000
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='1',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
--ELSE IF (ISNULL(@IsAdvance,0)=1 OR ISNULL(@IsAdvance,0)=2) AND ISNULL(@TotalMoney,0)>=10000--提前收料，金额大于50000
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='2',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo


--2019-3-5之前的逻辑Start

--当没有提前收货料号时，赋值
--IF ISNULL(@IsAdvance,0)=0
--BEGIN
--SET @IsAdvance=0
--SET @TotalMoney=0
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1=@IsAdvance,DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
--END 
--ELSE IF ISNULL(@IsAdvance,0)=1 AND ISNULL(@TotalMoney,0)<=20000
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='1',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
--ELSE IF ISNULL(@IsAdvance,0)=1 AND ISNULL(@TotalMoney,0)<=50000 AND ISNULL(@TotalMoney,0)>20000
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='2',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
--ELSE IF ISNULL(@IsAdvance,0)=1 AND ISNULL(@TotalMoney,0)>50000
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='3',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
--ELSE IF ISNULL(@IsAdvance,0)=2 AND ISNULL(@TotalMoney,0)<=20000
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='4',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
--ELSE IF ISNULL(@IsAdvance,0)=2 AND ISNULL(@TotalMoney,0)<=50000 AND ISNULL(@TotalMoney,0)>20000
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='5',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo
--ELSE IF ISNULL(@IsAdvance,0)=2 AND ISNULL(@TotalMoney,0)>50000
--UPDATE dbo.PM_Receivement SET DescFlexField_PrivateDescSeg1='6',DescFlexField_PrivateDescSeg2=@TotalMoney WHERE DocNo=@DocNo

--2019-3-5之前的逻辑End

END 


