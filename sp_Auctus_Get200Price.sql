USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_Get200Price]    Script Date: 2018/11/16 14:41:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[sp_Auctus_Get200Price]
(
@Org BIGINT
)
AS
BEGIN 

--DECLARE @Org BIGINT=(SELECT id FROM dbo.Base_Organization WHERE code='200') 
DECLARE @LogTime VARCHAR(50)
SET @LogTime=GETDATE()
SELECT   @LogTime=CONVERT(VARCHAR(50),DATEADD(dd,-day(@LogTime)+1,@LogTime),111)
IF EXISTS(SELECT 1 FROM dbo.Auctus_PriceOf200 WHERE LogTime=@LogTime)
DELETE FROM Auctus_PriceOf200 WHERE LogTime=@LogTime


--DECLARE @Org BIGINT=1001708020135665
DECLARE @Org2 BIGINT=1001708020135435
DECLARE @ExpandLv int--展开层级
SET @ExpandLv=9
IF object_id(N'tempdb.dbo.#tempBOMMaster',N'U') is NULL
BEGIN 
CREATE TABLE #tempBOMMaster
(
ID BIGINT,
DescPrivate1 VARCHAR(4),--权级
MasterCode VARCHAR(50)
)
END
ELSE 
BEGIN
TRUNCATE TABLE #tempBOMMaster
END

INSERT INTO #tempBOMMaster
        SELECT t.ID,t.DescFlexField_PrivateDescSeg1,t1.Code
		FROM (SELECT ID,ItemMaster,DescFlexField_PrivateDescSeg1, ROW_NUMBER() OVER(PARTITION BY ItemMaster ORDER BY BOMVersion DESC)rn 
				FROM dbo.CBO_BOMMaster 
				WHERE Org=@Org
				--AND id=1001711210816009
				)
		t  LEFT JOIN dbo.CBO_ItemMaster t1 ON t.ItemMaster=t1.ID WHERE t.rn=1 AND t1.Code LIKE '3%'
		
		IF OBJECT_ID(N'tempdb.dbo.#Auctus_NewestBom',N'U') is NULL
		BEGIN
		CREATE TABLE #Auctus_NewestBom
		(
		MasterBom varchar(50),--最顶层成品料号编码
		MasterCode VARCHAR(50),
		BOMMaster varchar(50),--母项id
		PID varchar(50),--母项料号id
		ParentCode varchar(50),--子项料号编码
		MID varchar(50),--子项料号id
		Code varchar(50),--子项料号编码
		Name NVARCHAR(255)     ,
		Sequence INT,
		ComponentType INT,--子项类型 标准/替代 0/2
		SubSeq INT,--替代顺序
		EffectiveDate datetime,--母项生效时间
		DisableDate datetime,--母项失效时间
		SubEffectiveDate DATETIME,--子项生效时间
		SubDisableDate DATETIME,--子项失效时间
		ThisUsageQty DECIMAL(18,8),--用量
		Level INT,
		DescPrivate1 VARCHAR(4),--权级，即CBO_BOMMaster的DescFlexField_PrivateDescSeg1字段
		IsExpand VARCHAR(4)--是否展开，根据BOMMaster权级字段来判断，0/1-不展开/展开
		,Org BIGINT
		)
        END
        ELSE
        BEGIN
		TRUNCATE TABLE #Auctus_NewestBom
        END
        
