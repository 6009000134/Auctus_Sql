/*
标题:锁领料单BE插件
需求：信息部
作者:liufei
上线时间:2018-05
备注说明：


ADD(2018-11-23)：
1、不限制204010160料号领料
2、当供应的单据都是关闭或者完工状态，则允许直接领料。

ADD(2018-12-04)
1、不对拆卸领料单进行限制
ADD(2019-4-17)
总需求=实际需求量-备料单已发放数量
可领料数量=总需求-在途未回数量=可领料数量
假设备料单(同一需求分类号可能有多张)总需求4000，已发放1000，采购数量只转了800，且采购收货500，可领料数量=备料单实际需求量-已发放数量-未收货数量=4000-1000-(800-500)=2700

ADD(2019-7-26)
风险备料工单无需求分类号，直接放过
*/
ALTER PROC [dbo].[sp_Auctus_BE_MoIssueDoc]
(
@DocNo VARCHAR(50),
@BeforeConfirmDate VARCHAR(50),
@ConfirmDate VARCHAR(50),--@BeforeConfirmDate和@ConfirmDate值都为空时，执行的是添加BE
@Result NVARCHAR(MAX) OUT
)
AS 
BEGIN 
--生产领料

DECLARE @Num INT --物料不够数量
SET @Result='1'--赋值不可缺省


----关闭领料锁定功能
--RETURN;

--当@@BeforeConfirmDate和@@ConfirmDate不为空且值相等时，执行的是更新BE操作且领料单则为已发料状态，故不做校验
IF @BeforeConfirmDate=@ConfirmDate AND ISNULL(@BeforeConfirmDate,'')<>''--更新
RETURN ;

DECLARE @Mo NVARCHAR(50)
DECLARE @IssueDocType NVARCHAR(100)

SELECT @Mo=dbo.F_GetEnumName('UFIDA.U9.Base.Doc.BusinessTypeEnum',c.BusinessType,'zh-cn') FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocLine b ON a.ID=b.IssueDoc LEFT JOIN dbo.MO_MO c ON b.MO=c.ID
LEFT JOIN dbo.CBO_MrpInfo d ON b.Item=d.ItemMaster LEFT JOIN dbo.CBO_ItemMaster d1 ON b.Item=d1.ID
WHERE a.DocNo=@DocNo
AND d.DemandRule=0

SELECT @IssueDocType=b1.Name FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocType b ON a.IssueDocType=b.ID INNER JOIN dbo.MO_IssueDocType_Trl b1 ON b.ID=b1.ID
WHERE a.DocNo=@DocNo
AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'

--退料单和超领单不验证		
IF PATINDEX('%退料%',@IssueDocType)>0 OR @IssueDocType='超额特别领料单' OR @IssueDocType='拆卸领料单'
RETURN ;

IF ISNULL(@Mo,'')='返工生产'
RETURN ;


--SELECT docstate,WFCurrentState,WFOriginalState FROM dbo.MO_IssueDoc WHERE docno='LL-301810110002'

IF OBJECT_ID(N'tempdb.dbo.#tempCode',N'U') IS NULL
CREATE TABLE #tempCode(Item BIGINT,Code VARCHAR(50))
ELSE
TRUNCATE TABLE #tempCode
--获取领料单中需要严格匹配的料号集合
INSERT INTO #tempCode
SELECT b.Item,d1.Code FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocLine b ON a.ID=b.IssueDoc LEFT JOIN dbo.MO_MO c ON b.MO=c.ID
LEFT JOIN dbo.CBO_MrpInfo d ON b.Item=d.ItemMaster LEFT JOIN dbo.CBO_ItemMaster d1 ON b.Item=d1.ID
WHERE a.DocNo=@DocNo
AND d.DemandRule=0
AND d1.Code<>'204010160'

--获取需求分类号
DECLARE @DemandCode VARCHAR(50)
SELECT @DemandCode=c.DemandCode FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocLine b ON a.ID=b.IssueDoc LEFT JOIN dbo.MO_MO c ON b.MO=c.ID
WHERE a.DocNo=@DocNo

