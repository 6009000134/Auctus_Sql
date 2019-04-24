/*
工单转WPO比例优化
与请购转PO比例优化一样
需求：
    请购转PO分配逻辑如下（本邮件中的料品都是指按比例分配的料品）：
     1、请购单转PO时，按货源表设置的比例进行分配，不足MOQ部分优先分配给价格最低的供应商
     2、今天沟通后，在逻辑1的基础上增加：当请购数量小于50K时，请购数量全部分配给价格最低的供应商，不进行比例分配
    例如：   M料号按比例分配有供应商A1 40%（A1价格最低），A2 30%, A3 30%，供应商MOQ均为1000，
    当M的请购数量为6003005，若按系统原始逻辑分配结果：
    A1：24K+1205
    A2：18K+915
    A3：18K+915
    IT开发插件优化后分配结果为：
    A1：24K+3005
    A2：18K
    A3：18K
*/
ALTER PROC [dbo].[sp_Auctus_UI_GetWPOSupplySource]
(
@MOID BIGINT,
@Result NVARCHAR(max) OUT
)
AS
BEGIN

--DECLARE @MOID BIGINT
--DECLARE @Result NVARCHAR(MAX)
DECLARE @Org BIGINT =1001708020135665
DECLARE @TaxRate DECIMAL(18,2)--税率
SET @TaxRate=1.13

DECLARE @PurchaseQuotaMode int
SELECT @PurchaseQuotaMode=b.PurchaseQuotaMode FROM dbo.MO_MO a LEFT JOIN dbo.CBO_PurchaseInfo b ON a.ItemMaster=b.ItemMaster
WHERE a.ID=@MOID

IF ISNULL(@PurchaseQuotaMode,0)<>4
BEGIN--料号分配模式为：不按比例分配
	SET @Result='0'
