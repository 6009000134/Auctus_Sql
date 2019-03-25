/*
标题:限制标准\委外采购数量，锁WMO转委外
需求：PMC\采购
作者:liufei
上线时间:2018-08-22
逻辑：
锁300组织转委外工单
开发工单转委外BE插件
1、查出库存在手量 可用的
2、检查工单转委外的数量是否有库存
3、检查已存在的委外订单是否有欠料（即已发数量=实际需求量）
4、每个委外商可以有一张未发料的委外单存在（之前是所有委外商只有1张未发料的委外单存在）
ADD(2018-12-06)林炳煌
1、不控制伟丰转单

ADD(2018-12-14)
限制标准\委外采购数量：插件限制采购数量不能大于需求量（需考虑最小包装量。如：需求量860 最小包装量 100 采购数量为900正常 采购数量为1000不允许保存
1、采购数量>需求数量
2、采购数量-需求数量<MPQ（供应商料品交叉最小叫货量）

*/
--采购订单BE插件
ALTER PROC [dbo].[sp_Auctus_BE_PurchaseOrderAU]
(
@DocNo VARCHAR(50),
@Result NVARCHAR(max) out--结果:1\不需要校验
)
AS
BEGIN

--DECLARE @Result NVARCHAR(max)='1'
--DECLARE @DocNo VARCHAR(50)
--SET @DocNo='PO30170815002'

DECLARE @w VARCHAR(20)--委外仓库关键字
DECLARE @company NVARCHAR(255)--委外商名称
DECLARE @Org BIGINT=1001708020135665--300组织ID
DECLARE @Wh VARCHAR(100)--锁委外验证：仓库编码
DECLARE @WPOList VARCHAR(MAX)--锁委外验证：未发料的委外订单号
DECLARE @codeList NVARCHAR(MAX)--锁委外验证：待转订单库存不够的料号集合

SET @Result='1'
--RETURN;--关闭验证功能


--判断订单是不是标准采购或委外采购单
DECLARE @IsPO INT=0 --是否为标准采购单或者委外采购
SELECT @IsPO=
CASE WHEN  a.BizType IN (316, 317, 318, 319, 320, 321,327, 328) AND b.[IsFillin]='false' AND b.[IsInitPO]='false'  THEN 1--标准采购
WHEN  a.BizType IN ( 325, 326) AND b.[IsFillin]='false' AND b.[IsInitPO]='false'  THEN 2--委外采购
else 0 END 
FROM PM_PurchaseOrder a LEFT JOIN PM_PODocType b ON  a.DocumentType=b.ID
WHERE a.DocNo=@DocNo 

IF @IsPO=0--非标准采购或委外采购单直接返回
RETURN;



IF OBJECT_ID('tempdb.dbo.#tempResult','U') IS NOT NULL
DROP TABLE #tempResult

;
WITH SupplierItem AS--供应商料品交叉待修改
(
SELECT a.ID,a.CreatedOn,a.ModifiedOn,a.Org,a.ItemInfo_ItemID,a.ItemInfo_ItemCode,a.ItemInfo_ItemName
,CASE WHEN ISNULL(a.MinOrderQty,0)=0 THEN 1
else a.MinOrderQty END  MinOrderQty--,a.MinOrderQty
,b1.Name SupplierName,a.SupplierInfo_Supplier Supplier,b.Org SupplierOrg
,ROW_NUMBER()OVER(PARTITION BY a.ItemInfo_ItemCode ORDER BY a.ModifiedOn desc)RN
FROM dbo.CBO_SupplierItem a 
LEFT JOIN dbo.CBO_Supplier b ON a.SupplierInfo_Supplier=b.ID LEFT JOIN dbo.CBO_Supplier_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE 1=1 AND a.Org=1001708020135665 --AND b.Org=1001708020135665
AND a.Effective_IsEffective=1 AND b.Effective_IsEffective=1
),
PO AS
(
SELECT a.DocNo,b.DocLineNo,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,b.ReqQtyPU--需求计价单位数量
,b.PurQtyTU--采购数量1
,a.Supplier_Supplier
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
WHERE 1=1 AND a.DocNo=@DocNo
),
Result AS
(
SELECT a.*,b.MinOrderQty
,a.ReqQtyPU%b.MinOrderQty QtyLeave
,CASE WHEN a.ReqQtyPU%b.MinOrderQty=0 THEN a.ReqQtyPU
ELSE a.ReqQtyPU+(b.MinOrderQty-a.ReqQtyPU%b.MinOrderQty) END CorrectQty
,ROW_NUMBER()OVER(PARTITION BY a.DocLineNo,b.ItemInfo_ItemCode ORDER BY b.ModifiedOn desc) rn
FROM PO a LEFT JOIN SupplierItem b ON a.ItemInfo_ItemCode=b.ItemInfo_ItemCode AND a.Supplier_Supplier=b.Supplier
)
SELECT * 
,CASE WHEN a.PurQtyTU<a.ReqQtyPU THEN '1'
WHEN a.PurQtyTU<>a.CorrectQty THEN '2'
ELSE '0' END Flag INTO #tempResult
FROM Result a
WHERE a.rn=1


SELECT @Result=(SELECT CASE WHEN a.Flag='1' THEN '行号：'+CONVERT(VARCHAR(10),a.DocLineNo)+',采购数量小于需求量' 
WHEN a.Flag='2' THEN '行号：'+CONVERT(VARCHAR(10),a.DocLineNo)+',采购数量不对，应为：'+CONVERT(VARCHAR(20),CONVERT(INT,a.CorrectQty))
ELSE '0' END+'||' 
FROM #tempResult a WHERE a.Flag>0 FOR XML PATH(''))

--采购数量不符合标准，直接返回
IF ISNULL(@Result,'')<>''
RETURN;
ELSE--采购数量符合标准
SET @Result='1'


END