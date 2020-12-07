/*
չ����BOM
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
DECLARE @ExpandLv int--���չ���㼶
SET @ExpandLv=9
--���BOM�Ϻż���
IF object_id(N'tempdb.dbo.#tempBOMMaster',N'U') is NULL
BEGIN 
CREATE TABLE #tempBOMMaster
(
ID BIGINT,
DescPrivate1 VARCHAR(4),--Ȩ��
MasterCode VARCHAR(50)
)
END
ELSE 
BEGIN
TRUNCATE TABLE #tempBOMMaster
END

IF @Org=@Org2--չ200��֯BOM��ֻȡ��������������Ķ����Ϻţ�оƬ��
INSERT INTO #tempBOMMaster
        SELECT t.ID,t.DescFlexField_PrivateDescSeg1,t1.Code
		FROM (SELECT ID,ItemMaster,DescFlexField_PrivateDescSeg1, ROW_NUMBER() OVER(PARTITION BY ItemMaster ORDER BY BOMVersion DESC)rn 
				FROM dbo.CBO_BOMMaster 
				WHERE Org=@Org
				)
		t  LEFT JOIN dbo.CBO_ItemMaster t1 ON t.ItemMaster=t1.ID WHERE t.rn=1 AND PATINDEX('%���%',t1.Name)>0
ELSE --չ300��֯ʱ��ȡ���ж���BOM�Ϻ�
INSERT INTO #tempBOMMaster
        SELECT t.ID,t.DescFlexField_PrivateDescSeg1,t1.Code
		FROM (SELECT ID,ItemMaster,DescFlexField_PrivateDescSeg1, ROW_NUMBER() OVER(PARTITION BY ItemMaster ORDER BY BOMVersion DESC)rn 
				FROM dbo.CBO_BOMMaster 
				WHERE Org=@Org AND ItemMaster=@Itemmaster
				)
		t  LEFT JOIN dbo.CBO_ItemMaster t1 ON t.ItemMaster=t1.ID WHERE t.rn=1
--BOMչ������
IF OBJECT_ID(N'tempdb.dbo.#Auctus_NewestBom',N'U') is NULL
BEGIN
CREATE TABLE #Auctus_NewestBom
(
MasterBom varchar(50),--����Ʒ�Ϻű���
MasterCode VARCHAR(50),
BOMMaster varchar(50),--ĸ��id
PID varchar(50),--ĸ���Ϻ�id
ParentCode varchar(50),--�����Ϻű���
MID varchar(50),--�����Ϻ�id
Code varchar(50),--�����Ϻű���
Name NVARCHAR(255)     ,
Sequence INT,
ComponentType INT,--�������� ��׼/��� 0/2
SubSeq INT,--���˳��
EffectiveDate datetime,--ĸ����Чʱ��
DisableDate datetime,--ĸ��ʧЧʱ��
SubEffectiveDate DATETIME,--������Чʱ��
SubDisableDate DATETIME,--����ʧЧʱ��
ThisUsageQty DECIMAL(18,8),--����
Level INT,
DescPrivate1 VARCHAR(4),--Ȩ������CBO_BOMMaster��DescFlexField_PrivateDescSeg1�ֶ�
IsExpand VARCHAR(4)--�Ƿ�չ��������BOMMasterȨ���ֶ����жϣ�0/1-��չ��/չ��
,Org BIGINT
)
END
ELSE
BEGIN
TRUNCATE TABLE #Auctus_NewestBom
END

--��Ʒ���ϣ�������ʱ���Ż�SQLִ���ٶ�
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

--����ItemMaster����
INSERT INTO #Auctus_ItemMaster
( ID, Code, Name )
	SELECT ID,Code,Name FROM dbo.CBO_ItemMaster WHERE  Org=@Org

--չBOM��ʼ        
DECLARE @BomID BIGINT,@QuanJi VARCHAR(4),@MasterCode VARCHAR(50)
DECLARE curBOMMaster CURSOR
FOR 
SELECT ID,DescPrivate1,MasterCode FROM #tempBOMMaster
OPEN curBOMMaster
FETCH NEXT FROM curBOMMaster INTO @BomID,@QuanJi,@MasterCode
		WHILE @@FETCH_STATUS=0
		BEGIN --While
			--��������չ��Bom�Ľ������ʱ��,��ÿһ��BOMչ���󶼱�����tempBom�У�Ȼ����뵽#Auctus_NewestBom��
			IF OBJECT_ID(N'tempdb.dbo.#tempBom',N'U') is NULL
			BEGIN 
			CREATE TABLE #tempBom(
			MasterBom varchar(50),--����Ʒ�Ϻű���
			MasterCode VARCHAR(50),
			BOMMaster varchar(50),--ĸ��id
			PID varchar(50),--ĸ���Ϻ�id
			ParentCode varchar(50),--�����Ϻű���
			MID varchar(50),--�����Ϻ�id
			Code varchar(50),--�����Ϻű���
			Name NVARCHAR(255)     ,
			Sequence INT,
			ComponentType INT,--�������� ��׼/��� 0/2
			SubSeq INT,--���˳��
			EffectiveDate datetime,--ĸ����Чʱ��
			DisableDate datetime,--ĸ��ʧЧʱ��
			SubEffectiveDate DATETIME,--������Чʱ��
			SubDisableDate DATETIME,--����ʧЧʱ��
			ThisUsageQty DECIMAL(18,8),--����
			Level INT,
			DescPrivate1 VARCHAR(4),--Ȩ������CBO_BOMMaster��DescFlexField_PrivateDescSeg1�ֶ�
			IsExpand VARCHAR(4)--�Ƿ�չ��������BOMMasterȨ���ֶ����жϣ�0/1-��չ��/չ��
			,Org BIGINT 
			)
			END 
			ELSE
			BEGIN
			TRUNCATE TABLE #tempBom
			END 

			--Start �ҳ�ĸ�ͨ��BomID��		
			INSERT INTO #tempBom
			SELECT @BomID,@MasterCode,a.ID,a.ItemMaster,c.Code,b.ItemMaster,d.Code,d.Name,b.Sequence,b.ComponentType,b.SubSeq,a.EffectiveDate,
			CASE WHEN a.DisableDate>'9000-12-31' THEN GETDATE() ELSE a.DisableDate END,b.EffectiveDate,b.DisableDate,
			b.UsageQty/b.ParentQty
			,1--Level
			,a.DescFlexField_PrivateDescSeg1--Ȩ��
			,CASE WHEN @QuanJi=01 THEN 0 ELSE 1 END --IsExpand
			,@Org
			FROM dbo.CBO_BOMMaster a 
			INNER JOIN dbo.CBO_BOMComponent b on a.ID=b.BOMMaster 
			LEFT JOIN #Auctus_ItemMaster c on a.ItemMaster=c.ID
			LEFT JOIN #Auctus_ItemMaster d on b.ItemMaster=d.ID
			WHERE --b.ComponentType=0 AND
			a.AlternateType=0 AND a.BOMType=0 AND a.Org=@Org
			AND a.ID=@BomID
			--End �ҳ�ĸ��

			--������Ϊĸ��ʱ�����ĸ�����Ӧ����ϣ�ͨ����Чʱ�䣩
			DECLARE @MasterBom varchar(50),@MID BIGINT,@Code varchar(50),@Name NVARCHAR(255),@DisableDate varchar(50),@curLv INT,@ThisUsageQty DECIMAL(18,8)
			,@IsExpand VARCHAR(4)
			--��ǰҪչ����BOM�㼶
			SET @curLv=1
			WHILE (exists(select 0 from #tempBom where Level=@curLv) and @curLv<@ExpandLv)--��#tempBom��@curLv(��ǰ�㼶)����Ʒ��@curLvС��@ExpandLv(���չ���㼶)
			BEGIN--Start While ѭ������չBom
			DECLARE curBom cursor
			FOR
			SELECT MasterBom,MID,Code,Name,DisableDate,ThisUsageQty,IsExpand from #tempBom where Level=@curLv AND ComponentType=0 AND Org=@Org
			OPEN curBom
			FETCH next from curBom into @MasterBom,@MID,@Code,@Name,@DisableDate,@ThisUsageQty,@IsExpand
				WHILE @@fetch_status=0
				BEGIN--Start While ������Ϊĸ��ʱ�����ĸ�����Ӧ����ϣ�ͨ����Чʱ�䣩
					--300��֯��������߼���300��֯��������Ϻ�ȥ200�ҵײ�BOM
					--207030006��207030008�Ϻ����ƴ��С���Ӧ�����������������BOM����300��֯������200��֯�����Բ�ȥ200��֯ץȡ
					IF @Org=1001708020135665 AND (PATINDEX('%���%',@Name)>0) AND @Code<>'207030006' AND @Code<>'207030008'
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
				END --End While ������Ϊĸ��ʱ�����ĸ�����Ӧ����ϣ�ͨ����Чʱ�䣩
				CLOSE curBom
				DEALLOCATE curBom
				SET @curLv=@curLv+1
			END--End While ѭ������չBom
			INSERT INTO #Auctus_NewestBom
					SELECT * FROM #tempBom
			FETCH NEXT FROM curBOMMaster INTO @BomID,@QuanJi,@MasterCode
        END --End While
CLOSE curBOMMaster
DEALLOCATE curBOMMaster
END 

	