END 
ELSE--料号分配模式为：按比例分配
BEGIN
	SET @Result='1'
	--获取料号的货源表比例分配数据
	--需求待调研：是否只取供货顺序为1的货源
	
	--SELECT
	--a.DocNo,b.ItemInfo_ItemCode,a.ProductQty,b.OrderNO,b.SupplierQuota,c.PurchaseBatchQty
	--FROM dbo.MO_MO a LEFT JOIN dbo.CBO_SupplySource b ON a.ItemMaster=b.ItemInfo_ItemID AND a.Org=b.Org
	--LEFT JOIN dbo.CBO_PurchaseInfo c ON a.ItemMaster=c.ItemMaster
	--WHERE a.DocNo='WMO-30190225017'
	--AND b.Effective_IsEffective=1	

	--请购料品信息
	IF OBJECT_ID(N'tempdb.dbo.#tempItem',N'U') IS NULL
	BEGIN
		CREATE TABLE #tempItem
		(
		MOID BIGINT,
		DocNo VARCHAR(50),
		Itemmaster BIGINT,
		Code VARCHAR(50),
		ProductQty DECIMAL(18,0),
		SupplySource BIGINT,
		SupplierQuota DECIMAL(18,4),
		Supplier BIGINT,
		SupplierCode NVARCHAR(100),
		SupplierName NVARCHAR(100),
		MinRcvQty DECIMAL(18,0),
		Price DECIMAL(18,9),
		Times INT,
		Remainder DECIMAL(18,4),
		Remainder2 DECIMAL(18,4),
		RN INT,--同一PRLine排序
		RN2 INT--同一PRLine按比例降序、价格升序排序
    
		)
	END
	ELSE
		TRUNCATE TABLE #tempItem

	--按比例排序
	;

	WITH ItemMaster AS
	(
	SELECT a.ID,a.DocNo,c.ItemInfo_ItemID,c.ItemInfo_ItemCode
	,a.ProductQty
	,c.ID SupplySource,c.SupplierQuota,c.SupplierInfo_Supplier,e.Code,e1.Name,CASE WHEN ISNULL(b.MinRcvQty,0)=0 THEN 1 ELSE b.MinRcvQty END MinRcvQty
	FROM dbo.MO_MO a INNER JOIN dbo.CBO_PurchaseInfo b ON a.ItemMaster=b.ItemMaster
	INNER JOIN dbo.CBO_SupplySource c ON a.ItemMaster=c.ItemInfo_ItemID AND c.Org=a.Org
	LEFT JOIN dbo.CBO_Supplier e ON c.SupplierInfo_Supplier=e.ID LEFT JOIN dbo.CBO_Supplier_Trl e1 ON e.ID=e1.ID AND ISNULL(e1.SysMLFlag,'zh-cn')='zh-cn'
	WHERE a.ID=@MOID AND a.Org=@Org AND c.OrderNO=1
	),
	PPR AS
	(
	 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,a2.Supplier,itemmaster.ID,
							CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/@TaxRate
							WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
							WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2)/@TaxRate
							ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, GETDATE(), 2) END Price,
							ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode,a2.Supplier ORDER BY a2.Org DESC,a1.FromDate DESC) AS rowNum					--倒序排生效日
					FROM    PPR_PurPriceLine a1 INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
							INNER JOIN ItemMaster itemmaster ON a2.Supplier=itemmaster.SupplierInfo_Supplier AND a1.ItemInfo_ItemID=itemmaster.ItemInfo_ItemID
					WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
							a2.Org=@Org
							AND a1.FromDate <= GETDATE())
							t WHERE t.rowNum=1
	)
	INSERT INTO #tempItem
	SELECT a.*,b.Price
	, FLOOR(a.ProductQty*a.SupplierQuota/a.MinRcvQty)  Times
	, a.ProductQty*a.SupplierQuota%a.MinRcvQty  Remainder
	,0 Remainder2
	,DENSE_RANK()OVER(ORDER BY a.ID)RN,ROW_NUMBER() OVER(PARTITION BY a.ID ORDER BY b.Price ASC,a.SupplierQuota DESC)RN2
	FROM ItemMaster a LEFT JOIN PPR b ON a.ID=b.ID AND a.SupplierInfo_Supplier=b.Supplier    


	DECLARE @ErrorInfo NVARCHAR(MAX)=''--错误信息
	DECLARE @IsPriceExists NVARCHAR(MAX)=''--料品是否有价格
	DECLARE @IsPercent100 NVARCHAR(MAX)=''--货源表比例分配总和是否为100%

	SELECT @IsPercent100=CASE WHEN SUM(a.SupplierQuota)=1 THEN '' WHEN SUM(a.SupplierQuota)>1 THEN '货源表货顺序为“1”的比例和超过了100%。' ELSE '货源表货顺序为“1”的比例和小于100%。' END  FROM #tempItem a GROUP BY a.DocNo

	SELECT @IsPriceExists=(
	SELECT a.Code+a.SupplierName+'供应商无厂商价目表数据;'
	FROM #tempItem a
	WHERE a.Price IS NULL
	FOR XML PATH('') )

	SET @ErrorInfo=ISNULL(@IsPriceExists,'')
	SET @ErrorInfo=@ErrorInfo+ISNULL(@IsPercent100,'')
	--SET @ErrorInfo=''--测试用，正式库请删除此行
	IF ISNULL(@ErrorInfo,'')<>''--有料号存在无供应商-料品交叉数据，直接返回错误信息
	BEGIN
		SET @Result=LEFT(@ErrorInfo,LEN(@ErrorInfo)-1)
	END 
	--SELECT @Result

	DECLARE @RN BIGINT,@Remainder decimal(18,0)
	DECLARE cur CURSOR
	FOR
	SELECT RN,SUM(Remainder) FROM #tempItem GROUP BY RN
	OPEN cur                     
	FETCH NEXT FROM cur INTO @RN,@Remainder                   
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE #tempItem SET Remainder2=@Remainder WHERE rn=@RN AND RN2=1
		FETCH NEXT FROM cur  INTO @RN,@Remainder

	END                     
	CLOSE cur 
	DEALLOCATE cur 

	SELECT a.*,ISNULL(a.MinRcvQty,1)*a.Times+a.Remainder2 ActualReq FROM #tempItem a

	
END 

END 