IF @DemandCode='-1'--风险备料工单无需求分类号
RETURN;


--mo与po供给集合
IF OBJECT_ID(N'tempdb.dbo.#tempSupply',N'U') IS NULL
CREATE TABLE #tempSupply(Code VARCHAR(50),DemandCode VARCHAR(10),TotalQty DECIMAL(18,0),SupplyQty DECIMAL(18,0),DocNo VARCHAR(50),IsClose CHAR(2))
ELSE
TRUNCATE TABLE #tempSupply


IF OBJECT_ID(N'tempdb.dbo.#tempLL',N'U') IS NULL
CREATE TABLE #tempLL(DocNo VARCHAR(50),Code VARCHAR(50),IssueQty DECIMAL(18,0),IssuedQty DECIMAL(18,0),DemandCode VARCHAR(20))
ELSE
TRUNCATE TABLE #tempLL

INSERT INTO #tempLL
SELECT a.DocNo,d.Code,b.IssueQty
,b.IssuedQty
,c.DemandCode
FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocLine b ON a.ID=b.IssueDoc 
LEFT JOIN MO_MO c ON b.MO=c.ID LEFT JOIN dbo.CBO_ItemMaster d ON b.Item=d.ID
LEFT JOIN dbo.MO_IssueDocType e ON a.IssueDocType=e.ID LEFT JOIN dbo.MO_IssueDocType_Trl e1 ON e.ID=e1.ID
LEFT JOIN dbo.CBO_MrpInfo f ON d.ID=f.ItemMaster
WHERE a.Org=1001708020135665
AND ISNULL(e1.SysMLFlag,'zh-cn')='zh-cn'
AND f.DemandRule=0
AND a.DocNo=@DocNo
AND d.Code IN (SELECT DISTINCT code FROM #tempCode)

IF (SELECT COUNT(*) FROM #tempLL)=0--当新生成的领料单中没有需要验证的料品时直接返回
RETURN

--生产订单做出来的半成品也算供应
;
WITH MO AS
(
SELECT b.Code,b.Name,a.ProductQty,a.TotalCompleteQty ,a.DemandCode,a.DocNo
,CASE WHEN a.DocState=3 THEN '1' ELSE '0' END IsColse
FROM dbo.MO_MO a INNER JOIN dbo.CBO_ItemMaster b ON a.ItemMaster=b.ID INNER JOIN #tempCode c ON b.Code=c.Code
WHERE a.DemandCode=@DemandCode
AND a.Cancel_Canceled=0
)
INSERT #tempSupply
SELECT a.Code,a.DemandCode,a.ProductQty,a.TotalCompleteQty
,a.DocNo,a.IsColse FROM MO a

--采购料品算供应
;
WITH PO AS
(
SELECT a.DocNo PoNo,b.DocLineNo PoLineNo,c.SubLineNo PoSubLineNo,c.DemondCode PO_DemandCode,c.ReqQtyTU
,c.ItemInfo_ItemCode,c.ItemInfo_ItemName ,c.SrcDocInfo_SrcDocNo,c.SrcDocInfo_SrcDocLineNo
,CASE  WHEN b.Status IN(3,4,5) THEN '1' ELSE '0' END IsClose
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder INNER JOIN #tempCode e ON b.ItemInfo_ItemCode=e.Code LEFT JOIN dbo.PM_POShipLine c ON b.ID=c.POLine
LEFT JOIN  dbo.CBO_MrpInfo d ON d.ItemMaster=c.ItemInfo_ItemID
WHERE b.Status IN(0,1,2,3,4,5,6,7,8)
AND a.Org=1001708020135665
AND d.DemandRule=0--严格按需求分类号匹配
AND c.DemondCode=@DemandCode
AND a.Cancel_Canceled=0
),
RCV AS
(
SELECT a.DocNo,b.DocLineNo--,c.ItemInfo_ItemCode cc
,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,b.SrcDoc_SrcDocNo,b.SrcDoc_SrcDocLineNo,b.SrcDoc_SrcDocSubLineNo ,b.ArriveQtyTU,b.RcvQtyTU
--,c.ReqQtyTU,c.PO_DemandCode
FROM dbo.PM_Receivement a INNER JOIN dbo.PM_RcvLine b ON a.ID=b.Receivement 
INNER JOIN PO c ON b.SrcDoc_SrcDocNo=c.PoNo AND b.SrcDoc_SrcDocLineNo=c.PoLineNo AND  b.SrcDoc_SrcDocSubLineNo=c.PoSubLineNo
WHERE a.Org=1001708020135665
)
INSERT INTO #tempSupply
SELECT a.ItemInfo_ItemCode,a.PO_DemandCode,MIN(a.ReqQtyTU),SUM(ISNULL(b.RcvQtyTU,0))RcvQtyTu,a.PoNo,a.IsClose
--,(SELECT c.PoNo+',' FROM PO c WHERE c.ItemInfo_ItemCode=a.ItemInfo_ItemCode AND c.PO_DemandCode=a.PO_DemandCode FOR XML PATH(''))PoNoList
FROM PO a LEFT JOIN RCV b ON b.SrcDoc_SrcDocNo=a.PoNo AND b.SrcDoc_SrcDocLineNo=a.PoLineNo AND  b.SrcDoc_SrcDocSubLineNo=a.PoSubLineNo
GROUP BY a.ItemInfo_ItemCode,a.PO_DemandCode,a.PoNo,a.IsClose

--如果所有供应的单据都已经是关闭/完工状态，则允许直接领料（若不加此逻辑，当供应小于需求时会导致无法领取库存）
IF(SELECT COUNT(*) FROM #tempSupply WHERE IsClose='0')=0
RETURN;

DECLARE @MODoc VARCHAR(50)=(SELECT distinct c.DocNo FROM dbo.MO_IssueDoc a INNER JOIN dbo.MO_IssueDocLine b ON a.ID=b.IssueDoc AND a.DocNo=@DocNo INNER JOIN dbo.MO_MO c ON b.MO=c.ID)


DECLARE @Docs2 NVARCHAR(MAX)
;
WITH Supply AS--供应
(
SELECT a.Code,a.DemandCode,SUM(a.TotalQty)TotalQty,SUM(a.SupplyQty)SupplyQty 
,(SELECT b.DocNo+',' FROM #tempSupply b WHERE b.DemandCode=a.DemandCode AND b.Code=a.Code FOR XML PATH(''))DocList 
FROM #tempSupply a GROUP BY a.DemandCode,a.Code
),
Demand AS--需求
(
SELECT a.Code,SUM(a.IssueQty)IssueQty,SUM(a.IssuedQty)IssuedQty FROM #tempLL a
GROUP BY a.DemandCode,a.Code
),
MOPickList AS
(
SELECT c.Code,c.Name,SUM(a.ActualReqQty-ISNULL(a.IssuedQty,0))ActualReqQty FROM dbo.MO_MOPickList a INNER JOIN dbo.MO_MO b ON a.MO=b.ID AND b.DocNo=@MODoc INNER JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID
GROUP BY c.Code,c.Name
)
SELECT @Docs2=(
SELECT 
a.Code+'：领料数量'+CONVERT(VARCHAR(50),a.IssuedQty)+',最多可领数量'+CONVERT(VARCHAR(50),c.ActualReqQty+ISNULL(b.SupplyQty,0) -ISNULL(b.TotalQty,0))+',订单列表：'+b.DocList
FROM Demand a left JOIN Supply b ON a.Code=b.Code LEFT JOIN MOPickList c ON a.Code=c.Code
WHERE a.IssuedQty>c.ActualReqQty+ISNULL(b.SupplyQty,0) -ISNULL(b.TotalQty,0)
FOR XML PATH('')) 

IF ISNULL(@Docs2,'')<>''
SET @Result=@Docs2
ELSE	
SET @Result='1'
END 








