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

ADD(2019-1-2)邹功禄
关闭WMO转委外控制

ADD(2019-3-15)
WPO增加供应商审批流管控
  1）取采购订订单行物料对应供应商货源表上的配额方式及供应顺序，如果配额方式不包含比例分配及供应顺序等于”1“，标记该物料采购订单头主供应商标识为”TRUE“否则为”FALSE“；
  2）如果采购订单行为多行，存在任意一行物料判定不是主供应商，标记采购订单头主供应商标识为”FALSE”反之为“TRUE”

*/
--采购订单BE插件
ALTER PROC [dbo].[sp_Auctus_BE_PurchaseOrderAI]
(
  @DocNo VARCHAR(50),
 @Result NVARCHAR(MAX) OUT--检测结果 0、不欠料；1、现有委外单欠料；2、生产订单备料单没库存
)
AS
BEGIN


DECLARE @UnPrimaryCount INT --非主供应商数量
SELECT 
--a.DocNo,a.Supplier_Supplier,b.ItemInfo_ItemCode,b.ItemInfo_ItemName,cp.PurchaseQuotaMode,ISNULL(c.OrderNO,0)OrderNo
--,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.PurchaseQuotaModeEnum',cp.PurchaseQuotaMode,'zh-cn')
@UnPrimaryCount=COUNT(1)
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder
LEFT JOIN dbo.CBO_PurchaseInfo cp ON b.ItemInfo_ItemID=cp.ItemMaster
LEFT JOIN dbo.CBO_SupplySource c ON a.Supplier_Supplier=c.SupplierInfo_Supplier AND b.ItemInfo_ItemID=c.ItemInfo_ItemID
WHERE 1=1 AND  a.DocNo=@DocNo
AND ((PATINDEX('%比例%',dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.PurchaseQuotaModeEnum',cp.PurchaseQuotaMode,'zh-cn'))=0AND ISNULL(c.OrderNO,0)<>1) --辅、备供应商
OR PATINDEX('%比例%',dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Item.PurchaseQuotaModeEnum',cp.PurchaseQuotaMode,'zh-cn'))>0)--比例分配
IF @UnPrimaryCount=0--使用辅、备供应商/比例分配的个数为0
BEGIN
	UPDATE dbo.PM_PurchaseOrder SET DescFlexField_PrivateDescSeg2=0 WHERE DocNo=@DocNo
END
ELSE
BEGIN
	UPDATE dbo.PM_PurchaseOrder SET DescFlexField_PrivateDescSeg2=1 WHERE DocNo=@DocNo
END 
--End	如果配额方式不包含比例分配且供应顺序等于”1“，则不需要审批


SET @Result=0
RETURN ;
----匹配委外仓
DECLARE @w VARCHAR(20)
DECLARE @company NVARCHAR(255)

SELECT @company=b1.Name FROM dbo.PM_PurchaseOrder a LEFT JOIN dbo.CBO_Supplier b ON a.Supplier_Supplier=b.ID LEFT JOIN dbo.CBO_Supplier_Trl b1 ON b.ID=b1.ID
WHERE ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn' AND a.DocNo=@DocNo

IF PATINDEX('%华强%',@company)>0
 SET @w='华强'  

IF PATINDEX('%康拓%',@company)>0
SET @w='康拓'
IF PATINDEX('%启源%',@company)>0
SET @w='启源'
IF PATINDEX('%同格%',@company)>0
BEGIN
SET @w='同格'
SET @Result=0
RETURN;
END 
IF PATINDEX('%金创图%',@company)>0
SET @w='金创图'
IF PATINDEX('%伟丰实业%',@company)>0
BEGIN 
SET @w='伟丰实业'
SET @Result=0
RETURN ;
END 
IF PATINDEX('%中旭%',@company)>0
SET @w='中旭'

 
DECLARE @Org BIGINT=1001708020135665
DECLARE @Wh VARCHAR(100)
DECLARE @WPOList VARCHAR(MAX)--未发料的委外订单号
SELECT @WPOList=(SELECT DISTINCT a.DocNo+','
--a.DocNo,d.PickLineNo
--,d.ItemInfo_ItemID Item,d.ItemInfo_ItemCode,d.ItemInfo_ItemName
--,d.IssuedQty--已发放数量  
--,d.ActualReqQty--实际需求数量	
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
LEFT JOIN dbo.CBO_Supplier f ON a.Supplier_Supplier=f.ID LEFT JOIN dbo.CBO_Supplier_Trl f1 ON f.ID=f1.ID AND ISNULL(f1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.Status in(0,1,2) and b.Status in (0,1,2) AND a.Org=@Org --AND d.ActualReqDate BETWEEN @StartDate AND @EndDate
and  exists  (select 1 from PM_POShipLine b1  where e.ID=b1.ID   )
AND c.ID IS NOT NULL
AND a.Cancel_Canceled<>1
AND d.IssueStyle<>2--2 是不发料
AND d.IssuedQty<d.ActualReqQty
AND f1.Name=@company
AND a.DocNo<>@DocNo
FOR XML PATH('')
)
IF ISNULL(@WPOList,'')<>''--存在未发料的委外订单
BEGIN
 SET @Result='存在未发料的委外单:'+@WPOList
RETURN
END 

DECLARE @codeList NVARCHAR(MAX)--待转订单库存不够的料号集合

;
WITH MOPickList AS
(
SELECT a.DocNo,d.PickLineNo
,d.ItemInfo_ItemID Item,d.ItemInfo_ItemCode,d.ItemInfo_ItemName
,d.IssuedQty--已发放数量  
,d.ActualReqQty--实际需求数量	
FROM dbo.PM_PurchaseOrder a INNER JOIN dbo.PM_POLine b ON a.ID=b.PurchaseOrder 
LEFT JOIN dbo.CBO_SCMPickHead c ON b.SCMPickHead=c.ID LEFT JOIN dbo.CBO_SCMPickList d ON d.PicKHead=c.ID
LEFT JOIN dbo.PM_POShipLine e ON e.POLine=b.ID
WHERE a.Org=@Org --AND d.ActualReqDate BETWEEN @StartDate AND @EndDate
and  exists  (select 1 from PM_POShipLine b1  where e.ID=b1.ID   )
AND a.Cancel_Canceled<>1
AND c.ID IS NOT NULL
AND d.IssueStyle<>2--2 是不发料
AND d.IssuedQty<d.ActualReqQty
AND a.DocNo=@DocNo
),
Woh AS
(
SELECT a.ItemInfo_ItemCode,SUM(a.StoreQty)StoreQty FROM dbo.InvTrans_WhQoh a LEFT JOIN dbo.CBO_Wh b ON a.Wh=b.ID LEFT JOIN dbo.CBO_Wh_Trl b1 ON b.ID=b1.ID
WHERE b.Org=@Org AND b.LocationType=0--普通仓
AND b.Effective_IsEffective=1
AND a.StorageType  not  in (5,1,2,0,3,7) --0、1、2、3、5、7 待检、在检、不合格、报废、冻结、待返工
AND a.ItemInfo_ItemCode IN 
(SELECT DISTINCT a.ItemInfo_ItemCode FROM MOPickList a)
AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
AND (PATINDEX('%委外%',b1.Name)=0 OR PATINDEX('%'+@w+'%',b1.Name)>0)
--AND b.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Wh))  
Group By a.ItemInfo_ItemCode 
)
SELECT @codeList=( SELECT a.ItemInfo_ItemCode+',' FROM MOPickList a LEFT JOIN Woh b ON a.ItemInfo_ItemCode=b.ItemInfo_ItemCode
WHERE (a.ActualReqQty-a.IssuedQty)>ISNULL(b.StoreQty,0) FOR XML PATH('')
)
IF ISNULL(@codeList,'')<>''
BEGIN
 SET @Result='工单备料库存不足：'+@codeList
RETURN
END
SET @Result='0'


----300 委外单才会去验证
END