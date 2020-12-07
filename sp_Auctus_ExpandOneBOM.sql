/*
展单个BOM
*/
alter PROC sp_Auctus_ExpandOneBOM
(
@Itemmaster BIGINT,
@Org BIGINT
)
AS
BEGIN 
--DECLARE @Itemmaster BIGINT=1001907160013022
--DECLARE @Org BIGINT=1001708020135665
DECLARE @Org2 BIGINT=1001708020135435
DECLARE @ExpandLv int--最大展开层级
SET @ExpandLv=9
--最顶层BOM料号集合
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

IF @Org=@Org2--展200组织BOM，只取带“软件”字样的顶层料号（芯片）
INSERT INTO #tempBOMMaster
        SELECT t.ID,t.DescFlexField_PrivateDescSeg1,t1.Code
		FROM (SELECT ID,ItemMaster,DescFlexField_PrivateDescSeg1, ROW_NUMBER() OVER(PARTITION BY ItemMaster ORDER BY BOMVersion DESC)rn 
				FROM dbo.CBO_BOMMaster 
				WHERE Org=@Org
				)
		t  LEFT JOIN dbo.CBO_ItemMaster t1 ON t.ItemMaster=t1.ID WHERE t.rn=1 AND PATINDEX('%软件%',t1.Name)>0
ELSE --展300组织时，取所有顶层BOM料号
INSERT INTO #tempBOMMaster
        SELECT t.ID,t.DescFlexField_PrivateDescSeg1,t1.Code
		FROM (SELECT ID,ItemMaster,DescFlexField_PrivateDescSeg1, ROW_NUMBER() OVER(PARTITION BY ItemMaster ORDER BY BOMVersion DESC)rn 
				FROM dbo.CBO_BOMMaster 
				WHERE Org=@Org AND ItemMaster=@Itemmaster
				)
		t  LEFT JOIN dbo.CBO_ItemMaster t1 ON t.ItemMaster=t1.ID WHERE t.rn=1
--BOM展开集合
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

--料品集合，放入临时表优化SQL执行速度
IF OBJECT_ID(N'tempdb.dbo.#Auctus_ItemMaster',N'U') is NULL
BEGIN
CREATE TABLE #Auctus_ItemMaster
(
ID BIGINT,
Code VARCHAR(50),
Name NVARCHAR(255)        
)
END
ELSE
BEGIN
TRUNCATE TABLE #Auctus_ItemMaster
END

--插入ItemMaster数据
INSERT INTO #Auctus_ItemMaster
( ID, Code, Name )
	SELECT ID,Code,Name FROM dbo.CBO_ItemMaster WHERE  Org=@Org

--展BOM开始        
DECLARE @BomID BIGINT,@QuanJi VARCHAR(4),@MasterCode VARCHAR(50)
DECLARE curBOMMaster CURSOR
FOR 
SELECT ID,DescPrivate1,MasterCode FROM #tempBOMMaster
OPEN curBOMMaster
FETCH NEXT FROM curBOMMaster INTO @BomID,@QuanJi,@MasterCode
		WHILE @@FETCH_STATUS=0
		BEGIN --While
			--创建保存展开Bom的结果集临时表,，每一个BOM展开后都保存在tempBom中，然后插入到#Auctus_NewestBom中
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
			LEFT JOIN #Auctus_ItemMaster c on a.ItemMaster=c.ID
			LEFT JOIN #Auctus_ItemMaster d on b.ItemMaster=d.ID
			WHERE --b.ComponentType=0 AND
			a.AlternateType=0 AND a.BOMType=0 AND a.Org=@Org
			AND a.ID=@BomID
			--End 找出母项

			--当子项为母项时，查出母项与对应子项集合（通过有效时间）
			DECLARE @MasterBom varchar(50),@MID BIGINT,@Code varchar(50),@Name NVARCHAR(255),@DisableDate varchar(50),@curLv INT,@ThisUsageQty DECIMAL(18,8)
			,@IsExpand VARCHAR(4)
			--当前要展开的BOM层级
			SET @curLv=1
			WHILE (exists(select 0 from #tempBom where Level=@curLv) and @curLv<@ExpandLv)--当#tempBom中@curLv(当前层级)有料品且@curLv小于@ExpandLv(最大展开层级)
			BEGIN--Start While 循环往下展Bom
			DECLARE curBom cursor
			FOR
			SELECT MasterBom,MID,Code,Name,DisableDate,ThisUsageQty,IsExpand from #tempBom where Level=@curLv AND ComponentType=0 AND Org=@Org
			OPEN curBom
			FETCH next from curBom into @MasterBom,@MID,@Code,@Name,@DisableDate,@ThisUsageQty,@IsExpand
				WHILE @@fetch_status=0
				BEGIN--Start While 当子项为母项时，查出母项与对应子项集合（通过有效时间）
					--300组织才走这个逻辑，300组织带软件的料号去200找底层BOM
					--207030006和207030008料号名称带有“含应用软件”，但是他的BOM是在300组织，不在200组织，所以不去200组织抓取
					IF @Org=1001708020135665 AND (PATINDEX('%软件%',@Name)>0) AND @Code<>'207030006' AND @Code<>'207030008'
					BEGIN 			
					INSERT INTO #tempBom
					SELECT @BomID,@MasterCode,a.BOMMaster,@MID,a.ParentCode,a.MID,a.Code,a.Name,a.Sequence,a.ComponentType,a.SubSeq,a.EffectiveDate,a.DisableDate,a.SubEffectiveDate,a.SubDisableDate,a.ThisUsageQty*@ThisUsageQty,@curLv+1,a.DescPrivate1,a.IsExpand,a.Org
					FROM dbo.Auctus_NewestBom a WHERE Org=@Org2 AND MasterCode=@Code
					END 
					ELSE 
					BEGIN
					INSERT INTO #tempBom
					SELECT @BomID,@MasterCode,a.BOMMaster,a.PID,a.ParentCode,a.MID,a.Code,a.Name,a.Sequence,a.ComponentType,a.SubSeq,a.EffectiveDate,a.Dis,a.subEff,a.subDis,a.thisUsage,a.lv ,a.DescFlexField_PrivateDescSeg1,a.IsExpand,@Org
					FROM 
					(
					SELECT a.id BOMMaster,a.Itemmaster PID,c.Code ParentCode,b.ItemMaster MID,d.Code,b.Sequence,b.ComponentType,b.SubSeq
					,a.EffectiveDate,@DisableDate Dis,b.EffectiveDate subEff,b.DisableDate subDis,b.UsageQty/b.ParentQty*@ThisUsageQty thisUsage
					,@curLv+1 lv,a.DescFlexField_PrivateDescSeg1
					,CASE  WHEN 	a.DescFlexField_PrivateDescSeg1=01 OR @IsExpand=0  THEN 0 ELSE 1 END IsExpand
					,d.Name,ROW_NUMBER()OVER(PARTITION BY a.ItemMaster,b.ItemMaster  ORDER BY a.BOMVersion DESC) rn
					FROM dbo.CBO_BOMMaster a 
					INNER JOIN dbo.CBO_BOMComponent b on a.ID=b.BOMMaster 
					LEFT JOIN #Auctus_ItemMaster c on a.ItemMaster=c.ID
					LEFT JOIN #Auctus_ItemMaster d on b.ItemMaster=d.ID
					WHERE @disabledate between a.effectivedate and a.disabledate and c.code=@Code 
					AND a.Org=@Org and  a.bomtype=0 AND a.AlternateType=0
					--AND b.ComponentType=0
					) a WHERE a.rn=1
					END 
			
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
END 

	

