USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[sp_Auctus_WhOfPhantomPart]    Script Date: 2018/8/14 10:15:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
查询条件：
BOM版是否最新
 是：只查询最新版本 
 否：查询所有版本

报表逻辑：
根据查询条件找出所有BOM中虚拟件的物料，关联现有库存表提取展示有库存的物料

布署节点：库存管理
报表名称：BOM虚拟件库存报表
*/
ALTER PROC [dbo].[sp_Auctus_WhOfPhantomPart]
(
@Org BIGINT,
@IsNewest VARCHAR(2),
@Wh VARCHAR(500)
)
AS
BEGIN 
--DECLARE @IsNewest VARCHAR(2)='是'
--DECLARE @Wh VARCHAR(500)=''
--DECLARE @Org BIGINT=1001708020135665
IF OBJECT_ID(N'tempdb.dbo.#tempBom',N'U') is NULL
		BEGIN 
		CREATE TABLE #tempBom(
		BomID BIGINT,
		ParentCode VARCHAR(50),
		ParentName NVARCHAR(255),
		Code VARCHAR(50),
		Name NVARCHAR(255),
		ParentVersionCode VARCHAR(50),
		IsPhantomPart VARCHAR(50),
		RN int
	)
		END 
		ELSE
        BEGIN
        TRUNCATE TABLE #tempBom
		END 		
		IF ISNULL(@IsNewest,'是')='否'--取全部版本
		BEGIN 
			INSERT INTO #tempBom
			SELECT a.ID ,c.Code,c.Name,d.Code CCode,d.Name CName,a.BOMVersionCode,b.IsPhantomPart,
			ROW_NUMBER()OVER(PARTITION BY a.ItemMaster,b.ItemMaster ORDER BY a.BOMVersion desc)RN
			FROM dbo.CBO_BOMMaster a LEFT JOIN dbo.CBO_BOMComponent b ON a.ID=b.BOMMaster
			LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID LEFT JOIN dbo.CBO_ItemMaster d ON b.ItemMaster=d.ID
			WHERE a.Org=@Org AND b.IsPhantomPart=1 
		END 
		ELSE 
		BEGIN 
		;WITH BOMMaster AS
			(
			SELECT * FROM (SELECT a.ID,a.ItemMaster,a.BOMVersionCode,ROW_NUMBER()OVER(PARTITION BY a.ItemMaster ORDER BY a.BOMVersion DESC)rn FROM dbo.CBO_BOMMaster a WHERE Org=1001708020135665) a WHERE a.rn=1
			),data1 AS
            (			
			SELECT a.ID ,c.Code,c.Name,d.Code CCode,d.Name CName,a.BOMVersionCode, b.IsPhantomPart
			FROM BOMMaster a INNER JOIN dbo.CBO_BOMComponent b ON a.ID=b.BOMMaster
			LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemMaster=c.ID LEFT JOIN dbo.CBO_ItemMaster d ON b.ItemMaster=d.ID
			WHERE c.org=@Org AND d.org=@Org AND d.Code<>'314050016'
			AND b.IsPhantomPart=1
			 --AND d.code='202010133'
			) INSERT INTO #tempBom SELECT *,1 RN FROM data1
		END 

;

IF ISNULL(@Wh,'')=''
BEGIN
SET @Wh=(SELECT Code+',' FROM CBO_Wh WHERE Org=@Org FOR XML PATH(''))
END

;WITH WH AS
(
SELECT a.ItemInfo_ItemID,a.ItemInfo_ItemCode,a.LotInfo_LotCode,c.DocNo,c.DocLineNo,a.StoreQty 
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.StorageTypeEnum',a.StorageType,'zh-cn')StorageType
,b1.Name StoreLocation
FROM dbo.InvTrans_WhQoh a LEFT JOIN dbo.CBO_Wh b ON a.Wh=b.ID LEFT JOIN dbo.CBO_Wh_Trl b1 ON b.ID=b1.ID
LEFT JOIN dbo.Lot_LotMaster c ON a.LotInfo_LotMaster_EntityID=c.ID
WHERE b.Org=@Org --AND b.LocationType=0--普通仓
AND b.Effective_IsEffective=1
--AND a.StorageType  not  in (5,1,2,0,3,7) --0、1、2、3、5、7 待检、在检、不合格、报废、冻结、待返工
AND a.ItemInfo_ItemCode IN (SELECT DISTINCT  Code FROM #tempBom)
AND b.Code IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@Wh))  
AND b1.SysMLFlag='zh-cn'
AND a.StoreQty<>0
),
Result AS
(
SELECT c.Code,c.Name,c.SPECS,a.* FROM WH a LEFT JOIN (SELECT DISTINCT Code FROM #tempBom) b ON a.ItemInfo_ItemCode=b.Code
LEFT JOIN dbo.CBO_ItemMaster c ON a.ItemInfo_ItemID=c.ID
WHERE b.Code IS NOT NULL
)
SELECT * FROM Result ORDER BY Result.Code


END
	