DECLARE @BomID BIGINT,@QuanJi VARCHAR(4),@MasterCode VARCHAR(50)
DECLARE curBOMMaster CURSOR
FOR 
SELECT ID,DescPrivate1,MasterCode FROM #tempBOMMaster
OPEN curBOMMaster
FETCH NEXT FROM curBOMMaster INTO @BomID,@QuanJi,@MasterCode
		WHILE @@FETCH_STATUS=0
		BEGIN --While
		--创建保存展开Bom的结果集临时表
		IF OBJECT_ID(N'tempdb.dbo.#tempBom',N'U') is NULL
		BEGIN 
		CREATE TABLE #tempBom(
		MasterBom varchar(50),--最顶层成品料号编码
		MasterCode VARCHAR(50),
		BOMMaster varchar(50),--母项id
		PID varchar(50),--母项料号id
		ParentCode varchar(50),--子项料号编码
		MID varchar(50),--子项料号id
		Code varchar(50),--子项料号编码
		Name NVARCHAR(255)     ,
		Sequence INT,
		ComponentType INT,--子项类型 标准/替代 0/2
		SubSeq INT,--替代顺序
		EffectiveDate datetime,--母项生效时间
		DisableDate datetime,--母项失效时间
		SubEffectiveDate DATETIME,--子项生效时间
		SubDisableDate DATETIME,--子项失效时间
		ThisUsageQty DECIMAL(18,8),--用量
		Level INT,
		DescPrivate1 VARCHAR(4),--权级，即CBO_BOMMaster的DescFlexField_PrivateDescSeg1字段
		IsExpand VARCHAR(4)--是否展开，根据BOMMaster权级字段来判断，0/1-不展开/展开
		,Org BIGINT 
	)
		END 
		ELSE
        BEGIN
        TRUNCATE TABLE #tempBom
		END 
		--Start 找出母项（通过BomID）
		
		INSERT INTO #tempBom
		SELECT @BomID,@MasterCode,a.ID,a.ItemMaster,c.Code,b.ItemMaster,d.Code,d.Name,b.Sequence,b.ComponentType,b.SubSeq,a.EffectiveDate,
		CASE WHEN a.DisableDate>'9000-12-31' THEN GETDATE() ELSE a.DisableDate END,b.EffectiveDate,b.DisableDate,
		b.UsageQty/b.ParentQty
		,1--Level
		,a.DescFlexField_PrivateDescSeg1--权级
		,CASE WHEN @QuanJi=01 THEN 0 ELSE 1 END --IsExpand
		,@Org
		FROM dbo.CBO_BOMMaster a 
		INNER JOIN dbo.CBO_BOMComponent b on a.ID=b.BOMMaster 
		LEFT JOIN dbo.CBO_ItemMaster c on a.ItemMaster=c.ID
		LEFT JOIN dbo.CBO_ItemMaster d on b.ItemMaster=d.ID
		WHERE --b.ComponentType=0 AND
		a.AlternateType=0 AND a.BOMType=0 AND a.Org=@Org
		--AND c.code='101010008' AND a.BOMVersionCode='V3.1'
		AND a.ID=@BomID
		--End 找出母项

		--当子项为母项时，查出母项与对应子项集合（通过有效时间）
		DECLARE @MasterBom varchar(50),@MID BIGINT,@Code varchar(50),@Name NVARCHAR(255),@DisableDate varchar(50),@curLv INT,@ThisUsageQty DECIMAL(18,8)
		,@IsExpand VARCHAR(4)
		--SELECT TOP 1 @disabledate=disabledate FROM @tempBom 
		SET @curLv=1
		WHILE (exists(select 0 from #tempBom where Level=@curLv) and @curLv<@ExpandLv)
		BEGIN--Start While 循环往下展Bom
		DECLARE curBom cursor
		FOR
		SELECT MasterBom,MID,Code,Name,DisableDate,ThisUsageQty,IsExpand from #tempBom where Level=@curLv AND ComponentType=0 AND Org=@Org
		OPEN curBom
		FETCH next from curBom into @MasterBom,@MID,@Code,@Name,@DisableDate,@ThisUsageQty,@IsExpand
			WHILE @@fetch_status=0
			BEGIN--Start While 当子项为母项时，查出母项与对应子项集合（通过有效时间）
			
			INSERT INTO #tempBom
			SELECT @BomID,@MasterCode,a.BOMMaster,a.PID,a.ParentCode,a.MID,a.Code,a.Name,a.Sequence,a.ComponentType,a.SubSeq,a.EffectiveDate,a.Dis,a.subEff,a.subDis,a.thisUsage,a.lv ,a.DescFlexField_PrivateDescSeg1,a.IsExpand,@Org
			FROM 
			(
			SELECT a.id BOMMaster,a.Itemmaster PID,c.Code ParentCode,b.ItemMaster MID,d.Code,b.Sequence,b.ComponentType,b.SubSeq
			,a.EffectiveDate,@DisableDate Dis,b.EffectiveDate subEff,b.DisableDate subDis,b.UsageQty/b.ParentQty*@ThisUsageQty thisUsage
			,@curLv+1 lv,a.DescFlexField_PrivateDescSeg1,CASE  WHEN 
			--a.DescFlexField_PrivateDescSeg1=01 or 
			a.DescFlexField_PrivateDescSeg1=01 OR @IsExpand=0  THEN 0 ELSE 1 END IsExpand
			,d.Name
			,ROW_NUMBER()OVER(PARTITION BY a.ItemMaster,b.ItemMaster  ORDER BY a.BOMVersion DESC) rn
			FROM dbo.CBO_BOMMaster a 
			INNER JOIN dbo.CBO_BOMComponent b on a.ID=b.BOMMaster 
			LEFT JOIN dbo.CBO_ItemMaster c on a.ItemMaster=c.ID
			LEFT JOIN dbo.CBO_ItemMaster d on b.ItemMaster=d.ID
			WHERE @disabledate between a.effectivedate and a.disabledate and c.code=@Code 
			AND a.Org=@Org and c.Org=@Org AND d.Org=@org AND a.bomtype=0 AND a.AlternateType=0
			--AND b.ComponentType=0
			) a WHERE a.rn=1			
			FETCH next from curBom into @MasterBom,@MID,@Code,@Name,@DisableDate,@ThisUsageQty,@IsExpand
			END --End While 当子项为母项时，查出母项与对应子项集合（通过有效时间）
			CLOSE curBom
			DEALLOCATE curBom
			SET @curLv=@curLv+1
			END--End While 循环往下展Bom
			INSERT INTO #Auctus_NewestBom
				SELECT * FROM #tempBom
		FETCH NEXT FROM curBOMMaster INTO @BomID,@QuanJi,@MasterCode
        END --End While
CLOSE curBOMMaster
DEALLOCATE curBOMMaster


;
WITH parent AS
(
SELECT DISTINCT mastercode FROM #Auctus_NewestBom 
),
child AS
(
SELECT DISTINCT Code FROM #Auctus_NewestBom WHERE code NOT LIKE 'S%' 
),
alls AS
(
SELECT * FROM parent UNION SELECT * FROM child
),
PPRData AS
(
 SELECT * FROM (SELECT   a1.ItemInfo_ItemCode,
						CASE WHEN a2.currency=1 AND  a2.IsIncludeTax = 1 						THEN ISNULL(Price, 0)/1.16
						WHEN a2.Currency=1 AND a2.IsIncludeTax=0						THEN ISNULL(Price, 0)
						WHEN a2.Currency!=1 AND a2.IsIncludeTax=1						THEN ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, @LogTime, 2)/1.16
						ELSE ISNULL(Price, 0) * dbo.fn_CustGetCurrentRate(a2.Currency, 1, @LogTime, 2) END Price,
						ROW_NUMBER()OVER(PARTITION BY a1.ItemInfo_ItemCode ORDER BY a2.Org DESC,a1.FromDate DESC) AS rowNum					--倒序排生效日
				FROM    PPR_PurPriceLine a1 RIGHT JOIN alls c ON a1.ItemInfo_ItemCode=c.MasterCode
						INNER JOIN PPR_PurPriceList a2 ON a1.PurPriceList = a2.ID AND a2.Status = 2 AND a2.Cancel_Canceled = 0 AND a1.Active = 1
				WHERE   NOT EXISTS ( SELECT 1 FROM CBO_Supplier WHERE DescFlexField_PrivateDescSeg3 = 'OT01' AND a2.Supplier = ID ) AND 
						a2.Org IN( 1001708020135665,1001708020135435)
						--a2.Org=1001708020135665
						AND a1.FromDate <= @LogTime)
						t WHERE t.rowNum=1
),
result AS
(
SELECT a.parentcode,a.code,a.ThisUsageQty,ISNULL(b.Price,0)Price,ISNULL(c.Price,0) cPrice,ISNULL(d.StandardPrice,0)StandardPrice
,ISNULL(e.StandardPrice,0) cStandardPrice 
FROM #Auctus_NewestBom a LEFT JOIN PPRData b ON a.ParentCode=b.ItemInfo_ItemCode LEFT JOIN PPRData c ON a.Code=c.ItemInfo_ItemCode
LEFT JOIN dbo.Auctus_ItemStandardPrice d ON a.ParentCode=d.Code AND d.LogTime=@LogTime 
LEFT JOIN dbo.Auctus_ItemStandardPrice e ON a.Code=e.Code AND e.LogTime=@LogTime
WHERE a.code NOT LIKE 'S%'
)
INSERT INTO Auctus_PriceOf200
SELECT result.ParentCode,MIN(price)Price,SUM(result.ThisUsageQty*result.cPrice)materialTotal
,MIN(price)-SUM(result.ThisUsageQty*result.cPrice)-0.1/1.16 softTotal
,MIN(result.StandardPrice),SUM(result.ThisUsageQty*result.cStandardPrice)StandardMaterialTotal,
MIN(result.StandardPrice)- SUM(result.ThisUsageQty*result.cStandardPrice)-0.1/1.16 StandartSoftTotal
,@LogTime
FROM result 
GROUP BY result.ParentCode
--SELECT * FROM dbo.Auctus_PriceOf200


--CREATE TABLE Auctus_PriceOf200
--(
--ID INT PRIMARY KEY IDENTITY(1,1),
--Code VARCHAR(50),
--Price DECIMAL(18,6),
--MaterialTotal DECIMAL(18,6),
--SoftTotal DECIMAL(18,6),
--StandardPrice DECIMAL(18,6),
--StandardMaterialTotal DECIMAL(18,6),
--StandardSoftTotal DECIMAL(18,6),
--LogTime date
--)

--SELECT *FROM Auctus_PriceOf200

END 