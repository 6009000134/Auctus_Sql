declare	
	@PlanVersion  bigint=1001905311704959,
	@WorkCalendar bigint=1001708020000015,
	@Partition    int=0,
	@CurrentDate  date=getdate(),
	@errcode      nvarchar(300) 

BEGIN
		

/**********************************************************************************************************
-------------------------------------参数定义开始----------------------------------------------------------
**********************************************************************************************************/
	Declare @PlanMethod					int
	Declare @netchangeyn				bit	
	declare @StartDate                  datetime
	declare @EndDate                    datetime
	declare @TmpStartDate				datetime		--用于在Item为重复件时，获取工作日历用
	declare @TmpEndDate					datetime		--用于在Item为重复件时，获取工作日历用
	declare @TmpDemandDate              datetime
	declare @TmpSupplyDate              datetime
	declare @TmpOBaseUOM                bigint
	declare @TmpSMUOM                   bigint
	declare @TmpDayCount                int
	declare @TmpCount                   int
	declare @TmpSMQty                   decimal(24,9)
	declare @TmpBaseQty                 decimal(24,9)
	declare @TmpSUMBaseQty              decimal(24,9)
	declare @TmpDemandSMQty             decimal(24,9)
	declare @TmpDemandBaseQty           decimal(24,9)
	declare @TmpSUMSMQty                decimal(24,9)
	declare @TmpSupplySMQty             decimal(24,9)
	declare @TmpSupplyBaseQty			decimal(24,9)
	declare @TmpID                      bigint
	declare @TmpDate                    datetime
	declare @IsMPS                      bit
	declare @IsSafetyStock              bit
	declare @IsECN                      bit
	declare @IsCheckLoop                bit
	declare @IsLLC                      bit
	declare @MaxLLC                     int
	declare @Org                        bigint
	declare @IsSub                      int
	declare @TmpReturn                  int
	declare @IsLot                      bit
	declare @IsubsOptimization			int
	declare @IsMultiMPS                 BIT
	declare @whyn                       bit
	declare @dcyn						bit
	declare @StartDC					int 
	declare @EndDC						INT
	DECLARE @IsCleanRTDSInfo            bit

	--常量定义(最小/大优先级)
	declare @MinPri int
	declare @MaxPri int
	set @MinPri = 99;
	set @MaxPri = 0;
	--常量定义(计划类型)
	declare @MDS int
	declare @MPS int
	set @MDS = 0
	set @MPS = 1

	--常量定义(物料形态属性)
	declare @Repetitive int,
	        @Model int,
			@PTO			int,--PTO件
			@OPTIONCLASS	int, --选项类
            @PHANTOM        int  --虚拟件
			
	set @Repetitive = 21;
	set @PTO			= 1;
	set @OPTIONCLASS	= 3;
	set @Model = 0;
    set @PHANTOM=6;
    
    declare @Today datetime
    
    set @Today =cast(convert(nvarchar(20),getdate(),112) as datetime)

    declare @LastDate datetime

	--常量定义(计划方法)
	declare @PlanMethodMPS int
	set @PlanMethodMPS = 0
	declare @PlanMethodMRP int
	set @PlanMethodMRP = 1
	declare @PlanMethodDRP int
	set @PlanMethodDRP = 2
	declare @PlanMethodMPSDRP int
	set @PlanMethodMPSDRP = 3
	declare @PlanMethodMRPDRP int
	set @PlanMethodMRPDRP = 4	
	
	--物料计划方法
	declare @PlanType_MPS int
	declare @PlanType_MRP int
	declare @PlanType_DRP int
	declare @PlanType_MPSDRP int
	declare @PlanType_MRPDRP int
	
	set @PlanType_MPS = 0
	set @PlanType_MRP = 1
	set @PlanType_DRP = 3
	set @PlanType_MPSDRP = 4
	set @PlanType_MRPDRP = 5	


	--外部需求来源类型
	declare @SourceTypeMPS int
	set @SourceTypeMPS = 5
	
	declare @ProjectTaskObject int 
	set @ProjectTaskObject = 10000--下发对象为项目任务--吴峥于2009.04.03增加此参数
	declare @SupplierObject int 
	set @SupplierObject = 9--下发对象为厂牌--吴峥于2009.04.03增加此参数
	declare @SubStyleReplace int
	set @SubStyleReplace = 3--替代控制方式：替换，吴峥于2009.03.23增加此字段
	declare @ForecastOrder int
	set @ForecastOrder = 29 --预测订单需求

	--替代优化参数
	declare @IsSubsOptimization int
	declare @SyncRange int
	declare @isLRP bit
	declare @IsPlanOrderPL   bit;
	declare @planEOUScope bigint;
	declare @IsCalcByMPS	bit--按MPS料的计划订单直接计算  yanx于2014.10.08添加
	declare @IsConsiderOnRoad bit --考虑库存在途(调拨单),新计划模式
	declare @IsOnRoad bit --考虑库存在途(调拨单),老计划模式 by qinhjc on 20170408
	
	--原有逻辑中未对计划订单和调拨单进行存储地点过滤，现在预处理中加上by qinhjc on 20161223
	DECLARE @isNewPlanPattern BIT   --是否是新计划模式
	SET @isNewPlanPattern=0
	
    DECLARE @isWHOnlyControlStock INT --存储地点只控制库存
    SET @isWHOnlyControlStock=0

	--是否根据选配结果跑MRP
	declare @isCalcByConfigResult int;
	set @isCalcByConfigResult=0;

	--常量定义(子件发料方式)
	declare @IssueStylePhantom int
	set @IssueStylePhantom = 4 --虚拟件不发料

	declare @ConsiderIssueStylePhantom bit --考虑不发料子件
	set @ConsiderIssueStylePhantom=1

	--是否处理过期供应 By jiangjief 2019-02-18
	declare @isOverDemand bit  

 	declare @isOverSupply bit;
	set @isOverSupply = 0;
	declare @OverDateDays int;
	set @OverDateDays = 0;

/**********************************************************************************************************
-------------------------------------参数定义结束----------------------------------------------------------
**********************************************************************************************************/

/**********************************************************************************************************
-------------------------------------获取参数开始----------------------------------------------------------
**********************************************************************************************************/

	set @errcode = ''

	Select 
		@PlanMethod = B.[PlanMethod],@StartDate = B.[StartDate],@netchangeyn = A.[IsNetChange],
		@IsMPS = A.[IsMPS],@IsSafetyStock = A.[IsSafetyStock],@IsECN = A.[isECN],@IsCheckLoop = A.[IsCheckBOMLoop],
		@IsLLC = A.[IsReCalcLLC],@Org = B.[Org],@IsSub = ISNULL(A.IsSubst,0),@IsLot = A.[IsLot],@EndDate = B.[EndDate],
		@IsubsOptimization = A.IsSubsOptimization,
		@IsMultiMPS = A.[MultiLevelMPS],
		@IsSubsOptimization = isnull(A.[IsSubsOptimization],0),
		@SyncRange = isnull(A.[SyncRange],0),
		@whyn=[IsExecByWh],
		@dcyn = [IsDCRange],
		@StartDC= [StartDC], @EndDC=[EndDC]
		--LRP 
		,@isLRP = case B.PlanMethod when 5 then 1 else 0 end
		,@IsPlanOrderPL = A.IsPlanOrderPickList
		--PlanEOU
		,@planEOUScope = B.PlanScope
		,@IsCalcByMPS = (case when B.DescFlexField_PrivateDescSeg29 = '1' then 1 else 0 end)
		,@IsOnRoad=A.IsOnRoad --考虑库存在途(调拨单),老计划模式 by qinhjc on 20170408
		,@isOverDemand = b.IsOverDemand
	from MRP_PlanVersion A 
		inner join MRP_PlanName B on A.[PlanName] = B.[ID]
	Where A.[ID] = @PlanVersion;

	if (@@rowcount = 0)
	Begin
		return;
	End
	
	--201809070094 计划参数未勾选“考虑不发料BOM子项”，过滤掉不发料BOM子项 By jiangjief 2018-12-03
	select @ConsiderIssueStylePhantom=0 from MRP_PlanParams where PlanOrg=@Org and IsIssueStylePhantom is not null and IsIssueStylePhantom=0


	--是否启用实时追溯  yanx于2015.05.12添加
	declare @RTProfileID bigint;
	set @RTProfileID = 15064;
	declare @IsRTPegging bit;
	
	--V3可个性化出此参数并按组织同步参数档的值，改用ProfileValue进行判断  yanx于2015.03.17修改
	if exists (select top 1 0 from Base_ProfileValue where Profile = @RTProfileID and Value = 'true')
		set @IsRTPegging = 1;
	else
		set @IsRTPegging = 0;
	
	--LRP 预处理逻辑  yanx于2012.05.20添加
	if @isLRP = 1
	begin
		--不支持多重Output  yanx于2013.08.29修改
		exec @errcode = MRP_LRP_Pretreatment @PlanVersion,@WorkCalendar,@Partition,@CurrentDate;
		select @errcode;
	end

	declare @isGrossRequire bit;
	declare @IsItemWithConsigner bit;--是否考虑委托方带料需求
	select @MaxLLC = [MaxLLC],@isGrossRequire = isnull(IsGrossRequire,0)
		,@IsItemWithConsigner = IsItemWithConsigner,
		@IsConsiderOnRoad = IsConsiderOnRoad
		,@IsCleanRTDSInfo=IsCleanRTDSInfo
		,@isOverSupply = MRP0062
		,@OverDateDays = OverDateDays
	from MRP_PlanParams where [PlanOrg] = @Org;

	if (@@rowcount = 0)
	Begin
		set @MaxLLC = 0
	END
	
	--是否启用增强计划运算  By jiangjief 2022-02-25
	--当客户未启用增强计划运算，且没有操作保存过参数设置，不会触发数据同步逻辑，部分参数需要从profile中获取
	--如是否考虑过期供应（@MRP0062）
	declare @MRP018_ID bigint;
	set @MRP018_ID = 20031;
	declare @MRP018 bit;
	set @MRP018 = 0;

	if exists (select top 1 0 from Base_ProfileValue where Profile = @MRP018_ID and Value = 'true')
	begin
		set @MRP018 = 1;	
	end
		
	if(@MRP018 = 1)
	begin
		--202202240030 是否考虑过期供应
		declare @MRP0062_ID bigint;
		set @MRP0062_ID = 20031;

		if exists (select top 1 0 from Base_ProfileValue where Profile = @MRP0062_ID and Value = 'true')
		begin
			set @isOverSupply = 1;	
		end
		else
		begin
			set @isOverSupply = 0;	
		end
	end

	--是否为新计划模式
    SELECT @isNewPlanPattern=COUNT(*)
    FROM MRP_PlanVersion A 
    INNER JOIN MRP_PlanName B ON A.PlanName=B.ID
    inner JOIN MRP_PlanEOUScope C ON C.ID =B.PlanScope
    WHERE A.ID=@PlanVersion;
    
    --存储地点只控制库存
	IF(@isNewPlanPattern<>0)
	begin
	SELECT @isWHOnlyControlStock=isnull(E.IsWHOnlyControlStock,0)  
            FROM MRP_PlanVersion A 
            left JOIN MRP_PlanName B ON A.PlanName=B.ID
			left JOIN MRP_PlanEOUScope C ON C.ID =B.PlanScope
            left JOIN MRP_PlanEOUScopeRegion D ON D.PlanEOUScope=C.ID AND D.PlanEOURegion IS NOT NULL
            left JOIN MRP_PlanEOURegion E ON E.ID=D.PlanEOURegion
			WHERE A.ID=@PlanVersion; 
	end
			
	--老计划模式从计划方案中找存储地点只控制库存参数
	IF(@isNewPlanPattern=0)
	BEGIN
	SELECT @isWHOnlyControlStock=isnull(B.IsWHOnlyControlStock,0)
	FROM MRP_PlanName A
	INNER JOIN MRP_PlanStrategy B ON B.ID=A.PlanStrategy
	INNER JOIN MRP_PlanVersion C ON C.PlanName=A.ID
	WHERE A.IsExecByPlanStrategy=1 AND C.ID=@PlanVersion
	END
/**********************************************************************************************************
-------------------------------------获取参数结束----------------------------------------------------------
**********************************************************************************************************/

/**********************************************************************************************************
-------------------------------------创建处理日志----------------------------------------------------------
**********************************************************************************************************/

    delete from [MRP_ProcessLog] where [LogType]=0
    insert into [MRP_ProcessLog] values(@planversion,0,1,getdate(),'1900-1-1',0) 
    set @LastDate=getdate();
/**********************************************************************************************************
-------------------------------------根据选配结果写入BOM快照数据----------------------------------------------------------
**********************************************************************************************************/
	--根据选配结果跑计划
	exec MRP_GetConfigResult @PlanVersion;
	

--是否根据选配结果跑LRP
	select @isCalcByConfigResult=count(0)
	from MRP_BOMMapping_Temp A
	where A.PlanVersion=@PlanVersion and ConfigResultID>1;
/**********************************************************************************************************
------------------------------删除非最后生产线的PLS产出，库存----------------------------------------------
**********************************************************************************************************/
	if object_id('tempdb.dbo.#Tmp_ItemProductionLine') is null
		create table #Tmp_ItemProductionLine
		(
			[PlanVersion] [bigint] NULL,
			[ProductLine] [bigint] NULL,
			[Item] [bigint] NULL,
			[Seq] [int] NULL
        )

	insert into #Tmp_ItemProductionLine
	(
		[PlanVersion],[Item],[Seq],[ProductLine]
	)
	select 
		A.planversion,A.item,A.seq,A.[ProductionLine]
	from MRP_ItemProductionLineMapping_Temp A 
		inner join 
		(
			select item,max(seq) as seq 
				from MRP_ItemProductionLineMapping_Temp where planversion=@PlanVersion
			group by org,item,planversion
		) B on A.item=B.item and A.seq=B.seq
    where A.planversion=@PlanVersion

--没有必要的赋值--吴峥于2009.09.05注释
--	update A 
--		set A.[ProductLine]=B.[ProductionLine]
--	from #Tmp_ItemProductionLine A, MRP_ItemProductionLineMapping_Temp B
--	where A.org=B.org and A.item=B.item 
--		and A.seq=B.seq and A.pri=B.pri 
--		and A.planversion=B.planversion 
--		and A.planversion=@PlanVersion

    delete [MRP_ItemCurQtyMapping_Temp] 
    --添加条件 and [ProductLine] > 0  yanx于2011.08.17修改
    where [ProductLine] is not null and [ProductLine] > 0
		and [ProductLine] not in(select [ProductLine] from #Tmp_ItemProductionLine)
		and planversion=@PlanVersion
    
    delete [MRP_RepMapping_Temp] 
    where [ProductLine] not in(select [ProductLine] from #Tmp_ItemProductionLine)
		and planversion=@PlanVersion

    drop table #Tmp_ItemProductionLine

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=1
    insert into [MRP_ProcessLog] values(@planversion,0,2,getdate(),'1900-1-1',0)  
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------如果计划方法为MRP，则展开MPS的子件需求---------------------------------------
------------------------------MPS子件需求改在净算过程中产生，吴峥于2010.03.17修改--------------------------
**********************************************************************************************************/
--	--展开MPS过程会产生DI，所以要在ProcessDI过程之前做
--	if (@PlanMethod in (@PlanMethodMRP,@PlanMethodMRPDRP))
--	begin
--		delete from MRP_DemandInterfaceMapping_Temp where [PlanVersion] = @PlanVersion and [SourceType] = @SourceTypeMPS;
--		exec MRP_GenDependentDemandByMPS @PlanVersion,@WorkCalendar;
--	end

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=2
    insert into [MRP_ProcessLog] values(@planversion,0,3,getdate(),'1900-1-1',0)  
    set @LastDate=getdate()  

/**********************************************************************************************************
------------------------------处理DI中[BOMComponent]不为空的记录(取替代件、供应商及UTE记录)----------------
**********************************************************************************************************/
	--ProcessDI过程会产生新的BOM，所以要在ProcessECNBOM过程之前做
	set @TmpDate = getdate()
	exec MRP_ProcessDI @PlanVersion,@TmpDate,@Partition;	

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=3
    insert into [MRP_ProcessLog] values(@planversion,0,4,getdate(),'1900-1-1',0)
    set @LastDate=getdate()


/**********************************************************************************************************
------------------------------收集BOM阶梯损耗，吴峥于2009.11.03增加此逻辑----------------------------------
**********************************************************************************************************/

	exec [MRP_GetBOMStepScrap] @PlanVersion

/**********************************************************************************************************
------------------------------删除优化结果集合，吴峥于2009.11.11增加此逻辑---------------------------------
**********************************************************************************************************/

	delete from [MRP_OptimizationResult] where Planversion = @Planversion

/**********************************************************************************************************
------------------------------收集厂牌信息，吴峥于2009.11.17增加此逻辑------------------------------------
**********************************************************************************************************/

	exec [MRP_GetSupplier] @Planversion,0,'1900-1-1',0,0,0

/**********************************************************************************************************
------------------------------处理ECNBOM与ECNRouting-------------------------------------------------------
**********************************************************************************************************/
	if (@IsECN = 1)
	begin
		execute MRP_ProcessECNBOM @PlanVersion;	
		execute MRP_ProcessECNRouting @PlanVersion;
	end

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=4
    insert into [MRP_ProcessLog] values(@planversion,0,5,getdate(),'1900-1-1',0) 
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------处理低阶码计算---------------------------------------------------------------
**********************************************************************************************************/
	
	if (@IsCheckLoop = 1 or @IsLLC = 1 or @isCalcByConfigResult>0)
	begin
		exec @TmpReturn = MRP_CalcItemLLCByMapping @PlanVersion,@MaxLLC,@IsLLC,@IsSub;
		if (@TmpReturn < 0)
		begin
			select @errcode = '-1'
			
		end
		--sylviahj 07.08.06 更新BOM展开映像上的LLC，净算使用
		update A 
			set A.[LLC] = B.[LowLevelCode]
		from MRP_BOMMapping_Temp A 
			inner join MRP_ExpandItemMapping_Temp B on A.[PlanVersion] = B.[PlanVersion] 
												and A.[BOMMasterItem] = B.[Item]
												and A.[Org] = B.[Org] 
												and A.planversion=@PlanVersion;
	end

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=5
    insert into [MRP_ProcessLog] values(@planversion,0,6,getdate(),'1900-1-1',0)    
    set @LastDate=getdate()

/**********************************************************************************************************
--------------------------------独立需求DTF处理------------------------------------------------------------
--------------------------------调用[独立需求DTF处理(@PlanVersion)]----------------------------------------
**********************************************************************************************************/

	exec MRP_ProcessDTFRule @PlanVersion

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=6
    insert into [MRP_ProcessLog] values(@planversion,0,7,getdate(),'1900-1-1',0)     
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------处理BOM中的model/opt等及UTE,该部分已经废弃-----------------------------------
------------------------------model/opt已经不用跳层，UTE在BOM收集的时候处理，吴峥于2009.09.05注释----------
**********************************************************************************************************/

	--处理BOM中的model/opt等及UTE
--	exec MRP_ProcessBOM @PlanVersion,1,1,@WorkCalendar;
	--产生一年的生产线日能力记录
	--sylviahj 07.08.16 由于重复排产算法调整，不用再产生一年的日能力记录了
--	exec MRP_GenPLDailyCap @PlanVersion,@Partition;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=7
    insert into [MRP_ProcessLog] values(@planversion,0,8,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------产生无备料的MO的备料需求-----------------------------------------------------
------------------------------产生无备料的MO的备料需求改在净算中进行实现，吴峥于2010.03.25修改-------------
**********************************************************************************************************/

--	exec MRP_GetNoPickListMOComponent @PlanVersion,@Partition,@Workcalendar,1,1;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=8
    insert into [MRP_ProcessLog] values(@planversion,0,9,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/***********************************************************************************************************
-----------------------------去掉预处理展开MDS的逻辑,吴峥于2009.05.31去掉此逻辑-----------------------------
***********************************************************************************************************/
	--对MDS中的MODEL/OPT/KIT等物料做子件展开处理
	--execute MRP_OpDemandExpand @PlanVersion,@WorkCalendar;	

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=9
    insert into [MRP_ProcessLog] values(@planversion,0,10,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------MO预计产出，Rep预计产出------------------------------------------------------
------------------------------由于读取MO的预计可供应量不再需要倒扣，吴峥于2010.06.09-----------------------
**********************************************************************************************************/
--	--MO预计产出
--	execute MRP_ProcessMOOutPut @PlanVersion;
--
--    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
--    where planversion=@planversion and [LogType]=0 and [Number]=10
--    insert into [MRP_ProcessLog] values(@planversion,0,11,getdate(),'1900-1-1',0)
--    set @LastDate=getdate()
--	--Rep预计产出
--	execute MRP_ProcessRepOutPut @PlanVersion;
--	
--    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
--    where planversion=@planversion and [LogType]=0 and [Number]=11
--    insert into [MRP_ProcessLog] values(@planversion,0,12,getdate(),'1900-1-1',0)
--    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------处理物料优先级---------------------------------------------------------------
**********************************************************************************************************/

	declare @itemcode nvarchar(255)
	execute MRP_GenItemPri @PlanVersion,@itemcode = @itemcode output;
	if @itemcode <> ''
	begin
		select @errcode = '-2,' + @itemcode
		
	end

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=12
    insert into [MRP_ProcessLog] values(@planversion,0,13,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------收集库存异动信息，吴峥于2009.11.09增加此逻辑----------------------------------
**********************************************************************************************************/

	if (@IsubsOptimization <> 0)
	Begin
		exec [MRP_GetINVTrans] @PlanVersion
	End

/**********************************************************************************************************
------------------------------收集MO子件厂牌，吴峥于2009.11.09增加此逻辑-----------------------------------
**********************************************************************************************************/

	exec [MRP_GetMOPickSupplier] @PlanVersion


/**********************************************************************************************************
------------------------------收集生产期间，吴峥于2010.05.19增加此逻辑-----------------------------------
**********************************************************************************************************/

	exec [MRP_GetProductPeriod] @PlanVersion

/**********************************************************************************************************
------------------------------删除销售映像中model物料的需求------------------------------------------------
**********************************************************************************************************/
	--删除销售映像中model物料的需求
	delete A from MRP_SOMapping_Temp A inner join MRP_ExpandItemMapping_Temp B
	on A.Item = B.Item and A.PlanVersion = B.PlanVersion
	where A.PlanVersion = @PlanVersion and B.ItemType = @Model;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=13
    insert into [MRP_ProcessLog] values(@planversion,0,14,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------根据是否为净改变删除相应的记录-----------------------------------------------
**********************************************************************************************************/

	--清除模拟计划订单/外部需求/DTE临时表记录
	--sylviahj 07.07.11 清除该计划版本上次产生的外部需求来源记录
	--sylviahj 07.07.12 如果为净改变，则只删除净改变物料的外部需求来源记录
	if (@netchangeyn = 0)
		delete A from MRP_DemandInterface A inner join MRP_SimuDemandInterface B on
		A.[SimuDemandInterface] = B.[ID]
		where B.[PlanVersion] = @PlanVersion;
	else
		delete A from MRP_DemandInterface A inner join MRP_SimuDemandInterface B on
		A.[SimuDemandInterface] = B.[ID] inner join MRP_SimuPlanOrder Z on 
		B.[SourceDocNo] = Z.[DocNo] and B.[PlanVersion] = Z.[PlanVersion]
		inner join MRP_ExpandItemMapping_Temp C on
		Z.[PlantOrg] = C.[Org] and Z.[Item] = C.[Item] and Z.[PlanVersion] = C.[PlanVersion]
		where B.[PlanVersion] = @PlanVersion;

	--sylviahj 07.07.11 如果是净改变，只删除在物料映像Temp表中存在的物料的模拟计划订单
	if (@netchangeyn = 0)
	begin
		delete from MRP_SimuPlanOrder where [PlanVersion] = @PlanVersion;
		delete from MRP_SimuPlanOrderPickList where [PlanVersion] = @PlanVersion;
	end
	else
		delete A from MRP_SimuPlanOrder A inner join MRP_ExpandItemMapping_Temp B on A.[PlantOrg] = B.[Org]
		and A.[Item] = B.[Item] and A.[PlanVersion] = B.[PlanVersion]
		where A.[PlanVersion] = @PlanVersion;


    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=14
    insert into [MRP_ProcessLog] values(@planversion,0,15,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--sylviahj 07.07.11 清除毛需求、供需资料、重排建议、供需追溯表记录
	--sylviahj 07.08.06 删除模拟库存规划
	if (@netchangeyn = 0)
	begin
		delete from MRP_GrossRequirement where [PlanVersion] = @PlanVersion;
		delete from MRP_DSInfo where [PlanVersion] = @PlanVersion;
		delete from MRP_Reschedule where [PlanVersion] = @PlanVersion;
		delete from MRP_DSTree where [PlanVersion] = @PlanVersion;
		delete from MRP_SimuInventoryPlan where [PlanVersion] = @PlanVersion;
		delete from MRP_SimuMDS where [PlanVersion] = @PlanVersion;
	end
	else
	begin
		delete A from MRP_GrossRequirement A inner join MRP_ExpandItemMapping_Temp B on A.[FactoryOrg] = B.[Org]
		and A.[Item] = B.[Item] and A.[PlanVersion] = B.[PlanVersion]
		where A.[PlanVersion] = @PlanVersion;
		delete A from MRP_DSInfo A inner join MRP_ExpandItemMapping_Temp B on A.[FactoryOrg] = B.[Org]
		and A.[Item] = B.[Item] and A.[PlanVersion] = B.[PlanVersion]
		where A.[PlanVersion] = @PlanVersion;
		delete A from MRP_Reschedule A inner join MRP_ExpandItemMapping_Temp B on A.[Org] = B.[Org]
		and A.[Item] = B.[Item] and A.[PlanVersion] = B.[PlanVersion]
		where A.[PlanVersion] = @PlanVersion;
		delete A from MRP_DSTree A inner join MRP_DSInfo B on A.[DSInfo] = B.[ID] and A.[PlanVersion] = B.[PlanVersion]
		inner join MRP_ExpandItemMapping_Temp C on B.[FactoryOrg] = C.[Org]
		and B.[Item] = C.[Item] and B.[PlanVersion] = C.[PlanVersion]
		where A.[PlanVersion] = @PlanVersion;
		delete A from MRP_SimuMDS A inner join MRP_ExpandItemMapping_Temp B on A.Org = B.[Org]
		and A.[Item] = B.[Item] and A.[PlanVersion] = B.[PlanVersion]
		where A.[PlanVersion] = @PlanVersion;		
	end

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=15
    insert into [MRP_ProcessLog] values(@planversion,0,16,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------删除错误信息表、模拟计划订单以及UTEDATE--------------------------------------
**********************************************************************************************************/

	delete from MRP_ErrorMsg where [PlanVersion] = @PlanVersion;
	delete from MRP_SimuDemandInterface where [PlanVersion] = @PlanVersion;
	delete from mrp_utedate_temp where [PlanVersion] = @PlanVersion;	

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=16
    insert into [MRP_ProcessLog] values(@planversion,0,17,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------在此处删除未锁定的MPS，不考虑是否主版本，是否考虑MPS-------------------------
------------------------------删除模型间PO、SO-------------------------------------------------------------
**********************************************************************************************************/

	if (@PlanMethod = @PlanMethodMPS)
	begin
	    delete B from MRP_MPS A inner join MRP_MPSDetail B on A.[ID] = B.[MPS]
		where A.[PlanVersion] = @PlanVersion and B.[IsFirmed] = 0;
			
	    delete from MRP_MPS where [PlanVersion] = @PlanVersion and not exists(select 0
		from MRP_MPSDetail A where MRP_MPS.ID = A.[MPS]);
	end

    delete A from MRP_POMapping_Temp A inner join MRP_ExpandItemMapping_Temp B 
    on A.[Item]=B.[Item]
    where B.[ItemType] in (@Model,@PTO,@OPTIONCLASS) and A.[PlanVersion] = @PlanVersion

    delete A from  MRP_SOMapping_Temp A inner join MRP_ExpandItemMapping_Temp B
    on A.[Item]=B.[Item]
    where B.[ItemType] in (@Model,@PTO,@OPTIONCLASS) and A.[PlanVersion] = @PlanVersion
    
/**********************************************************************************************************
-----------------------------把MRP_ChannelQohMapping的数据导入MRP_ChannelQohMapping_Temp，然后删除---------
-----------------------------MRP_ChannelQohMapping的数据---------------------------------------------------
**********************************************************************************************************/  
    --lujj 09.06.10 把MRP_ChannelQohMapping的数据导入MRP_ChannelQohMapping_Temp，然后删除
    --MRP_ChannelQohMapping的数据
    delete from MRP_ChannelQohMapping_Temp where PlanVersion= @PlanVersion
    INSERT INTO [MRP_ChannelQohMapping_Temp]
           ([PlanVersion],[Org],[Item],[ItemVersion],[FromDegree],[ToDegree],[FromPotency]
           ,[ToPotency],[Vendor],[Location],[OwnerOrg],[Project],[Task],[Seiban],[DemandCode]
           ,[TradeQty],[TradeUOM],[INVUOM],[INVQty])
    select  [PlanVersion],[Org],[Item],[ItemVersion],[FromDegree],[ToDegree],[FromPotency]
           ,[ToPotency],[Vendor],[Location],[OwnerOrg],[Project],[Task],[Seiban],[DemandCode]
           ,[TradeQty],[TradeUOM],[INVUOM],[INVQty]
    from MRP_ChannelQohMapping where PlanVersion= @PlanVersion
   
    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=17
    insert into [MRP_ProcessLog] values(@planversion,0,18,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
------------------------------所有需求写入需求暂存表开始---------------------------------------------------
**********************************************************************************************************/

    --因为预处理前事件可能客开增加需求，所以这里不做删除 By jiangjief 2021-11-14
	--删除当前计划版本的需求暂存记录
	--delete from Mrp_DemandTemp where [PlanVersion] = @PlanVersion;
--	select @TmpDate = A.[StartDate]
--	from MRP_PlanName A inner join MRP_PlanVersion B on A.[ID] = B.[PlanName]
--	where B.[ID] = @PlanVersion

	--销售订单映像写入需求暂存表
	Insert Into MRP_DemandTemp
	(	
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[IsCurrentOrgShip]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
		,[InnerSupersede]
		,[ConfigResultID] --选配结果ID by qinhjc on 20170209
		,[BusinessDate] --SO业务日期 By jiangjief 2020-10-19
	)
	Select 		
		A.[Saleorg]
		,A.[Factoryorg]
		,A.[Item]		
		,A.[ItemVersion]		
		,A.[FromDegree]
		,A.[ToDegree]		
		,A.[FromPotency]
		,A.[ToPotency]
		,A.[Warehouse]
		,A.[Lot]
		,A.[Supplier]
		,A.[DemandCode]
		,0							-- DemandType， 0 表示独立需求 ，1表示相依需求
		,A.[SaleBaseUOM]
		,A.[SaleBaseQty]
		,A.[StoreMainUOM]
		,A.[DemandSMQty]
		,A.[DemandDate]
		,0
		,0
		,0							-- DemandSource 需求来源 ，0 内部，1 外部
		,case when A.[DocType] in(0,4) then 10 when A.[DocType] in(1,5) then 1 when A.[DocType] in(2,6) then 7 end
		,A.[PlanLine]
		,A.[PRI]
		,A.[DemandSMQty]
		,A.[WorkCalendarDemandDate]
		,A.[PlanVersion]
		,0
		,0
		,A.[IsFirm]
		,A.[DocVersion]
		,isnull(A.[DocNo],'')
		,A.[PlanLineNum]
		,A.[LineNum]
		,A.[OwnerOrg]
		,A.[Project]
		,A.[Task]
		,null
		,0
		,A.[ReserveQty]
		,null
		,null
		,null
		,''
		,''
		,0
		,0
		,A.[IsSecurityStock]
		,case when A.[DemandTransformType] in(1,4) then 1 else 0 end --1-跨组织出货2-当前组织出货
		,A.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,A.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.[SOHeader]
		,A.[InnerSupersede]
		,A.[ConfigResultID]
		,A.[BusinessDate]
	from MRP_SOMapping_Temp A 
--		inner join MRP_ExpandItemMapping_Temp B on A.[Item] = B.[Item] 
--											and A.[PlanVersion] = B.[PlanVersion]
--											--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
--											and B.[Org] = A.[Factoryorg]
	Where A.PlanVersion = @PlanVersion 
		and A.[DemandSMQty] > 0
	
	--WBS映像写入需求暂存表
	Insert Into MRP_DemandTemp
	(	
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[EarlyStartDate] 
	    ,[LateStartDate] 	
	    ,[ScheduleRoundType] 
	    ,[TotalScaling]	
	    ,[WBSTask]
		,[originalDemandHeader]
		,[TaskType]
		,[BusinessAction]
		--累计使用量  yanx于2012.04.10添加
		,WBSTotalUsedQty
	)
	Select 		
		A.Org,A.ExecuteOrg,A.ItemInfo_ItemID ,A.ItemInfo_ItemVersion,A.ItemInfo_ItemGrade,A.ItemInfo_ItemGrade 		
		,A.ItemInfo_ItemPotency,A.ItemInfo_ItemPotency,A.WareHouse,'',A.[Supplier],-1
		,0							-- DemandType， 
		,A.UOM ,A.TradeQty,A.InvUOM,A.InvQty,A.ProjOutputDate,0,0
		,0							-- DemandSource 需求来源 ，0 内部，1 外部
		,25                        -- originalDemandStatus， 25 WBSDemand,27项目需求
		,A.TaskOutput_EntityID,0,A.InvQty,A.ProjOutputDate,A.[PlanVersion],0,0,0 --是否锁定
		,'','0','0','0',A.[OwnerOrg],A.[Project],A.[Task],null,0,0,null,null,null,'','',0,0,B.[IsSecurityStock]
		,A.TaskEarlyStartDate,A.TaskLateStartDate,isnull(A.[ScheduleRoundType],0),ISNULL(A.[TotalScaling],1),A.[WBSTask],0,A.TaskType,A.BusinessAction
		--累计使用量  yanx于2012.04.10添加
		,A.TotalUsedQty
	from MRP_WBSMapping_Temp A 
	inner join MRP_ExpandItemMapping_Temp B on A.ItemInfo_ItemID = B.[Item] and A.[PlanVersion] = B.[PlanVersion]
	--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
	and B.[Org] = A.ExecuteOrg 
	Where A.PlanVersion = @PlanVersion and A.TradeQty > 0 and A.[DSInfoDocType]=25 
	
	--WBS映像写入需求暂存表
	Insert Into MRP_DemandTemp
	(	
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[EarlyStartDate] 
	    ,[LateStartDate] 	
	    ,[ScheduleRoundType] 
	    ,[TotalScaling]	
	    ,[WBSTask]
		,[originalDemandHeader]
		,[BusinessAction]
	)
	Select 		
		A.Org,case when A.BusinessAction =1 then A.Org else A.ExecuteOrg end,--lujj 2010.1.9 WBS需求要根据类型来确定工厂组织哦。 1：采购 2：制造
		A.ItemInfo_ItemID ,A.ItemInfo_ItemVersion,A.ItemInfo_ItemGrade,A.ItemInfo_ItemGrade
		,A.ItemInfo_ItemPotency,A.ItemInfo_ItemPotency,A.WareHouse,'',A.[Supplier],-1
		,0							-- DemandType， 
		,A.UOM ,A.TradeQty ,A.InvUOM,A.InvQty,A.ProjOutputDate,0,0
		,0							-- DemandSource 需求来源 ，0 内部，1 外部
		,27                        -- originalDemandStatus， 25 WBSDemand,27项目需求
		,A.TaskOutput_EntityID,0,A.InvQty,A.ProjOutputDate,A.[PlanVersion],0,0,0 --是否锁定
		,'','0','0','0',isnull(A.[OwnerOrg], (case when A.BusinessAction =1 then A.Org else A.ExecuteOrg end)),A.[Project],A.[Task],null,0,0,null,null,null,'','',0,0,B.[IsSecurityStock]
		,A.TaskEarlyStartDate,A.TaskLateStartDate,isnull(A.[ScheduleRoundType],0)
		,ISNULL(A.[TotalScaling],1),A.[WBSTask],0,A.[BusinessAction]
	from MRP_WBSMapping_Temp A 
	inner join MRP_ExpandItemMapping_Temp B on A.ItemInfo_ItemID = B.[Item] and A.[PlanVersion] = B.[PlanVersion]
	--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
	and B.[Org] = A.ExecuteOrg 
	Where A.PlanVersion = @PlanVersion --and A.ProjQty -A.CompleteQty > 0 
	and  A.[DSInfoDocType]=27

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=18
    insert into [MRP_ProcessLog] values(@planversion,0,19,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--预测映像写入需求暂存表
	Insert Into MRP_DemandTemp
	(
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
	)
	Select 
		A.[Saleorg]
		,A.[Factoryorg]
		,A.[Item]		
		,A.[ItemVersion]
		,A.[FromDegree]
		,A.[ToDegree]
		,A.[FromPotency]
		,A.[ToPotency]
		--如果销售组织与工厂组织不同则清空存储地点--吴峥于2010.11.16修改
		,(case when A.[Saleorg] = A.[Factoryorg] then A.[WareHouse] else 0 end)
		,A.[Lot]
		,A.[Supplier]
		,A.[DemandCode]
		,0						-- DemandType 
		,A.[SaleUOM]
		,A.[DemandSaleUOMQty]
		,A.[StoreMainUOM]
		,A.[DemandSMUOMQty]
		,A.[DemandDate]
		,A.[ProcessingDays]
		,A.[DailyCapacity]
		,0						--DemandSource
		,2
		,A.[ForecastLine]		
		,@MinPri
		,A.[DemandSMUOMQty]
		,A.[WorkCalendarDemandDate]
		,A.[PlanVersion]
		,0
		,0
		,0					-- IsFirm
		,A.[ForecastDocVersion]
		,isnull(A.[ForecastDocNo],'')
		,0
		,A.[LineNum]
		,A.[OwnerOrg]
		,A.[Project]
		,A.[Task]
		,null
		,0
		,0
		,null
		,null
		,null
		,''
		,''
		,0
		,0
		,B.[IsSecurityStock]
		,A.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,A.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.[ForecastHeader]
	from MRP_ForecastMapping_Temp A 
		inner join MRP_ExpandItemMapping_Temp B on A.[Item] = B.[Item] 
											and A.[PlanVersion] = B.[PlanVersion]
											--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
											and A.[Factoryorg] = B.[Org]
	Where A.PlanVersion = @PlanVersion and A.[DemandSMUOMQty] > 0
	
	update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=18
    insert into [MRP_ProcessLog] values(@planversion,0,19,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--预测订单映像写入需求暂存表
	Insert Into MRP_DemandTemp
	(
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		--,[IsSecurityStock]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
		,[ForecastOrderType]
	)
	Select 
		A.[Saleorg]
		,A.[SupplyOrg]
		,A.[Item]		
		,A.[ItemVersion]
		,A.[FromDegree]
		,A.[ToDegree]
		,A.[FromPotency]
		,A.[ToPotency]
		,0
		,A.[Lot]
		,A.[MFC]
		,A.[DemandCode]
		,0						-- DemandType 
		,A.[TradeUOM]
		,A.[DemandTUQty]
		,A.[INVUOM]
		,A.[DemandQty]
		,A.[ShipplanDate]
		,0
		,0
		,0						--DemandSource
		,@ForecastOrder         --OriginalDemandStatus
		,A.[FOLineID]
		,@MinPri
		,A.[DemandQty]
		,A.[WorkCalendarDemandDate]
		,A.[PlanVersion]
		,0
		,0
		,0					-- IsFirm
		,''
		,isnull(A.[DocNo],'')
		,0
		,A.[DocLineNo]
		,A.OwnerOrg --预订单增加货主组织  yanx于2014.08.08添加
		,A.[Project]
		,0
		,null
		,0
		,0
		,null
		,null
		,null
		,''
		,''
		,0
		,0		
		,A.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,A.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.[FOHeaderID]
		,case when (A.IsPreSend=1 and A.IsPrePick=1) then 2
		when (A.IsPreSend=1 and A.IsPrePick=0) then 0
		when (A.IsPreSend=0 and A.IsPrePick=1) then 1
		else -1 end
	from MRP_ForecastOrderMapping_Temp A 		
	Where A.PlanVersion = @PlanVersion and A.[DemandQty] > 0


    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=19
    insert into [MRP_ProcessLog] values(@planversion,0,20,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--主计划映像中已展开=否的资料写入需求暂存表	
	--先处理非重复物料或为重复性物料，但开始日期=结束日期的记录
	Insert Into MRP_DemandTemp
	(
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
		,[SrcWareHouse]
	)
	Select 
		t1.[org]
		,t1.[org]		
		,t1.[Item]		
		,t1.[ItemVersion]
		,t1.[fromDegree]
		,t1.[ToDegree]
		,t1.[fromPotency]
		,t1.[ToPotency]
		,t1.[WareHouse]
		,t1.[Lot]
		,t1.[Supplier]
		,t1.[DemandCode]
		,0
		,t1.[OBaseUOM]
		,t1.[DemandBaseQty]
		,t1.[StoreMainUOM]
		,t1.[DemandSMQty]
		,t1.[originalDSDate]
		,case t1.[ItemType] when @Repetitive then 1 else 0 end
		,case t1.[ItemType] when @Repetitive then t1.[DemandSMQty] else 0 end
		,0
		,3					--MDS
		,t1.[MasterPlanDetail]
		,t1.[PRI]
		,t1.[DemandSMQty]
		,t1.[WorkCalendarDSDate]
		,t1.[PlanVersion]
		,0
		,0
		,t1.[IsFirm]
		,t1.[SourceDocVersion]
		,isnull(t1.[SourceDocNo],'')
		,t1.[SourceDocPlanLineNum]
		,t1.[SourceDocLineNum]
		,t1.[OwnerOrg]
		,t1.[Project]
		,t1.[Task]
		,null
		,0
		,0
		,t1.[PreDemandLine]
		,t1.[PreLevelItemOrg]
		,t1.[PreLevelItem]
		,t1.[PreDocNo]
		,t1.[PreDocVersion]
		,t1.[PreDocLineNum]
		,t1.[PreDocPlanLineNum]
		,t1.[IsSecurityStock]
		,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,t1.[MasterPlan]
		,t1.[SrcWareHouse]
	from [MRP_MPMapping_Temp] t1
--		inner join [MRP_ExpandItemMapping_temp] t2 on t1.[PlanVersion] = t2.[PlanVersion] 
--													and t1.[org] = t2.[org] 
--													and t1.[Item] = t2.[Item]
	Where t1.[IsExpanded] = 0 
		and t1.[PlanVersion] = @PlanVersion and t1.[PlanType] = @MDS --只读MDS计划
		and (t1.[ItemType] <> @Repetitive 
			or (t1.[ItemType] = @Repetitive and t1.[WorkCalendarDSDate] = t1.[WorkCalendarEndDSDate]))

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=20
    insert into [MRP_ProcessLog] values(@planversion,0,21,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--处理重复件(开始日期<>结束日期)
	declare MPProcessRep cursor for
	select 
		t1.[WorkCalendarDSDate],t1.[WorkCalendarEndDSDate],t1.[OBaseUOM],t1.[StoreMainUOM],t1.[DemandSMQty],
		t1.[DemandBaseQty],t1.[ID],Y.[WorkCalendar]
	from [MRP_MPMapping_Temp] t1
--		inner join [MRP_ExpandItemMapping_temp] t2 on t1.[PlanVersion] = t2.[PlanVersion] 
--												and t1.[org] = t2.[org] 
--												and t1.[Item] = t2.[Item]
		inner join Base_Organization Y on t1.[Org] = Y.[ID]
	Where t1.[IsExpanded] = 0 
		and t1.[PlanVersion] = @PlanVersion and t1.[PlanType] = @MDS --只读MDS计划
		and t1.[ItemType] = @Repetitive and t1.[WorkCalendarDSDate] <> t1.[WorkCalendarEndDSDate];
	open MPProcessRep;
	fetch next from MPProcessRep into @TmpStartDate,@TmpEndDate,@TmpOBaseUOM,@TmpSMUOM,@TmpDemandSMQty,@TmpDemandBaseQty,@TmpID,@WorkCalendar;
	
	while(@@fetch_status = 0)
	begin
		--计算开始日期到结束日期之间的工作日天数
		set @TmpDayCount = dbo.fn_MRP_GetIntervalWorkDays(@TmpStartDate,@TmpEndDate,@WorkCalendar);
		set @TmpCount = 1
		set @TmpSMQty = 0
		set @TmpBaseQty = 0
		set @TmpSUMSMQty = 0
		set @TmpSUMBaseQty = 0

		while (@TmpCount <= @TmpDayCount)
		begin
			set @TmpDemandDate = dbo.fn_MRP_GetWorkDate(@WorkCalendar,@TmpStartDate,@TmpCount,1);
			if (@TmpCount < @TmpDayCount)
			begin
			--如果不是最后一次循环,则数量=@TmpDemandSMQty / @TmpDayCount,否则数量=@TmpDemandSMQty - 前几次循环的数量和
				if @TmpSMQty = 0
					set @TmpSMQty = dbo.fn_MRP_GetRoundValue(@TmpSMUOM,@TmpDemandSMQty / @TmpDayCount);
				if @TmpBaseQty = 0
					set @TmpBaseQty = dbo.fn_MRP_GetRoundValue(@TmpOBaseUOM,@TmpDemandBaseQty / @TmpDayCount);
				set @TmpSUMSMQty = @TmpSUMSMQty + @TmpSMQty
				set @TmpSUMBaseQty = @TmpSUMBaseQty + @TmpBaseQty
				Insert Into MRP_DemandTemp
				(
					[org]
					,[Factoryorg]
					,[Item]		
					,[ItemVersion]
					,[FromDegree]
					,[ToDegree]
					,[FromPotency]
					,[ToPotency]
					,[WareHouse]
					,[Lot]
					,[Supplier]
					,[DemandCode]
					,[DemandType]
					,[TradeUOM]
					,[TradeQty]
					,[INVUOM]
					,[DemandQty]
					,[DemandDate]
					,[ProcessingDays]
					,[DailyCapacity]
					,[DemandSource]
					,[originalDemandStatus]
					,[originalDemand]
					,[PRI]
					,[RemainQty]
					,[WorkCalendarDemandDate]
					,[PlanVersion]
					,[IsUTE]
					,[SubstituteType]
					,[IsFirm]
					,[DemandVersion]
					,[DemandDocNo]
					,[DemandPlanLineNum]
					,[DemandLineNum]
					,[OwnerOrg]
					,[Project]
					,[Task]
					,[BOMComponent]
					,[IsNew]
					,[ReserveQty]
					,[PreDemandLine]
					,[PreOrg]
					,[PreItem]
					,[PreDocNo]
					,[PreDocVersion]
					,[PreDocLineNum]
					,[PreDocPlanLineNum]
					,[IsSecurityStock]
					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,[originalDemandHeader]
				)
				Select 
					t1.[org]
					,t1.[org]		
					,t1.[Item]		
					,t1.[ItemVersion]
					,t1.[fromDegree]
					,t1.[ToDegree]
					,t1.[fromPotency]
					,t1.[ToPotency]
					,t1.[WareHouse]
					,t1.[Lot]
					,t1.[Supplier]
					,t1.[DemandCode]
					,0
					,t1.[OBaseUOM]
					,@TmpBaseQty
					,t1.[StoreMainUOM]
					,@TmpSMQty
					,@TmpDemandDate
					,1
					,@TmpSMQty
					,0
					,3					--MDS
					,t1.[MasterPlanDetail]
					,t1.[PRI]
					,@TmpSMQty
					,@TmpDemandDate
					,t1.[PlanVersion]
					,0
					,0
					,t1.[IsFirm]
					,t1.[SourceDocVersion]
					,isnull(t1.[SourceDocNo],'')
					,t1.[SourceDocPlanLineNum]
					,t1.[SourceDocLineNum]
					,t1.[OwnerOrg]
					,t1.[Project]
					,t1.[Task]
					,null
					,0
					,0
					,t1.[PreDemandLine]
					,t1.[PreLevelItemOrg]
					,t1.[PreLevelItem]
					,t1.[PreDocNo]
					,t1.[PreDocVersion]
					,t1.[PreDocLineNum]
					,t1.[PreDocPlanLineNum]
					,t1.[IsSecurityStock]
					,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,t1.[MasterPlan]
				from [MRP_MPMapping_Temp] t1 
--				inner join MRP_ExpandItemMapping_Temp t2 on t1.[Item] = t2.[Item]
--				and t1.Planversion = @planversion and t1.[PlanVersion] = t2.[PlanVersion] 
--				and t2.[Org] = t1.[Org]
				where t1.[ID] = @TmpID;
			end
			else
			begin
				Insert Into MRP_DemandTemp
				(
					[org]
					,[Factoryorg]
					,[Item]		
					,[ItemVersion]
					,[FromDegree]
					,[ToDegree]
					,[FromPotency]
					,[ToPotency]
					,[WareHouse]
					,[Lot]
					,[Supplier]
					,[DemandCode]
					,[DemandType]
					,[TradeUOM]
					,[TradeQty]
					,[INVUOM]
					,[DemandQty]
					,[DemandDate]
					,[ProcessingDays]
					,[DailyCapacity]
					,[DemandSource]
					,[originalDemandStatus]
					,[originalDemand]
					,[PRI]
					,[RemainQty]
					,[WorkCalendarDemandDate]
					,[PlanVersion]
					,[IsUTE]
					,[SubstituteType]
					,[IsFirm]
					,[DemandVersion]
					,[DemandDocNo]
					,[DemandPlanLineNum]
					,[DemandLineNum]
					,[OwnerOrg]
					,[Project]
					,[Task]
					,[BOMComponent]
					,[IsNew]
					,[ReserveQty]
					,[PreDemandLine]
					,[PreOrg]
					,[PreItem]
					,[PreDocNo]
					,[PreDocVersion]
					,[PreDocLineNum]
					,[PreDocPlanLineNum]
					,[IsSecurityStock]
					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,[originalDemandHeader]
				)
				Select 
					t1.[org]
					,t1.[org]		
					,t1.[Item]		
					,t1.[ItemVersion]
					,t1.[fromDegree]
					,t1.[ToDegree]
					,t1.[fromPotency]
					,t1.[ToPotency]
					,t1.[WareHouse]
					,t1.[Lot]
					,t1.[Supplier]
					,t1.[DemandCode]
					,0
					,t1.[OBaseUOM]
					,@TmpDemandBaseQty - @TmpSUMBaseQty
					,t1.[StoreMainUOM]
					,@TmpDemandSMQty - @TmpSUMSMQty
					,@TmpDemandDate
					,1
					,@TmpDemandSMQty - @TmpSUMSMQty
					,0
					,3					--MDS
					,t1.[MasterPlanDetail]
					,t1.[PRI]
					,@TmpDemandSMQty - @TmpSUMSMQty
					,@TmpDemandDate
					,t1.[PlanVersion]
					,0
					,0
					,t1.[IsFirm]
					,t1.[SourceDocVersion]
					,isnull(t1.[SourceDocNo],'')
					,t1.[SourceDocPlanLineNum]
					,t1.[SourceDocLineNum]
					,t1.[OwnerOrg]
					,t1.[Project]
					,t1.[Task]
					,null
					,0
					,0
					,t1.[PreDemandLine]
					,t1.[PreLevelItemOrg]
					,t1.[PreLevelItem]
					,t1.[PreDocNo]
					,t1.[PreDocVersion]
					,t1.[PreDocLineNum]
					,t1.[PreDocPlanLineNum]
					,t1.[IsSecurityStock]
					,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,t1.[MasterPlan]
				from [MRP_MPMapping_Temp] t1 
--				inner join MRP_ExpandItemMapping_Temp t2 on t1.[Item] = t2.[Item]
--				and t1.PlanVersion=@planVersion and t1.[PlanVersion] = t2.[PlanVersion]
--				and t2.[Org] = t1.[Org]
				where t1.[ID] = @TmpID;
			end
			set @TmpCount = @Tmpcount + 1
		end
		fetch next from MPProcessRep into @TmpStartDate,@TmpEndDate,@TmpOBaseUOM,@TmpSMUOM,@TmpDemandSMQty,@TmpDemandBaseQty,@TmpID,@WorkCalendar;
	end
	close MPProcessRep;
	deallocate MPProcessRep;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=21
    insert into [MRP_ProcessLog] values(@planversion,0,22,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--外部需求来源映像写入需求暂存表
	--先处理非重复物料或为重复性物料，但开始日期=结束日期的记录	
	Insert Into MRP_DemandTemp
	(
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
        ,[IsFromDI]
		,[IsSpecialUseItem]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[SrcWareHouse]
		,[ForecastOrderType]
		,[MultiHierarchyExpandFlag]
	)
	Select 
		t1.[SourceOrg]
		,t1.[Org]
		,t1.[Item]		
		,t1.[ItemVersion]
		,t1.[FromDegree]
		,t1.[ToDegree]
		,t1.[FromPotency]
		,t1.[ToPotency]
		,t1.[WareHouse]
		,t1.[Lot]
		,t1.[Supplier]
		,t1.[DemandCode]
		,(case 
			When t1.[SourceType] = 4 or t1.[SourceType] = 5 then 1
			Else  0
		 end ) --4、5为相依，其余为独立需求
		,t1.[OBaseUOM]
		,t1.[OBaseQty]
		,t1.[StoreMainUOM]
		,t1.[DemandSMQty]
		,t1.[WorkCalendarStartDate]
		,case t3.[ItemType] when @Repetitive then 1 else 0 end
		,case t3.[ItemType] when @Repetitive then t1.[DemandSMQty] else 0 end
		,1
		,case 
			when t1.[SourceType] = 0 then 2		--预测
			when t1.[SourceType] = 1 then 10     --报价单
			when t1.[SourceType] = 2 then 1     --订单
			when t1.[SourceType] = 3 then 7		-- 合同
			when t1.[SourceType] = 4 then 6		--计划订单
			when t1.[SourceType] = 5 then 5		--MPS
			when t1.[SourceType] = 6 then 9		--存货规划
			when t1.[SourceType] = 7 then 20    --PP
			when t1.[SourceType] = 8 then 12    --LRP
			when t1.[SourceType] in(9,-1) then 4 -- mo子件需求
			when t1.[SourceType] =10 then 3 -- mo子件需求
			when t1.[SourceType] =12 then 28  --DRP
			when t1.[SourceType] =25 then 25
			when t1.[SourceType] =27 then 27
			when t1.[SourceType] = 29 then 29
			when t1.[SourceType] = 30 then 30
			when t1.[SourceType] = 23 then 31
			else 0 
		 end
		,t1.[SourceDocLine]
		--,t1.[DemandInterface]					--原始需求ID
		,@MinPri
		,t1.[DemandSMQty]
		,t1.[WorkCalendarStartDate]
		,t1.[PlanVersion]
		,isnull(t2.[IsUTE],0)
		,t1.[SubsitituteType]
		,t1.[IsFirm]
		,t1.[SourceDocVersion]
		,isnull(t1.[SourceDocNo],'')
		,t1.[PlanLineNum]
		,t1.[Linenum]
		,t1.[OwnerOrg]
		,t1.[Project]
		,t1.[Task]
		,t1.[BOMComponent]
		,0
		,0
		,case when t1.[SourceType] in(4,5) then t1.[SourceDocLine] else 0 end --sylviahj 07.07.12 如果来源为mps或计划订单则为对应的mpsdetail或计划订单的ID，否则为空
		,null
		,null
		,''
		,''
		,0
		,0
		,t3.[IsSecurityStock]
        ,1
		,t1.[IsSpecialUseItem]
		,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,t1.[SrcWareHouse]
		,t1.[ForecastOrderType]
		,t1.[MultiHierarchyExpandFlag]
	from MRP_DemandInterfaceMapping_Temp t1 
		inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
												and t1.[Org] = t3.[Org] and t1.[Item] = t3.[Item]
		Left outer join MRP_BOMMapping_Temp t2 on t1.[BOMComponent] = t2.[BOMComponent] 
												and t1.[PlanVersion] = t2.[PlanVersion]	
	Where t1.[PlanVersion] = @PlanVersion 
		and (t3.[ItemType] <> @Repetitive 
			or (t3.[ItemType] = @Repetitive and t1.[WorkCalendarStartDate] = t1.[WorkCalendarEndDate]))
		and t1.[DemandSMQty] > 0

	--处理重复件(开始日期<>结束日期)
	declare DIProcessRep cursor for
	select 
		t1.[WorkCalendarStartDate],t1.[WorkCalendarEndDate],t1.[OBaseUOM],t1.[StoreMainUOM],t1.[DemandSMQty],
		t1.[OBaseQty],t1.[ID],Y.[WorkCalendar]
	from MRP_DemandInterfaceMapping_Temp t1
		inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
											and t1.[Org] = t3.[Org] and t1.[Item] = t3.[Item]
		inner join Base_Organization Y on t3.[Org] = Y.[ID]
	Where t1.[PlanVersion] = @PlanVersion 
		and t3.[ItemType] = @Repetitive 
		and t1.[WorkCalendarStartDate] <> t1.[WorkCalendarEndDate] 
		and t1.[DemandSMQty] > 0;
	open DIProcessRep;
	fetch next from DIProcessRep 
	into @TmpStartDate,@TmpEndDate,@TmpOBaseUOM,@TmpSMUOM,@TmpDemandSMQty,@TmpDemandBaseQty,@TmpID,@WorkCalendar;
	
	while(@@fetch_status = 0)
	begin
		--计算开始日期到结束日期之间的工作日天数
		set @TmpDayCount = dbo.fn_MRP_GetIntervalWorkDays(@TmpStartDate,@TmpEndDate,@WorkCalendar);
		set @TmpCount = 1
		set @TmpSMQty = 0
		set @TmpBaseQty = 0
		set @TmpSUMSMQty = 0
		set @TmpSUMBaseQty = 0

		while (@TmpCount <= @TmpDayCount)
		begin
			set @TmpDemandDate = dbo.fn_MRP_GetWorkDate(@WorkCalendar,@TmpStartDate,@TmpCount,1);
			if (@TmpCount < @TmpDayCount)
			begin
			--如果不是最后一次循环,则数量=@TmpDemandSMQty / @TmpDayCount,否则数量=@TmpDemandSMQty - 前几次循环的数量和
				if @TmpSMQty = 0
					set @TmpSMQty = dbo.fn_MRP_GetRoundValue(@TmpSMUOM,@TmpDemandSMQty / @TmpDayCount);
				if @TmpBaseQty = 0
					set @TmpBaseQty = dbo.fn_MRP_GetRoundValue(@TmpOBaseUOM,@TmpDemandBaseQty / @TmpDayCount);
				set @TmpSUMSMQty = @TmpSUMSMQty + @TmpSMQty
				set @TmpSUMBaseQty = @TmpSUMBaseQty + @TmpBaseQty
				Insert Into MRP_DemandTemp
				(
					[org]
					,[Factoryorg]
					,[Item]		
					,[ItemVersion]
					,[FromDegree]
					,[ToDegree]
					,[FromPotency]
					,[ToPotency]
					,[WareHouse]
					,[Lot]
					,[Supplier]
					,[DemandCode]
					,[DemandType]
					,[TradeUOM]
					,[TradeQty]
					,[INVUOM]
					,[DemandQty]
					,[DemandDate]
					,[ProcessingDays]
					,[DailyCapacity]
					,[DemandSource]
					,[originalDemandStatus]
					,[originalDemand]
					,[PRI]
					,[RemainQty]
					,[WorkCalendarDemandDate]
					,[PlanVersion]
					,[IsUTE]
					,[SubstituteType]
					,[IsFirm]
					,[DemandVersion]
					,[DemandDocNo]
					,[DemandPlanLineNum]
					,[DemandLineNum]
					,[OwnerOrg]
					,[Project]
					,[Task]
					,[BOMComponent]
					,[IsNew]
					,[ReserveQty]
					,[PreDemandLine]
					,[PreOrg]
					,[PreItem]
					,[PreDocNo]
					,[PreDocVersion]
					,[PreDocLineNum]
					,[PreDocPlanLineNum]
					,[IsSecurityStock]
                    ,[IsFromDI]
					,[IsSpecialUseItem]
					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,[ForecastOrderType]
					,[MultiHierarchyExpandFlag]
				)
				Select 
					t1.[SourceOrg]
					,t1.[Org]
					,t1.[Item]		
					,t1.[ItemVersion]
					,t1.[FromDegree]
					,t1.[ToDegree]
					,t1.[FromPotency]
					,t1.[ToPotency]
					,t1.[WareHouse]
					,t1.[Lot]
					,t1.[Supplier]
					,t1.[DemandCode]
					,(case 
						When t1.[SourceType] = 4 or t1.[SourceType] = 5 then 1
						Else  0
					 end ) --4、5为相依，其余为独立需求
					,t1.[OBaseUOM]
					,@TmpBaseQty
					,t1.[StoreMainUOM]
					,@TmpSMQty
					,@TmpDemandDate
					,1
					,@TmpSMQty
					,1
					,case 
						when t1.[SourceType] = 0 then 2		--预测
						when t1.[SourceType] = 1 then 1     --报价单
						when t1.[SourceType] = 2 then 1     --订单
						when t1.[SourceType] = 3 then 7		-- 合同
						when t1.[SourceType] = 4 then 6		--计划订单
						when t1.[SourceType] = 5 then 5		--MPS
						when t1.[SourceType] = 6 then 9		--存货规划
						when t1.[SourceType] = 7 then 20    --PP
						when t1.[SourceType] = 8 then 12    --LRP
						when t1.[SourceType] in(9,-1) then 4 -- mo子件需求
						when t1.[SourceType] =10 then 3 -- mo子件需求
						when t1.[SourceType] =12 then 28  --DRP
						when t1.[SourceType] =25 then 25
						when t1.[SourceType] =27 then 27
						when t1.[SourceType] = 29 then 29
						when t1.[SourceType] = 30 then 30
						else 0 
					 end
					,t1.[SourceDocLine]
--					,t1.[DemandInterface]					--原始需求ID
					,@MinPri
					,@TmpSMQty
					,@TmpDemandDate
					,t1.[PlanVersion]
					,isnull(t2.[IsUTE],0)
					,t1.[SubsitituteType]
					,t1.[IsFirm]
					,t1.[SourceDocVersion]
					,isnull(t1.[SourceDocNo],'')
					,t1.[PlanLineNum]
					,t1.[Linenum]
					,t1.[OwnerOrg]
					,t1.[Project]
					,t1.[Task]
					,t1.[BOMComponent]
					,0
					,0
					,null
					,null
					,null
					,''
					,''
					,0
					,0
					,t3.[IsSecurityStock]
                    ,1
					,t1.[IsSpecialUseItem]
					,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,t1.[ForecastOrderType]
					,t1.[MultiHierarchyExpandFlag]
				from MRP_DemandInterfaceMapping_Temp t1 
					left outer join MRP_BOMMapping_Temp t2 on t1.[BOMComponent] = t2.[BOMComponent] 
														and t1.[PlanVersion] = t2.[PlanVersion]
					inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
														and t1.[Item] = t3.[Item]
														--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
														and t3.[Org] = t1.[Org]
				where t1.[ID] = @TmpID and t1.[PlanVersion] = @PlanVersion;
			end
			else
			begin
				Insert Into MRP_DemandTemp
				(
					[org]
					,[Factoryorg]
					,[Item]		
					,[ItemVersion]
					,[FromDegree]
					,[ToDegree]
					,[FromPotency]
					,[ToPotency]
					,[WareHouse]
					,[Lot]
					,[Supplier]
					,[DemandCode]
					,[DemandType]
					,[TradeUOM]
					,[TradeQty]
					,[INVUOM]
					,[DemandQty]
					,[DemandDate]
					,[ProcessingDays]
					,[DailyCapacity]
					,[DemandSource]
					,[originalDemandStatus]
					,[originalDemand]
					,[PRI]
					,[RemainQty]
					,[WorkCalendarDemandDate]
					,[PlanVersion]
					,[IsUTE]
					,[SubstituteType]
					,[IsFirm]
					,[DemandVersion]
					,[DemandDocNo]
					,[DemandPlanLineNum]
					,[DemandLineNum]
					,[OwnerOrg]
					,[Project]
					,[Task]
					,[BOMComponent]
					,[IsNew]
					,[ReserveQty]
					,[PreDemandLine]
					,[PreOrg]
					,[PreItem]
					,[PreDocNo]
					,[PreDocVersion]
					,[PreDocLineNum]
					,[PreDocPlanLineNum]
					,[IsSecurityStock]
                    ,[IsFromDI]
					,[IsSpecialUseItem]
					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,[ForecastOrderType]
					,[MultiHierarchyExpandFlag]
				)
				Select 
					t1.[SourceOrg]
					,t1.[Org]
					,t1.[Item]		
					,t1.[ItemVersion]
					,t1.[FromDegree]
					,t1.[ToDegree]
					,t1.[FromPotency]
					,t1.[ToPotency]
					,t1.[WareHouse]
					,t1.[Lot]
					,t1.[Supplier]
					,t1.[DemandCode]
					,(case 
						When t1.[SourceType] = 4 or t1.[SourceType] = 5 then 1
						Else  0
					 end ) --4、5为相依，其余为独立需求
					,t1.[OBaseUOM]
					,@TmpDemandBaseQty - @TmpSUMBaseQty
					,t1.[StoreMainUOM]
					,@TmpDemandSMQty - @TmpSUMSMQty
					,@TmpDemandDate
					,@TmpDayCount
					,@TmpSMQty
					,1
					,case 
						when t1.[SourceType] = 0 then 2		--预测
						when t1.[SourceType] = 1 then 1     --报价单
						when t1.[SourceType] = 2 then 1     --订单
						when t1.[SourceType] = 3 then 7		-- 合同
						when t1.[SourceType] = 4 then 6		--计划订单
						when t1.[SourceType] = 5 then 5		--MPS
						when t1.[SourceType] = 6 then 9		--存货规划
						when t1.[SourceType] = 7 then 20    --PP
						when t1.[SourceType] = 8 then 12    --LRP
						when t1.[SourceType] in(9,-1) then 4 -- mo子件需求
						when t1.[SourceType] =10 then 3 -- mo子件需求
						when t1.[SourceType] =12 then 28  --DRP
						when t1.[SourceType] =25 then 25
						when t1.[SourceType] =27 then 27
						when t1.[SourceType] = 29 then 29
						when t1.[SourceType] = 30 then 30
						else 0 
					 end
					,t1.[SourceDocLine]
--					,t1.[DemandInterface]					--原始需求ID
					,@MinPri
					,@TmpDemandSMQty - @TmpSUMSMQty
					,@TmpDemandDate
					,t1.[PlanVersion]
					,isnull(t2.[IsUTE],0)
					,t1.[SubsitituteType]
					,t1.[IsFirm]
					,t1.[SourceDocVersion]
					,isnull(t1.[SourceDocNo],'')
					,t1.[PlanLineNum]
					,t1.[Linenum]
					,t1.[OwnerOrg]
					,t1.[Project]
					,t1.[Task]
					,t1.[BOMComponent]
					,0
					,0
					,null
					,null
					,null
					,''
					,''
					,0
					,0
					,t3.[IsSecurityStock]
                    ,1
					,t1.[IsSpecialUseItem]
					,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,t1.[ForecastOrderType]
					,t1.[MultiHierarchyExpandFlag]
				from MRP_DemandInterfaceMapping_Temp t1 
					left outer join MRP_BOMMapping_Temp t2 on t1.[BOMComponent] = t2.[BOMComponent] 
														and t1.[PlanVersion] = t2.[PlanVersion]
					inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
														and t1.[Item] = t3.[Item]
														--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
														and t3.[Org] = t1.[Org]
				where t1.[ID] = @TmpID and t1.[PlanVersion] = @PlanVersion;
			end
			set @TmpCount = @Tmpcount + 1
		end
		fetch next from DIProcessRep into @TmpStartDate,@TmpEndDate,@TmpOBaseUOM,@TmpSMUOM,@TmpDemandSMQty,@TmpDemandBaseQty,@TmpID,@WorkCalendar;
	end
	close DIProcessRep;
	deallocate DIProcessRep;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=22
    insert into [MRP_ProcessLog] values(@planversion,0,23,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--生产计划映像写入需求暂存表
	--先处理非重复物料或为重复性物料，但开始日期=结束日期的记录	
	Insert Into MRP_DemandTemp
	(
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
		,[ConfigResultID]
	)
	Select 
		isnull(t1.[OperatingOrg],t1.[PlantOrg])
		,t1.[PlantOrg]
		,t1.[Item]		
		,t1.[ItemVersion]
		,t1.[Degree]
		,t1.[Degree]
		,t1.[Potency]
		,t1.[Potency]
		,t1.[Warehouse]
		,isnull(t1.[Lot],'')
		,t1.[Supplier]
		,t1.[DemandCode]
		,0
		,t1.[ProductUOM]
		,t1.[PNetQty]
		,t1.[StoreMainUOM]
		,t1.[SMNetQty]
		,t1.[StarDate]
		,case t1.[ItemType] when @Repetitive then 1 else 0 end
		,case t1.[ItemType] when @Repetitive then t1.[SMNetQty] else 0 end
		,0
		,20  --PP
		,t1.[PPLine]					--原始需求ID
		,t1.[PRI]
		,t1.[SMNetQty]
		,t1.[WCStarDate]
		,t1.[PlanVersion]
		,0
		,0
		,0
		,t1.[Version]
		,t1.[DocNo] + '-' + t1.[PPLineNumber]
		,0
		,0 --由于pp中行号为nvarchar，所以将行号加到docno后面
		,t1.[OwnerOrg]
		,t1.[Project]
		,t1.[Task]
		,null
		,0
		,0
		,null
		,null
		,null
		,''
		,''
		,0
		,0
		,t1.[IsSecurityStock]
		,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,t1.[PP]
		,t1.[ConfigResultID]
	from MRP_PPMapping_Temp t1 
--		inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
--												and t1.[Item] = t3.[Item]
--												--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
--												and t3.[Org] = isnull(t1.[OperatingOrg],t1.[PlantOrg])
	Where t1.[PlanVersion] = @PlanVersion 
		--and (t1.[ItemType] <> @Repetitive 
		--	or (t1.[ItemType] = @Repetitive and t1.[WCStarDate] = t1.[WCEndDate]));

	--处理重复件(开始日期<>结束日期)
	--PP不再区分重复件  yanx于2014.11.26注释
--	declare PPProcessRep cursor for
--	select 
--		t1.[WCStarDate],t1.[WCEndDate],t1.[ProductUOM],t1.[StoreMainUOM],t1.[SMNetQty],
--		t1.[PNetQty],t1.[PPLine],t1.[WorkCalendar]
--	from MRP_PPMapping_Temp t1
----		inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
----												and t1.[Item] = t3.[Item]
----		inner join Base_Organization Y on t3.[Org] = Y.[ID]
--	Where t1.[PlanVersion] = @PlanVersion 
--		and t1.[ItemType] = @Repetitive 
--		and t1.[WCStarDate] <> t1.[WCEndDate];
--	open PPProcessRep;
--	fetch next from PPProcessRep 
--	into @TmpStartDate,@TmpEndDate,@TmpOBaseUOM,@TmpSMUOM,@TmpDemandSMQty,@TmpDemandBaseQty,@TmpID,@WorkCalendar;
	
--	while(@@fetch_status = 0)
--	begin
--		--计算开始日期到结束日期之间的工作日天数
--		set @TmpDayCount = dbo.fn_MRP_GetIntervalWorkDays(@TmpStartDate,@TmpEndDate,@WorkCalendar);
--		set @TmpCount = 1
--		set @TmpSMQty = 0
--		set @TmpBaseQty = 0
--		set @TmpSUMSMQty = 0
--		set @TmpSUMBaseQty = 0

--		while (@TmpCount <= @TmpDayCount)
--		begin
--			set @TmpDemandDate = dbo.fn_MRP_GetWorkDate(@WorkCalendar,@TmpStartDate,@TmpCount,1);
--			if (@TmpCount < @TmpDayCount)
--			begin
--			--如果不是最后一次循环,则数量=@TmpDemandSMQty / @TmpDayCount,否则数量=@TmpDemandSMQty - 前几次循环的数量和
--				if @TmpSMQty = 0
--					set @TmpSMQty = dbo.fn_MRP_GetRoundValue(@TmpSMUOM,@TmpDemandSMQty / @TmpDayCount);
--				if @TmpBaseQty = 0
--					set @TmpBaseQty = dbo.fn_MRP_GetRoundValue(@TmpOBaseUOM,@TmpDemandBaseQty / @TmpDayCount);
--				set @TmpSUMSMQty = @TmpSUMSMQty + @TmpSMQty
--				set @TmpSUMBaseQty = @TmpSUMBaseQty + @TmpBaseQty
--				Insert Into MRP_DemandTemp
--				(
--					[org]
--					,[Factoryorg]
--					,[Item]		
--					,[ItemVersion]
--					,[FromDegree]
--					,[ToDegree]
--					,[FromPotency]
--					,[ToPotency]
--					,[WareHouse]
--					,[Lot]
--					,[Supplier]
--					,[DemandCode]
--					,[DemandType]
--					,[TradeUOM]
--					,[TradeQty]
--					,[INVUOM]
--					,[DemandQty]
--					,[DemandDate]
--					,[ProcessingDays]
--					,[DailyCapacity]
--					,[DemandSource]
--					,[originalDemandStatus]
--					,[originalDemand]
--					,[PRI]
--					,[RemainQty]
--					,[WorkCalendarDemandDate]
--					,[PlanVersion]
--					,[IsUTE]
--					,[SubstituteType]
--					,[IsFirm]
--					,[DemandVersion]
--					,[DemandDocNo]
--					,[DemandPlanLineNum]
--					,[DemandLineNum]
--					,[OwnerOrg]
--					,[Project]
--					,[Task]
--					,[BOMComponent]
--					,[IsNew]
--					,[ReserveQty]
--					,[PreDemandLine]
--					,[PreOrg]
--					,[PreItem]
--					,[PreDocNo]
--					,[PreDocVersion]
--					,[PreDocLineNum]
--					,[PreDocPlanLineNum]
--					,[IsSecurityStock]
--					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
--					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
--					,[originalDemandHeader]
--				)
--				Select 
--					isnull(t1.[OperatingOrg],t1.[PlantOrg])
--					,t1.[PlantOrg]
--					,t1.[Item]		
--					,t1.[ItemVersion]
--					,t1.[Degree]
--					,t1.[Degree]
--					,t1.[Potency]
--					,t1.[Potency]
--					,t1.[Warehouse]
--					,isnull(t1.[Lot],'')
--					,t1.[Supplier]
--					,t1.[DemandCode]
--					,0
--					,t1.[ProductUOM]
--					,@TmpBaseQty
--					,t1.[StoreMainUOM]
--					,@TmpSMQty
--					,@TmpDemandDate
--					,1
--					,@TmpSMQty
--					,0
--					,20  --PP
--					,t1.[PPLine]					--原始需求ID
--					,t1.[PRI]
--					,@TmpSMQty
--					,@TmpDemandDate
--					,t1.[PlanVersion]
--					,0
--					,0
--					,0
--					,t1.[Version]
--					,t1.[DocNo] + '-' + t1.[PPLineNumber]
--					,0
--					,0
--					,t1.[OwnerOrg]
--					,t1.[Project]
--					,t1.[Task]
--					,null
--					,0
--					,0
--					,null
--					,null
--					,null
--					,''
--					,''
--					,0
--					,0
--					,t1.[IsSecurityStock]
--					,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
--					,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
--					,t1.[PP]
--				from MRP_PPMapping_Temp t1 
----				inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
----														and t1.[Item] = t3.[Item]
----														--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
----														and t3.[Org] = isnull(t1.[OperatingOrg],t1.[PlantOrg])
--				where t1.[PPLine] = @TmpID and t1.[PlanVersion] = @PlanVersion;
--			end
--			else
--			begin
--				Insert Into MRP_DemandTemp
--				(
--					[org]
--					,[Factoryorg]
--					,[Item]		
--					,[ItemVersion]
--					,[FromDegree]
--					,[ToDegree]
--					,[FromPotency]
--					,[ToPotency]
--					,[WareHouse]
--					,[Lot]
--					,[Supplier]
--					,[DemandCode]
--					,[DemandType]
--					,[TradeUOM]
--					,[TradeQty]
--					,[INVUOM]
--					,[DemandQty]
--					,[DemandDate]
--					,[ProcessingDays]
--					,[DailyCapacity]
--					,[DemandSource]
--					,[originalDemandStatus]
--					,[originalDemand]
--					,[PRI]
--					,[RemainQty]
--					,[WorkCalendarDemandDate]
--					,[PlanVersion]
--					,[IsUTE]
--					,[SubstituteType]
--					,[IsFirm]
--					,[DemandVersion]
--					,[DemandDocNo]
--					,[DemandPlanLineNum]
--					,[DemandLineNum]
--					,[OwnerOrg]
--					,[Project]
--					,[Task]
--					,[BOMComponent]
--					,[IsNew]
--					,[ReserveQty]
--					,[PreDemandLine]
--					,[PreOrg]
--					,[PreItem]
--					,[PreDocNo]
--					,[PreDocVersion]
--					,[PreDocLineNum]
--					,[PreDocPlanLineNum]
--					,[IsSecurityStock]
--					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
--					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
--					,[originalDemandHeader]
--				)
--				Select 
--					isnull(t1.[OperatingOrg],t1.[PlantOrg])
--					,t1.[PlantOrg]
--					,t1.[Item]		
--					,t1.[ItemVersion]
--					,t1.[Degree]
--					,t1.[Degree]
--					,t1.[Potency]
--					,t1.[Potency]
--					,t1.[Warehouse]
--					,isnull(t1.[Lot],'')
--					,t1.[Supplier]
--					,t1.[DemandCode]
--					,0
--					,t1.[ProductUOM]
--					,@TmpDemandBaseQty - @TmpSUMBaseQty
--					,t1.[StoreMainUOM]
--					,@TmpDemandSMQty - @TmpSUMSMQty
--					,@TmpDemandDate
--					,@TmpDayCount
--					,@TmpSMQty
--					,0
--					,20  --PP
--					,t1.[PPLine]					--原始需求ID
--					,t1.[PRI]
--					,@TmpDemandSMQty - @TmpSUMSMQty
--					,@TmpDemandDate
--					,t1.[PlanVersion]
--					,0
--					,0
--					,0
--					,t1.[Version]
--					,t1.[DocNo] + '-' + t1.[PPLineNumber]
--					,0
--					,0
--					,t1.[OwnerOrg]
--					,t1.[Project]
--					,t1.[Task]
--					,null
--					,0
--					,0
--					,null
--					,null
--					,null
--					,''
--					,''
--					,0
--					,0
--					,t1.[IsSecurityStock]
--					,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
--					,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
--					,t1.[PP]
--				from MRP_PPMapping_Temp t1 
----				inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
----														--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
----														and t3.[Org] = isnull(t1.[OperatingOrg],t1.[PlantOrg])
----														and t1.[Item] = t3.[Item]
--				where t1.[PPLine] = @TmpID and t1.[PlanVersion] = @PlanVersion;
--			end
--			set @TmpCount = @Tmpcount + 1
--		end
--		fetch next from PPProcessRep into @TmpStartDate,@TmpEndDate,@TmpOBaseUOM,@TmpSMUOM,@TmpDemandSMQty,@TmpDemandBaseQty,@TmpID,@WorkCalendar;
--	end
--	close PPProcessRep;
--	deallocate PPProcessRep;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=23
    insert into [MRP_ProcessLog] values(@planversion,0,24,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--子件需求映像写入需求暂存表
	Insert Into MRP_DemandTemp
	(
		[org]
		,[FactoryOrg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[TransOutWh]
		,[QtyType]
		,[QPA]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
		,[IsSpecialUseItem]
		,[IssuedINVQty]--已领料量-库存单位 yanx于2009.11.09添加
		,[IssueINVQty]--已领未发量-库存单位 yanx于2009.11.09添加
		,[OptQty]
		,[ReserveINVQty]
		,[issub]
		,SubstitutedItem
		,[IsOptimizeException] --优化例外标志 yanx于2011.05.17添加
		,[IsMultiHierarchyExpand]
		,[MOBusinessType]
		,[AlternateType]  --生产目的  yanx于2012.10.29添加
		,[IsPhantomPart] --是否为虚拟件工单备料需求 by  qinhjc 20170825
		,[IssueStyle] --工单备料发料方式 by qinhjc 20170825
		,[ConfigResultID] --选配结果ID by qinhjc on 20170209
	)
	Select distinct
		t1.[FactoryOrg]
		,t1.[SupplyOrg]	
		,t1.[ComponentItem]
		,t1.[ComponentItemVersion]
		,t1.[FromDegree]
		,t1.[ToDegree]
		,t1.[FromPotency]
		,t1.[ToPotency]
		,t1.[WareHouse]
		,''
		,t1.[Supplier]
		,t1.[DemandCode]
		,1
		,t1.[IssueUOM]
		,t1.[DemandIUOMQty]
		,t1.[StoreMainUOM]						
		,t1.[DemandSMUOMQty]
		,t1.[DemandDate]
		,0
		,0
		,0
		,case [DemandType] when 0 then 4 when 1 then 8 end
		,t1.[MOPickList]		
		,@MinPri
		,t1.[DemandSMUOMQty]
		,t1.[DemandDate]
		,t1.[PlanVersion]
		,isnull(t2.[IsUTE],0)
		,isnull(t2.[SubstituteType],0)
		,0							-- IsFirm 目前设置为0
		,''
		,t1.[MoDocNo]
		,0
		,0
		,t1.[OwnerOrg]
		,t1.[Project]
		,t1.[Task]
		,t1.[BOMComponent]
		,0
		,t1.[ReserveQty]
		,t1.[MO]
		,t1.[FactoryOrg]
		,t1.[BOMMasterItem]
		,t1.[MODocNo]
		,t1.[MODocVersion]
		,0
		,0
		,null--此处暂不考虑安全库存，因为下面逻辑有更新逻辑--吴峥于2009.10.15注释
		,t1.[TransOutWh]
		,t1.[QtyType]
		,t1.[QPA]
		,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,t1.[MO]
		,t1.[IsSpecialUseItem]
		,t1.IssuedINVQty--MO备料表中的已领料量-库存单位 yanx于2009.11.09添加
		,t1.IssueINVQty--已领未发量-库存单位 yanx于2009.11.09添加
		,t1.OptQty
		,t1.ReserveINVQty
		,t1.IsSub
		,t1.SubstitutedItem
		,t1.[IsOptimizeException] --优化例外标志 yanx于2011.05.17添加
		,t1.[IsMultiHierarchyExpand]
		,t1.[MOBusinessType]
		,t1.[AlternateType]  --生产目的  yanx于2012.10.29添加
		,t1.[IsPhantomPart] --是否为虚拟件工单备料需求 by  qinhjc 20170825
		,t1.[IssueStyle] --工单备料发料方式 by qinhjc 20170825
		,t1.[ConfigResultID]
	from MRP_MOComponentMapping_Temp t1
		Left outer join MRP_BOMMapping_Temp t2 on t1.[BOMComponent] = t2.[BOMComponent] 
											and t1.[PlanVersion] = t2.[PlanVersion]
											--and t1.[BOMMasterItem]=t2.[BOMMasterItem]
	where t1.[PlanVersion] = @PlanVersion 
		and (t1.[DemandSMUOMQty]>0 
			or (@IsSubsOptimization =1 and @SyncRange <>0))
	
	--计划版本添加是否收集计划订单备料字段，UI后续放开  yanx于2013.08.08添加
	if @IsPlanOrderPL = 1
	begin		
		--计划订单备料写入需求暂存表
		Insert Into MRP_DemandTemp
		(
			[org]
			,[FactoryOrg]
			,[originalDemandHeader]
			,[Item]		
			,[ItemVersion]
			,[FromDegree]
			,[ToDegree]
			,[FromPotency]
			,[ToPotency]
			,Lot
			,DemandCode
			,DemandType
			,INVUOM
			,TradeUOM
			,DemandDate
			,[WorkCalendarDemandDate]
			,DemandQty
			,QPA
			,[Project]
			,[Task]
			,WareHouse
			,[OwnerOrg]
			,PlanVersion
			,SeiBan
			,SeiBanCode
			,[BOMComponent]
			,[originalDemandStatus]
			,originalDemand
			,DemandDocNo
			,IsSub
			,LRPState
			,LRPSeq
			,IsFirm
			,PreDemandLine
			--LRP 
			,[IsUTE]
			,[SubstituteType]
			,[IsSpecialUseItem]
			,SubstitutedItem
			,[IsOptimizeException] --优化例外标志 yanx于2011.05.17添加
			,PRI
			,DemandVersion
			,TradeQty
			,AlternateType
			,[ConfigResultID] --选配结果ID by qinhjc on 20170209
		)
		Select
			--t1.SupplyOrg
			T2.Org --202009070190 计划订单备料收集时，收集需求组织为计划订单组织 By jiangjief 2020-09-15
			,t1.[SupplyOrg]
			,t1.PlanOrder --关联的计划订单	
			,t1.ItemMaster
			,isnull(Y.[Version],'')--t1.ItemVersion
			,t1.[FromGrade]
			,t1.ToGrade
			,t1.[FromPotency]
			,t1.[ToPotency]
			,t2.Lot
			--计划订单备料根据专用料标识收集DemandCode  yanx于2013.05.21修改
			,case ISNULL(C.IsInheritDemandCode,0) when 0 then -1 else t2.DemandCode end
			,1
			,t1.INVUOM
			,t1.IssueUOM
			,t1.ActualDemandDate
			,t1.ActualDemandDate
			--计划订单数量调整备料会根据QPA重算，需要取下精度  yanx于2014.12.20修改
			,[dbo].[fn_MRP_GetRoundValue](C.INVUOM,t1.ActualReqQty - t1.ReleasedQty)
			,T1.QPA
			,T1.[Project]
			,case isnull(T1.IsSpecialUseItem,0) when 1 then T2.[Task] else 0 end
			,T1.SupplyWh
			,t1.[SupplyOrg] --T2.[OwnerOrg] 202010120244 计划订单备料的货主组织是备料的供应组织，与外协订单、日计划备料保持一致 By jiangjief 2020-10-13
			,@PlanVersion
			--计划订单备料根据专用料标识收集Seiban  yanx于2013.05.21修改
			,case ISNULL(C.IsInheritSeiban,0) when 0 then 0 else T2.SeiBan end
			,case ISNULL(C.IsInheritSeiban,0) when 0 then '' else T2.SeiBanCode end
			,T1.[BOMComponent]
			,111--PLOPL 类型
			,T1.ID
			,T2.DocNo
			,0
			,1
			,999999
			,t2.IsFirm
			,T1.PlanOrder
			--LRP 以下临时赋值
			,0
			,-1
			,t1.IsSpecialUseItem
			,0
			,0
			,0
			,''
			,t1.ActualReqQty - t1.ReleasedQty
			,isnull(AlternateType,0)
			,case when T2.[ConfigResultID]>1 then ISNULL(F.[ID],-1) else -1 end
		from MRP_LRPPlanOrderPickList t1
			----LRP来源SO计算状态
			--inner join #SrcDocState B on B.SrcDocType = 'UFIDA.U9.MO.MO.MOPickList'
			--							and B.SrcDocID = t1.MOPickList
			--inner join MRP_LRPSourceDoc C on C.PlanVersion = B.PlanVersion
			--							and B.BusinessEntity_EntityType = B.SrcDocType
			--							and B.BusinessEntity_EntityID = B.SrcDocID
			inner join MRP_PlanOrderMapping_Temp T2 on T2.PlanOrder = t1.PlanOrder
			inner join MRP_ExpandItemMapping_Temp C on C.PlanVersion = @PlanVersion and C.Item = t1.ItemMaster
			--LRP 跑毛需求也要收集相依需求作为已处理需求，在2048中单独处理
			--and t2.IsFirm = 1 不再限制Firm(如按MPS料品计划订单备料运行)  yanx于2014.10.11注释
			and (@isLRP = 0 and ISNULL(t1.IsFromLRP,0) = 0)-- or @isLRP = 1 and @isGrossRequire = 0
			--只收集未展开过的虚拟件备料  yanx于2012.10.29添加
			and isnull(t1.IsPhantomPLExpand,0) = 0
			left join CBO_ConfigResult F on F.[ParentConfigResult]=T2.[ConfigResultID]
			left outer join CBO_ItemMasterVersion Y on t1.[ItemVersion] = Y.[ID]
			left outer join CBO_BOMComponent A on t1.BOMComponent=A.ID
		where t2.PlanVersion = @PlanVersion and
			t1.ActualReqQty > t1.ReleasedQty and--需求量要大于0
			--是否考虑委托方带料需求  yanx于2013.07.02修改
			(@IsItemWithConsigner = 1 or @IsItemWithConsigner = 0 and
			not (t1.ConsignProcessItemSrc = 1 or t1.ConsignProcessItemSrc = 3))
			--备料需求过滤不发料子项 By jiangjief 2018-12-03
			and ((@ConsiderIssueStylePhantom=1) or (@ConsiderIssueStylePhantom=0 and (a.IssueStyle is null or a.IssueStyle<>4)));
	end
	
	--PO子件需求映像写入需求暂存表--吴峥于2011.09.20增加
	Insert Into MRP_DemandTemp
	(
		[org],[FactoryOrg],[Item],[ItemVersion],
		[FromDegree],[ToDegree],[FromPotency],[ToPotency],
		[WareHouse],[Lot],[Supplier],[DemandCode],
		[DemandType],
		[TradeUOM],[TradeQty],[INVUOM],
		[DemandQty],
		[DemandDate],[ProcessingDays],[DailyCapacity],[DemandSource],
		[originalDemandStatus],
		[originalDemand],
		[PRI],[RemainQty],[WorkCalendarDemandDate],
		[PlanVersion],
		[IsUTE],[SubstituteType],
		[IsFirm],
		[DemandVersion],
		[DemandDocNo],[DemandPlanLineNum],[DemandLineNum],
		[OwnerOrg],[Project],[Task],
		[BOMComponent],[IsNew],[ReserveQty],
		[PreDemandLine],[PreOrg],[PreItem],[PreDocNo],[PreDocVersion],[PreDocLineNum],[PreDocPlanLineNum],
		[IsSecurityStock],
		[TransOutWh],[QtyType],[QPA],
		[SeiBan],[SeiBanCode],[originalDemandHeader],
		[IsSpecialUseItem],
		[IssuedINVQty],[IssueINVQty],[ReserveINVQty],
		[IsSub],[SubstitutedItem]
	)
	Select
		t1.[FactoryOrg],t1.[SupplyOrg],t1.[ComponentItem],t1.[ComponentItemVersion],
		t1.[FromDegree],t1.[ToDegree],t1.[FromPotency],t1.[ToPotency],
		t1.[WareHouse],'',t1.[Supplier],t1.[DemandCode],
		1,--相依需求
		t1.[IssueUOM],t1.[DemandIUOMQty],t1.[StoreMainUOM],
		t1.[DemandSMUOMQty],
		t1.[DemandDate],0,0,0,
		case t1.[DemandType] when 0 then 31 when 1 then 32 end,
		t1.[POPickList],
		@MinPri,t1.[DemandSMUOMQty],t1.[DemandDate],
		t1.[PlanVersion],
		isnull(t2.[IsUTE],0),isnull(t2.[SubstituteType],0),
		0,-- IsFirm 目前设置为0
		'',
		t1.[PODocNo],t1.[LineNum],t1.[PlanLineNum],
		t1.[OwnerOrg],t1.[Project],t1.[Task],
		t1.[BOMComponent],0,t1.[ReserveQty],
		t1.[PlanLine],t1.[FactoryOrg],t1.[BOMMasterItem],t1.[PODocNo],'',t1.[LineNum],t1.[PlanLineNum],
		null,--此处暂不考虑安全库存，因为下面逻辑有更新逻辑
		t1.[TransOutWh],t1.[QtyType],t1.[QPA],
		t1.[SeiBan],t1.[SeiBanCode],t1.[PO],
		t1.[IsSpecialUseItem],
		t1.IssuedINVQty,t1.IssueINVQty,t1.ReserveINVQty,
		t1.IsSub,t1.SubstitutedItem
	from MRP_POComponentMapping_Temp t1
		Left join MRP_BOMMapping_Temp t2 on t1.[BOMComponent] = t2.[BOMComponent] 
											and t1.[PlanVersion] = t2.[PlanVersion]
											and t1.[BOMMasterItem]=t2.[BOMMasterItem]
	where t1.[PlanVersion] = @PlanVersion 
		and t1.[DemandIUOMQty] > 0 
		
	--处理超额领料业务，需求数量为负的情况--吴峥于2010.11.09修改
	IF (@IsSubsOptimization =1 and @SyncRange <>0)
	Begin
		Update A
		set A.[DemandQty] = 0
		From MRP_DemandTemp A
		Where A.Planversion = @Planversion
			and isnull(A.[DemandQty],0) <0

		Update A
		set A.[TradeQty] = 0
		From MRP_DemandTemp A
		Where A.Planversion = @Planversion
			and isnull(A.[TradeQty],0) <0
	End
 
	--由于备料需求收集的时候已经考虑了物料跨组织转换，所以此处不用再进行转换--吴峥于2009.10.15修改
--	inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
--											 and t1.[ComponentItem] = t3.[Item]
--											 and t1.[FactoryOrg] = t3.[Org]
--										     --2008.11.18张金玉添加
--											 and t1.[DemandIUOMQty]>0
--	inner join MRP_ExpandItemMapping_Temp t4 on t1.[PlanVersion] = t4.[PlanVersion]
--											 and t4.[ItemCode] = t3.[ItemCode]
--											 and t4.[Org] = t1.[SupplyOrg]

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=24
    insert into [MRP_ProcessLog] values(@planversion,0,25,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--负库存作为需求处理--吴峥于2010.09.04增加
	Insert Into MRP_DemandTemp
	(
		[org],[FactoryOrg],[Item],[ItemVersion],
		[FromDegree],[ToDegree],[FromPotency],[ToPotency],
		[WareHouse],[Lot],[Supplier],
		[DemandCode],[DemandType],
		[TradeUOM],[TradeQty],[INVUOM],[DemandQty],
		[DemandDate],[ProcessingDays],[DailyCapacity],[DemandSource],
		[originalDemandStatus],[originalDemand],
		[PRI],[RemainQty],[WorkCalendarDemandDate],
		[PlanVersion],[IsUTE],[SubstituteType],[IsFirm],[DemandVersion],[DemandDocNo],
		[DemandPlanLineNum],[DemandLineNum],
		[OwnerOrg],[Project],[Task],[BOMComponent],
		[IsNew],[ReserveQty],[PreDemandLine],[PreOrg],[PreItem],
		[PreDocNo],[PreDocVersion],[PreDocLineNum],[PreDocPlanLineNum],[IsSecurityStock],
		[SeiBan],--增加Senban维度，吴峥于2009.06.10增加
		[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
	)
	Select 
		[Org],[Org],[Item],[ItemVersion],
		[Degree],[Degree],[Potency],[Potency],
		[WareHouse],[Lot],[Supplier],
		-1,0,--独立需求
		[StoreMainUOM],abs(sum([SMQty])),[StoreMainUOM],abs(sum([SMQty])),
		@Today,0,0,0,
		30,--负库存需求类型
		OhHand,--null 改用在手量头ID，用于实时追溯区分现存量null
		[PRI],abs(sum([SMQty])),@Today,
		@Planversion,0,0,0,'','',
		0,0,
		[OwnerOrg],[Project],[Task],0,
		0,0,null,null,null,
		'','',0,0,0,
		[SeiBan],--增加Senban维度，吴峥于2009.06.10增加
		[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
	from MRP_MinusItemCurQtyMapping_Temp
	Where [PlanVersion] = @PlanVersion
	group by [Org],[Item],[ItemVersion],[Degree],[Potency],[Warehouse],[Supplier],[Lot],
		[StoreMainUOM],[LotEffectiveDate],[OwnerOrg],[Project],[Task],[SeiBan],[SeiBanCode],OhHand,[PRI]
	having sum([SMQty]) < 0;
	
	--添加调拨申请单的需求  --wangxr添加于2014.12.04
	--if(@IsConsiderOnRoad = 1)
	if(@isNewPlanPattern=0 and @isOnRoad=1) or(@isNewPlanPattern<>0 and @IsConsiderOnRoad = 1)
	begin
	Insert Into MRP_DemandTemp
	(
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
		,[SrcWareHouse]
	)
	Select 
		t1.[TransInOrg]
		,t1.[TransOutOrg]		
		,t1.[TransOutItem]			
		,t1.[ItemVersion]
		,t1.[Degree]
		,t1.[Degree]
		,t1.[Potency]
		,t1.[Potency]
		,t1.[TransOutWH]
		,''
		,t1.[Supplier]
		,-1
		,0
		,t1.[TradeUOM]
		,t1.[TUQty]
		,t1.[StoreMainUOM]
		,t1.[TUQty]
		,t1.[RequireDate]
		,0
		,0
		,0
		,33					--MDS
		,t1.[TransApplyLine]
		,0
		,t1.[TUQty]
		,t1.[RequireDate]
		,t1.[PlanVersion]
		,0
		,0
		,1
		,0
		,t1.[DocNo]
		,0
		,0
		,t1.[OwnerOrg]
		,t1.[Project]
		,NULL
		,NULL
		,0
		,0
		,0   
		,NULL
		,0
		,0
		,0
		,0
		,0
		,0
		,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,NULL--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,t1.[TransferApply]
		,0
	from [MRP_TransApplyMapping_Temp] t1
	Where t1.[PlanVersion] = @PlanVersion and t1.[TUQty] > 0 and t1.[TransOutItem] > 0;
	end
	
	--对调拨类型进行存储地点过滤 by qinhjc on 20161223
	if(@isNewPlanPattern=0)--老计划
	BEGIN
		IF(@isWHOnlyControlStock<>1 and @whyn=1)--1.1 未勾选存储地点只控制库存，需求需要进行存储地点进行控制
		BEGIN
			delete A from MRP_DemandTemp A
			WHERE A.[originalDemandStatus]=33  and A.[PlanVersion]=@PlanVersion
			--AND A.[Factoryorg] IN
			--(
			--	select C.Org from MRP_PlanVersion as D 
		 --       inner join MRP_PlanName as B on B.ID = D.[PlanName] and D.ID = @PlanVersion
		 --       inner join MRP_PlanWareHouse as C on C.[PlanStrategy] = B.[PlanStrategy]
			--)
			AND not exists
			(
				select top 1 0 from MRP_PlanVersion as D 
		        inner join MRP_PlanName as B on B.ID = D.[PlanName] and D.ID = @PlanVersion
		        inner join MRP_PlanWareHouse as C on C.[PlanStrategy] = B.[PlanStrategy]
				WHERE A.[WareHouse]=C.WareHouse 
			);
		END
	END
	
	--添加调拨类型的计划订单作为需求  --wangxr添加于2014.12.04
	Insert Into MRP_DemandTemp
	(
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]
		,[ProcessingDays]
		,[DailyCapacity]
		,[DemandSource]
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]
		,[DemandVersion]
		,[DemandDocNo]
		,[DemandPlanLineNum]
		,[DemandLineNum]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[BOMComponent]
		,[IsNew]
		,[ReserveQty]
		,[PreDemandLine]
		,[PreOrg]
		,[PreItem]
		,[PreDocNo]
		,[PreDocVersion]
		,[PreDocLineNum]
		,[PreDocPlanLineNum]
		,[IsSecurityStock]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
		,[SrcWareHouse]
	)
	select 
		A.[SupplyOrg]
		,A.[SupplyOrg]		
		,B.[Item]			
		,A.[ItemVersion]
		,A.[FromDegree]
		,A.[ToDegree]
		,A.[FromPotency]
		,A.[ToPotency]
		,A.[WareHouse]
		,''
		,A.[Supplier]
		,A.[DemandCode]
		,0
		,A.[INVUOM]   
		,A.[MRPQty]-A.[ReleasedQty]
		,A.[INVUOM]
		,A.[MRPQty]-A.[ReleasedQty]
		,A.[AdjustDemandDate]
		,0
		,0
		,0
		,34					--MDS
		,A.ID
		,0
		,A.[MRPQty]-A.[ReleasedQty]
		,A.[AdjustDemandDate]
		,@PlanVersion
		,0
		,0
		,1
		,0
		,A.[DocNo]
		,0
		,0
		,A.[OwnerOrg]
		,NULL
		,NULL
		,NULL
		,0
		,0
		,0   
		,NULL
		,0
		,0
		,0
		,0
		,0
		,0
		,A.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,NULL--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.ID
		,0	
	from MRP_PlanOrder A 
		inner join MRP_ExpandItemMapping_Temp B on A.SupplyOrg = B.Org 
												and A.ItemCode = B.ItemCode 
												and B.PlanVersion=@PlanVersion 
												and A.MRPQty - A.ReleasedQty > 0--InputQty --> MRPQty
												and A.IsFromLRP = @isLRP
		
	where
		--收集供应日期<=计划结束日期的供应信息，吴峥于2009.07.10修改
		(A.AdjustDemandDate between @StartDate and @enddate)
		and A.SupplyType = 3 and A.IsFirmed = 1
			
	--将安全存量也最为一笔需求，需求日期为计划名称表中的开始日期，并且优先级为最大
	--如果是等级成分控制，则没有安全库存；
	--sylviahj 07.07.02 改为根据是否勾选了计划版本上的“安全库存”来决定是否加载安全库存
	--sylviahj 07.10.22 如果物料为ute料，则不考虑其安全库存
	declare @BOMStatus_Approved int
	set @BOMStatus_Approved = 2 --已审核的BOM

--	--收集安全库存
--	IF (@IsSafetyStock = 1)
--	begin
--		exec MRP_GetSafetyStock @PlanVersion
--	end

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=25
    insert into [MRP_ProcessLog] values(@planversion,0,26,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--销售订单映像写入需求暂存表
	Insert Into MRP_DemandTemp
	(	
		[org]
		,[Factoryorg]
		,[Item]		
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[WareHouse]
		,[Lot]
		,[Supplier]
		,[DemandCode]
		,[DemandType]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[DemandQty]
		,[DemandDate]	
		,[originalDemandStatus]
		,[originalDemand]
		,[PRI]
		,[RemainQty]
		,[WorkCalendarDemandDate]
		,[PlanVersion]
		,[IsUTE]
		,[SubstituteType]
		,[IsFirm]		
		,[DemandDocNo]
		,[DemandVersion]
		,[OwnerOrg]
		,[Project]
		,[Task]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalDemandHeader]
	)
	Select 		
		A.[ReqOrg]
		,A.[Factoryorg]
		,A.[Item]		
		,A.[ItemVersion]		
		,A.[FromDegree]
		,A.[ToDegree]		
		,A.[FromPotency]
		,A.[ToPotency]
		,A.[Wh]
		,A.[Lot]
		,A.[Supplier]
		,A.[DemandCode]
		,0							-- DemandType， 0 表示独立需求 ，1表示相依需求
		,A.[TradeUOM]
		,A.[DemandQty]
		,A.[TradeUOM]
		,A.[DemandQty]
		,A.[ReqDate]
		,35
		,A.[LineID]
		,0
		,A.[DemandQty]
		,A.[ReqDate]
		,A.[PlanVersion]
		,0
		,0
		,0
		,isnull(A.[DocNo],'')
		,A.[Version]
		,A.[OwnerOrg]
		,A.[Project]
		,A.[Task]		
		,A.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,A.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.[ID]
	from MRP_ItemRequestMapping_Temp A 
	Where A.PlanVersion = @PlanVersion 
	

/**********************************************************************************************************
------------------------------所有需求写入需求暂存表结束---------------------------------------------------
**********************************************************************************************************/


/**********************************************************************************************************
------------------------------更新需求暂存表的需求组织开始-------------------------------------------------
**********************************************************************************************************/
--收集数据，跨组织，默认为当前当前组织的需求 By jiangjief 2018-07-16
--以下类型，需求组织([org])!=供应组织([Factoryorg])，更新 需求组织=供应组织
--销售订单，销售合同，报价单，生产订单备料，生产线日计划备料，委外备料

--因为收集跨组织需求默认为当前组织的需求,所以项目号要更新为当前组织的项目号 By jiangjief 2018-11-22
--更新项目
update A set A.Project=C.ID 
from MRP_DemandTemp A
inner join cbo_project B on A.Project=B.ID and A.org=B.Org
inner join cbo_project C on C.Code=B.Code and A.[Factoryorg]=C.Org
    where planversion=@planversion and A.[org]!=A.[Factoryorg]
	and [originalDemandStatus] in(1,7,10,4,8,31,32)
	and A.Project is not null

update MRP_DemandTemp set [org]=[Factoryorg]
    where planversion=@planversion and [org]!=[Factoryorg]
	and [originalDemandStatus] in(1,7,10,4,8,31,32)

/**********************************************************************************************************
------------------------------更新需求暂存表的需求组织结束-------------------------------------------------
**********************************************************************************************************/


/**********************************************************************************************************
------------------------------收集安全库存----------------------------------------------------------------
**********************************************************************************************************/
	--收集安全库存
	IF (@IsSafetyStock = 1)
	Begin
		exec MRP_GetSafetyStock @PlanVersion
	End

/**********************************************************************************************************
------------------------------根据计划组织过滤需求暂存表开始------------------------------------------------
**********************************************************************************************************/
--根据计划组织过滤收集的需求 By jiangjief 2018-08-20
--需求只保留 组织=计划组织.工厂组织
--收集本次计划版本的计划组织
select A.* into #MRP_PlanOrg_Temp from MRP_PlanOrg A
inner join MRP_PlanVersion B on B.PlanName=A.PlanName AND B.ID = @PlanVersion 

delete A from MRP_DemandTemp A
inner join #MRP_PlanOrg_Temp B on A.[Factoryorg] = B.[DSOrg]
left join #MRP_PlanOrg_Temp C on A.[Factoryorg] = C.[Factoryorg]
where A.[PlanVersion] = @PlanVersion and C.ID is null

--计划名称.计划方法=MRP，料品.计划方法=MPS，删除该需求 By jiangjief 2018-09-14
--计划名称勾选“按MPS运算”
if(@PlanMethod=@PlanMethodMRP and @IsCalcByMPS=1)
begin
--收集本次计划版本的MPS料品
select * into #MRP_ExpandItemForMPS_Temp from MRP_ExpandItemMapping_Temp
where [PlanVersion] = @PlanVersion and [PlanType]=@PlanType_MPS

delete A from MRP_DemandTemp A
inner join #MRP_ExpandItemForMPS_Temp B on A.item=B.item and A.[PlanVersion]=B.[PlanVersion]
where A.[PlanVersion] = @PlanVersion
end

/**********************************************************************************************************
------------------------------根据计划组织过滤需求暂存表结束-----------------------------------------------
**********************************************************************************************************/

/**********************************************************************************************************
------------------------------所有供应写入供应暂存表开始---------------------------------------------------
**********************************************************************************************************/
    --因为预处理前事件可能客开增加供应，所以这里不做删除 By jiangjief 2021-11-14
	--删除当前版本供应暂存表记录
	--delete from Mrp_SupplyTemp where [PlanVersion] = @PlanVersion;
	
	--渠道库存供应写入供应暂存表
	Insert Into MRP_SupplyTemp
	(
		[Item],[ItemVersion],[FromDegree],[ToDegree],[FromPotency],[ToPotency]
		,[DemandCode],[Lot],[Supplier],[OwnerOrg],[WareHouse],[SupplyType],[originalSupply]
		,[TradeUOM],[TradeQty],[INVUOM],[OriginalQty],[SupplyQty],[SupplyDate]
		,[RemainQty],[PRI],[PlanVersion],[Org],[LotInvalidDate],[Factoryorg],[IsReplaced],[IsUrgent],[IsFirm]
		,[OriginalSupplyDocNo],[OriginalSupplyDocVersion],[OriginalSupplyLineNum],[OriginalSupplyPlanLineNum]
		,[IsByproduct],[Project],[Task],[ActionDate],[StartDate],[ProductionLine],[ReserveQty]
		,[originalSupplyHeader],[originalSupplyLine]
	)
	Select 		
		A.Item ,A.ItemVersion,A.FromDegree,A.ToDegree  		
		,A.FromPotency ,A.ToPotency ,-1,'',A.Vendor,A.OwnerOrg,A.Location
		,26							-- SupplyType， 26 渠道库存供应
		,null 
		,A.TradeUOM ,A.TradeQty,A.[INVUOM],A.[INVQty],A.TradeQty,cast(convert(nvarchar(20),getdate(),112) as datetime)
		,A.TradeQty,0,A.[PlanVersion],A.Org,'9999-12-31',A.Org,0,0,0--[IsFirm]是否锁定		
		,'','','','',0,A.[Project],A.[Task],'1900-01-01'
		,'1900-01-01',null,0,null,null
	from MRP_ChannelQohMapping_Temp A 
--		inner join MRP_ExpandItemMapping_Temp B on A.Item = B.[Item] 
--												and A.[PlanVersion] = B.[PlanVersion]
--												and B.[Org] = A.Org and A.[PlanVersion] = B.[PlanVersion]
	Where A.PlanVersion = @PlanVersion 
		and A.TradeQty > 0

	--WBS映像写入供应暂存表
	Insert Into MRP_SupplyTemp
	(
		[Item],[ItemVersion],[FromDegree],[ToDegree],[FromPotency],[ToPotency]
		,[DemandCode],[Lot],[Supplier],[OwnerOrg],[WareHouse],[SupplyType],[originalSupply]
		,[TradeUOM],[TradeQty],[INVUOM],[OriginalQty],[SupplyQty],[SupplyDate]
		,[RemainQty],[PRI],[PlanVersion],[Org],[LotInvalidDate],[Factoryorg],[IsReplaced],[IsUrgent],[IsFirm]
		,[OriginalSupplyDocNo],[OriginalSupplyDocVersion],[OriginalSupplyLineNum],[OriginalSupplyPlanLineNum]
		,[IsByproduct],[Project],[Task],[ActionDate],[StartDate],[ProductionLine],[ReserveQty]
		,[originalSupplyHeader],[originalSupplyLine]
	)
	Select 		
		A.ItemInfo_ItemID ,A.ItemInfo_ItemVersion,A.ItemInfo_ItemGrade,A.ItemInfo_ItemGrade 		
		,A.ItemInfo_ItemPotency,A.ItemInfo_ItemPotency,-1,'',A.[Supplier],A.ExecuteOrg,null
		,24							-- SupplyType， 24 WBS供应
		,A.TaskOutput_EntityID 
		,A.UOM ,A.TradeQty,A.InvUOM,A.InvQty,A.InvQty,A.ProjOutputDate
		,A.InvQty,0,A.[PlanVersion],A.Org,'9999-12-31',A.ExecuteOrg,0,0,0--[IsFirm]是否锁定		
		,'','','','',0,A.[Project],A.[Task],A.TaskEarlyStartDate,A.TaskEarlyStartDate,null,0,null,null
	from MRP_WBSMapping_Temp A 
--		inner join MRP_ExpandItemMapping_Temp B on A.ItemInfo_ItemID = B.[Item] 
--												and A.[PlanVersion] = B.[PlanVersion]
--												and B.[Org] = A.ExecuteOrg and 	A.[PlanVersion] = B.[PlanVersion]
	Where A.PlanVersion = @PlanVersion 
		and A.TradeQty > 0 and A.DSInfoDocType =24
	
	--采购订单映像写入供应暂存表	
	Insert Into MRP_SupplyTemp
	(
		[Item]	
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[DemandCode]
		,[Lot]	
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,[SupplyType]
		,[originalSupply]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[OriginalQty]
		,[SupplyQty]
		,[SupplyDate]
		,[RemainQty]
		,[PRI]
		,[PlanVersion]
		,[Org]
		,[LotInvalidDate]
		,[Factoryorg]
		,[IsReplaced]
		,[IsUrgent]
		,[IsFirm]
		,[OriginalSupplyDocNo]
		,[OriginalSupplyDocVersion]
		,[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum]
		,[IsByproduct]
		,[Project]
		,[Task]
		,[ActionDate]
		,[StartDate]
		,[ProductionLine]
		,[ReserveQty]
		,[originalSupplyHeader]
		,[originalSupplyLine]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[POBusinessType]
		,[BOMMaster]  --委外PR行记录BOMMaster yanx于2011.10.11添加
		,[IsSubcontract]--委外标识 yanx于2011.10.16添加
	)
	Select 
		A.[Item]		
		,A.[ItemVersion]
		,A.[FromDegree]
		,A.[ToDegree]
		,A.[FromPotency]
		,A.[ToPotency]
		,A.[DemandCode]
		,A.[Lot]
		,A.[Supplier]
		,A.[OwnerOrg]
		,A.[Warehouse]
		,Case 
			When A.[DocType] = 0 then 2				--请购单
			when A.[DocType] = 1 then 3             --采购单
			when A.[DocType] = 3 then 7			    --采购合同
			--新日需求一揽子采购也按普通合同处理(10->7)  yanx于2012.05.16修改
			when A.[DocType] = 2 then  7            --一揽子采购合同
			else 3                                  --来源于其它类型的，认为是采购
		 end
		,A.[PlanLine]
		,A.[PurchaseBaseUOM]
		,A.[BaseQty]
		,A.[StoreMainUOM]
        ,A.[OrgiQty]
		--,[dbo].[fn_MRP_GetRoundValue](A.[StoreMainUOM],dbo.fn_MRP_GetConvertRatio(A.[BaseQty],A.[PurchaseBaseUOM],A.[StoreMainUOM],A.[Item],B.[ConvertRule]))
		,A.[SupplySMQty]
		,A.[DeliverDate]
		--如下代码可能是开发遗漏，暂时不考虑--吴峥于2010.02.02修改
--		,case when A.[DeliverDate]<@StartDate then @StartDate else A.[DeliverDate] end
		,A.[SupplySMQty]
		,A.[PRI]
		,A.[PlanVersion]
		,A.[PurchaseOrg]
		,'9999-12-31'
		,A.[Factoryorg]
		,0
		,0
		,A.[IsFirm]
		,isnull(A.[DocNo],'')
		,A.[DocVersion]
		,A.[LineNum]
		,A.[PlanLineNum]
		,0
		,A.[Project]
		,A.[Task]
		,'1900-01-01'
		,'1900-01-01'
		,null
		,A.[ReserveQty]
		,A.[POHeader]
		,null
		,A.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,A.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.[BusinessType]
		,A.[BOMMaster]  --委外PR行记录BOMMaster yanx于2011.10.11添加
		,A.[IsSubcontract]--委外标识 yanx于2011.10.16添加
	from MRP_POMapping_Temp A 
--		inner join MRP_ExpandItemMapping_Temp B on A.[Item] = B.[Item] 
--											and A.[FactoryOrg] = B.[Org] 
--											and A.[PlanVersion] = B.[PlanVersion]
	Where A.[PlanVersion] = @PlanVersion and A.[SupplySMQty] > 0;


    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=26
    insert into [MRP_ProcessLog] values(@planversion,0,27,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--生产订单映像写入供应暂存表
	Insert Into MRP_SupplyTemp
	(
		[Item]	
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[DemandCode]
		,[Lot]	
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,[SupplyType]
		,[originalSupply]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[OriginalQty]
		,[SupplyQty]
		,[SupplyDate]
		,[RemainQty]
		,[PRI]
		,[PlanVersion]
		,[Org]
		,[LotInvalidDate]
		,[Factoryorg]
		,[IsReplaced]
		,[IsUrgent]
		,[IsFirm]
		,[OriginalSupplyDocNo]
		,[OriginalSupplyDocVersion]
		,[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum]
		,[IsByproduct]
		,[Project]
		,[Task]
		,[ActionDate]
		,[StartDate]
		,[ProductionLine]
		,[ReserveQty]
		,[ScrapPUOMQty]
		,[ScrapSMUOMQty]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalSupplyHeader]
		,[DocState]
		,[IsPickList]
		,[IsMultiHierarchyExpand]
		,[ParentDocNo]
		,[PlanOrderSupplyType]
		,[MOBusinessType]
		--BOM生产目的，默认主制造  yanx于2012.07.05添加
		,AlternateType
	)
	Select 
		A.[Item]
		,A.[ItemVersion]
		,A.[Degree]
		,A.[Degree]
		,A.[Potency]
		,A.[Potency]
		,A.[DemandCode]
		,A.[Lot]
		,A.[Manufacture]
		,A.[OwnerOrg]
		,A.[Wh]
		,1
		,A.[MO]
		,A.[ProductUOM]
		,A.[MrpQty]
		,A.[StoreMainUOM]
        ,A.[OrgiQty]
		--,[dbo].[fn_MRP_GetRoundValue](A.[StoreMainUOM], dbo.fn_MRP_GetConvertRatio(A.[MrpQty],A.[ProductUOM],A.[StoreMainUOM],A.[Item],B.[ConvertRule])) 
		,A.[SupplySMUOMQty]
		,A.[CompleteDate]
		,A.[SupplySMUOMQty]
		,A.[PRI]
		,A.[PlanVersion]
		,A.[Org]
		,'9999-12-31'
		,A.[Org]
		,0
		,0
		,A.[IsFirm]
		,isnull(A.[MODocNo],'')
		,A.[MODocVersion]
		,0
		,0
		,case A.[OutPutType] when 0 then 0 else 1 end
		,A.[Project]
		,A.[Task]
		,'1900-01-01'
		,A.[StartDate]
		,null
		,A.[ReserveQty]
		,A.[ScrapPUOMQty]
		,A.[ScrapSMUOMQty]
		,A.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,A.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.[MO]
		,A.[DocState]
		,A.[IsPickList]
		,A.[IsMultiHierarchyExpand]
		,A.[ParentDocNo]
		,A.[PlanOrderSupplyType]
		,A.[MOBusinessType]
		--BOM生产目的，默认主制造  yanx于2012.07.05添加
		,isnull(AlternateType,0)
	from MRP_MOMapping_Temp A 
--		inner join MRP_ExpandItemMapping_Temp B on A.[Item] = B.[Item] 
--											and A.[Org] = B.[Org] 
--											and A.[PlanVersion] = B.[PlanVersion]
	Where A.[PlanVersion] = @PlanVersion and A.[IsMaterialPlan] = 0;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=27
    insert into [MRP_ProcessLog] values(@planversion,0,28,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--重复计划映像写入供应暂存表
	Insert Into MRP_SupplyTemp
	(
		[Item]	
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[DemandCode]
		,[Lot]	
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,[SupplyType]
		,[originalSupply]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[OriginalQty]
		,[SupplyQty]
		,[SupplyDate]
		,[RemainQty]
		,[PRI]
		,[PlanVersion]
		,[Org]
		,[LotInvalidDate]
		,[Factoryorg]
		,[IsReplaced]
		,[IsUrgent]
		,[IsFirm]
		,[OriginalSupplyDocNo]
		,[OriginalSupplyDocVersion]
		,[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum]
		,[IsByproduct]
		,[Project]
		,[Task]
		,[ActionDate]
		,[StartDate]
		,[ProductionLine]
		,[ReserveQty]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalSupplyHeader]
		,[DocState]
		,[IsPickList]
	)
	Select 
		A.[Item]
		,A.[ItemVersion]
		,A.[Degree]
		,A.[Degree]
		,A.[Potency]
		,A.[Potency]
		,A.[DemandCode]
		,A.[Lot]
		,A.[Manufacture]
		,A.[OwnerOrg]
		,A.[Wh]
		,8
		,A.[MO]
		,A.[ProductUOM]
		,A.[ProductQty]
		,A.[StoreMainUOM]
		,A.[OriginalQty]
--		,[dbo].[fn_MRP_GetRoundValue](A.[StoreMainUOM], dbo.fn_MRP_GetConvertRatio(A.[ProductQty],A.[ProductUOM],A.[StoreMainUOM],A.[Item],B.[ConvertRule])) 
		,A.[SupplySMUOMQty]
		,A.[CompleteDate]
		,A.[SupplySMUOMQty]
		,A.[PRI]
		,A.[PlanVersion]
		,A.[Org]
		,'9999-12-31'
		,A.[Org]
		,0
		,0
		,A.[IsFirm]
		,isnull(A.[MODocNo],'')
		,A.[MODocVersion]
		,0
		,0
		,0
		,A.[Project]
		,A.[Task]
		,'1900-01-01'
		,A.[StartDate]
		,A.[ProductionLine]
		,A.[ReserveQty]
		,A.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,A.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.[MO]
		,A.[DocState]
		,A.[IsPickList]
	from MRP_RepMapping_Temp A 
--		inner join MRP_ExpandItemMapping_Temp B on A.[Item] = B.[Item] 
--											and A.[Org] = B.[Org] 
--											and A.[PlanVersion] = B.[PlanVersion]
	Where A.[PlanVersion] = @PlanVersion;
	
	--计划订单映像写入供应暂存表 根据现在规则，不需要乘以等级比例 	
	--对于Item为重复件的计划订单，需要按照工作日历分解到每天，产生多笔供应
	--sylviahj 07.07.27 计划订单不作为供应了
	--lujj 09.06.16 锁定的计划订单作为供应

	--先处理Item 形态不是 重复件 的数据，或虽为重复件，但起始／结束日期为同一天的数据
	--现在锁定的计划订单支持重排，可以给供应时间之前的需求做供应，不需要对重复件起始时间不同的计划订单作拆分处理  by qinhjc on 20161114
	Insert Into MRP_SupplyTemp
	(
		[Item]	
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[DemandCode]
		,[Lot]	
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,[SupplyType]
		,[originalSupply]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[OriginalQty]
		,[SupplyQty]
		,[SupplyDate]
		,[RemainQty]
		,[PRI]
		,[PlanVersion]
		,[Org]
		,[LotInvalidDate]
		,[Factoryorg]
		,[IsReplaced]
		,[IsUrgent]
		,[IsFirm]
		,[OriginalSupplyDocNo]
		,[OriginalSupplyDocVersion]
		,[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum]
		,[IsByproduct]
		,[Project]
		,[Task]
		,[ActionDate]
		,[StartDate]
		,[ProductionLine]
		,[ReserveQty]
		,[SeiBan]
		,[SeiBanCode]
		,[originalSupplyHeader]
		,[PlanOrderSupplyType]
		,[ForecastOrderType]
		,[MultiHierarchyExpandFlag]
		,[ByHand]
		,[BOMMaster]
		--BOM生产目的  yanx于2012.07.05添加
		,AlternateType
		--LRP顶层单号  yanx于2013.11.11添加
		,TopLevelDocNo
		,[IsPickList]
	)
	Select 
		t1.[Item]		
		,t1.[ItemVersion]
		,t1.[FromDegree]
		,t1.[ToDegree]
		,t1.[FromPotency]
		,t1.[ToPotency]
		,t1.[DemandCode]
		,t1.[Lot]
		,t1.[Supplier]
		,t1.[OwnerOrg]
		,t1.[WareHouse]
		,5							
		,t1.[Planorder]				
		,t1.[StoreMainUOM]					
		,t1.[MrpQty]
		,t1.[StoreMainUOM]						
		,t1.[MrpQty]
		,t1.[MrpQty]			
		,t1.[SupplyDate]
		,t1.[MrpQty]		
		,@MinPri	
		,t1.[PlanVersion]
		,t1.[Org]
		,'9999-12-31'
		,t1.[Org]
		,0
		,t1.[IsUrgency]
		,t1.[IsFirm]
		,isnull(t1.[DocNo],'')
		,null
		,null
		,null
		,0
		,t1.[Project]
		,t1.[Task]
		,t1.[ActionDate] 
		,t1.[StartDate]
		,null
		,0
		,t1.[SeiBan]
		,t1.[SeiBanCode]
		,t1.[Planorder]	
		,t1.[PlanOrderSupplyType]
		,t1.[ForecastOrderType]
		,t1.[MultiHierarchyExpandFlag]
		,t1.[ByHand]
		,t1.[BOMMaster]
		--BOM生产目的，默认主制造  yanx于2012.07.05添加
		,isnull(t1.AlternateType,0)
		,t1.TopLevelDocNo
		,t1.[IsPickList]
	from [MRP_PlanorderMapping_Temp] t1
--		inner join [MRP_ExpandItemMapping_temp] t2 on t1.[PlanVersion] = t2.[PlanVersion] 
--												and t1.[org] = t2.[org] 
--												and t1.[Item] = t2.[Item]
	Where t1.[PlanVersion] = @PlanVersion ;
		--and ((t1.[ItemType] <> @Repetitive) 
		--	or (t1.[ItemType] = @Repetitive and t1.[StartDate] = t1.[SupplyDate]));

	--处理Item为重复件且起始／结束日期不为同一天的数据
--	declare PlanOrderProcessRep cursor for
--	select 
--		t1.[StartDate],t1.[SupplyDate],t1.[StoreMainUOM],t1.[MrpQty] - t1.[ReleasedQty],t1.[ID]
--	from MRP_PlanorderMapping_Temp t1
----	inner join MRP_ExpandItemMapping_Temp t3 on t1.[PlanVersion] = t3.[PlanVersion] 
----											and t1.[Org] = t3.[Org] 
----											and t1.[Item] = t3.[Item]
--	Where t1.[PlanVersion] = @PlanVersion 
--		and t1.[ItemType] = @Repetitive and t1.[StartDate] <> t1.[SupplyDate];
--	open PlanOrderProcessRep;
--	fetch next from PlanOrderProcessRep 
--	into @TmpStartDate,@TmpEndDate,@TmpSMUOM,@TmpSupplySMQty,@TmpID;
	
--	while(@@fetch_status = 0)
--	begin
--		--计算开始日期到结束日期之间的工作日天数
--		set @TmpDayCount = dbo.fn_MRP_GetIntervalWorkDays(@TmpStartDate,@TmpEndDate,@WorkCalendar);
--		set @TmpCount = 1
--		set @TmpSMQty = 0
--		set @TmpSUMSMQty = 0

--		while (@TmpCount <= @TmpDayCount)
--		begin
--			set @TmpSupplyDate = dbo.fn_MRP_GetWorkDate(@WorkCalendar,@TmpStartDate,@TmpCount,1);
--			if (@TmpCount < @TmpDayCount)
--			begin
--			--如果不是最后一次循环,则数量=@TmpSupplySMQty / @TmpDayCount,否则数量=@TmpSupplySMQty - 前几次循环的数量和
--				if @TmpSMQty = 0
--					set @TmpSMQty = dbo.fn_MRP_GetRoundValue(@TmpSMUOM,@TmpSupplySMQty / @TmpDayCount);
--				set @TmpSUMSMQty = @TmpSUMSMQty + @TmpSMQty
--				Insert Into MRP_SupplyTemp
--				(
--					[Item]	
--					,[ItemVersion]
--					,[FromDegree]
--					,[ToDegree]
--					,[FromPotency]
--					,[ToPotency]
--					,[DemandCode]
--					,[Lot]	
--					,[Supplier]
--					,[OwnerOrg]
--					,[WareHouse]
--					,[SupplyType]
--					,[originalSupply]
--					,[TradeUOM]
--					,[TradeQty]
--					,[INVUOM]
--					,[OriginalQty]
--					,[SupplyQty]
--					,[SupplyDate]
--					,[RemainQty]
--					,[PRI]
--					,[PlanVersion]
--					,[Org]
--					,[LotInvalidDate]
--					,[Factoryorg]
--					,[IsReplaced]
--					,[IsUrgent]
--					,[IsFirm]
--					,[OriginalSupplyDocNo]
--					,[OriginalSupplyDocVersion]
--					,[OriginalSupplyLineNum]
--					,[OriginalSupplyPlanLineNum]
--					,[IsByproduct]
--					,[Project]
--					,[Task]
--					,[ActionDate]
--					,[StartDate]
--					,[ProductionLine]
--					,[ReserveQty]
--					,[SeiBan]
--		            ,[SeiBanCode]
--					,[originalSupplyHeader]
--					,[PlanOrderSupplyType]
--					,[ForecastOrderType]
--					,[MultiHierarchyExpandFlag]
--					,[ByHand]
--				)
--				Select 
--					[Item]		
--					,[ItemVersion]
--					,[FromDegree]
--					,[ToDegree]
--					,[FromPotency]
--					,[ToPotency]
--					,[DemandCode]
--					,[Lot]
--					,[Supplier]
--					,[OwnerOrg]
--					,[WareHouse]
--					,5							
--					,[Planorder]				
--					,[StoreMainUOM]					
--					,@TmpSMQty
--					,[StoreMainUOM]						
--					,@TmpSMQty
--					,@TmpSMQty		
--					,@TmpSupplyDate
--					,@TmpSMQty	
--					,@MinPri	
--					,[PlanVersion]
--					,[Org]
--					,'9999-12-31'
--					,[Org]
--					,0
--					,[IsUrgency]
--					,[IsFirm]
--					,isnull([DocNo],'')
--					,null
--					,null
--					,null
--					,0
--					,[Project]
--					,[Task]
--					,'1900-01-01'
--					,'1900-01-01'
--					,null
--					,0
--					,[SeiBan]
--		            ,[SeiBanCode]
--					,[Planorder]
--					,[PlanOrderSupplyType]
--					,[ForecastOrderType]
--					,[MultiHierarchyExpandFlag]
--					,[ByHand]
--				from MRP_PlanorderMapping_Temp
--				where [ID] = @TmpID;
--			end
--			else
--			begin
--				Insert Into MRP_SupplyTemp
--				(
--					[Item]	
--					,[ItemVersion]
--					,[FromDegree]
--					,[ToDegree]
--					,[FromPotency]
--					,[ToPotency]
--					,[DemandCode]
--					,[Lot]	
--					,[Supplier]
--					,[OwnerOrg]
--					,[WareHouse]
--					,[SupplyType]
--					,[originalSupply]
--					,[TradeUOM]
--					,[TradeQty]
--					,[INVUOM]
--					,[OriginalQty]
--					,[SupplyQty]
--					,[SupplyDate]
--					,[RemainQty]
--					,[PRI]
--					,[PlanVersion]
--					,[Org]
--					,[LotInvalidDate]
--					,[Factoryorg]
--					,[IsReplaced]
--					,[IsUrgent]
--					,[IsFirm]
--					,[OriginalSupplyDocNo]
--					,[OriginalSupplyDocVersion]
--					,[OriginalSupplyLineNum]
--					,[OriginalSupplyPlanLineNum]
--					,[IsByproduct]
--					,[Project]
--					,[Task]
--					,[ActionDate]
--					,[StartDate]
--					,[ProductionLine]
--					,[ReserveQty]
--					,[SeiBan]
--		            ,[SeiBanCode]
--					,[originalSupplyHeader]
--					,[PlanOrderSupplyType]
--					,[ForecastOrderType]
--					,[MultiHierarchyExpandFlag]
--					,[ByHand]
--				)
--				Select 
--					[Item]		
--					,[ItemVersion]
--					,[FromDegree]
--					,[ToDegree]
--					,[FromPotency]
--					,[ToPotency]
--					,[DemandCode]
--					,[Lot]
--					,[Supplier]
--					,[OwnerOrg]
--					,[WareHouse]
--					,5							
--					,[Planorder]				
--					,[StoreMainUOM]					
--					,@TmpSupplySMQty - @TmpSUMSMQty
--					,[StoreMainUOM]						
--					,@TmpSupplySMQty - @TmpSUMSMQty
--					,@TmpSupplySMQty - @TmpSUMSMQty		
--					,@TmpSupplyDate
--					,@TmpSupplySMQty - @TmpSUMSMQty	
--					,@MinPri	
--					,[PlanVersion]
--					,[Org]
--					,'9999-12-31'
--					,[Org]
--					,0
--					,[IsUrgency]
--					,[IsFirm]
--					,isnull([DocNo],'')
--					,null
--					,null
--					,null
--					,0
--					,[Project]
--					,[Task]
--					,'1900-01-01'
--					,'1900-01-01'
--					,null
--					,0
--					,[SeiBan]
--		            ,[SeiBanCode]
--					,[Planorder]
--					,[PlanOrderSupplyType]
--					,[ForecastOrderType]
--					,[MultiHierarchyExpandFlag]
--					,[ByHand]
--				from MRP_PlanorderMapping_Temp
--				where [ID] = @TmpID;
--			end
--			set @TmpCount = @Tmpcount + 1
--		end
--		fetch next from PlanOrderProcessRep into @TmpStartDate,@TmpEndDate,@TmpSMUOM,@TmpSupplySMQty,@TmpID;
--	end
--	close PlanOrderProcessRep;
--	deallocate PlanOrderProcessRep;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=28
    insert into [MRP_ProcessLog] values(@planversion,0,29,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--将锁定的MPS计划写入供应暂存表(暂不考虑BOM等级比例)
	--由于MPS子件需求展开改在净算中进行，所以去掉此条件--吴峥于2010.03.17修改
--	if (@PlanMethod in (@PlanMethodMPS,@PlanMethodMPSDRP)) or (@netchangeyn =1)
--	Begin
	--先处理非重复物料或虽为重复件，但起始／结束日期为同一天的数据
	Insert Into MRP_SupplyTemp
	(
		[Item]	
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[DemandCode]
		,[Lot]	
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,[SupplyType]
		,[originalSupply]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[OriginalQty]
		,[SupplyQty]
		,[SupplyDate]
		,[RemainQty]
		,[PRI]
		,[PlanVersion]
		,[Org]
		,[LotInvalidDate]
		,[Factoryorg]
		,[IsReplaced]
		,[IsUrgent]
		,[IsFirm]
		,[OriginalSupplyDocNo]
		,[OriginalSupplyDocVersion]
		,[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum]
		,[IsByproduct]
		,[Project]
		,[Task]
		,[ActionDate]
		,[StartDate]
		,[ProductionLine]
		,[ReserveQty]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalSupplyHeader]
		,[PlanOrderSupplyType]
		,[ForecastOrderType]
		,[MultiHierarchyExpandFlag]
		,[ByHand]
		,[BOMMaster]
		,[AlternateType]  --生产目的  yanx于2012.10.29添加
	)
	Select 
		t1.[Item]			
		,t1.[ItemVersion]
		,t1.[FromDegree]
		,t1.[ToDegree]
		,t1.[FromPotency]
		,t1.[ToPotency]
		,t1.[DemandCode]
		,t1.[Lot]
		,t1.[Supplier]
		,t1.[OwnerOrg]
		,t1.[WareHouse]
		,4							--MPS计划
		,t1.[MasterPlandetail]
		,t1.[OBaseUOM]
		,t1.[BaseQty]
		,t1.[StoreMainUOM]
		,t1.[DemandSMQty]
		,t1.[DemandSMQty] 
		,t1.[WorkCalendarDSDate]
		,t1.[DemandSMQty]
		,t1.[PRI]
		,t1.[PlanVersion]
		,t1.[Org]
		,'9999-12-31'
		,t1.[Org]
		,0
		,0
		,t1.[IsFirm]
		,''
		,''
		,0
		,0
		,0
		,t1.[Project]
		,t1.[Task]
		,'1900-01-01'
		,'1900-01-01'
		,null
		,0
		,t1.[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,t1.[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,t1.[MasterPlan]
		,[PlanOrderSupplyType]
		,t1.[ForecastOrderType]
		,t1.[MultiHierarchyExpandFlag]
		,t1.[ByHand]
		,t1.BOMMaster
		,t1.[AlternateType]  --生产目的  yanx于2012.10.29添加
	from MRP_MPMapping_Temp t1 
--			inner join MRP_ExpandItemMapping_Temp t2 on t1.[PlanVersion] = t2.[PlanVersion] 
--													and t1.[Org] = t2.[Org]
--													and t1.[Item] = t2.[Item]
	Where t1.[PlanType] = @MPS 
		and t1.PlanVersion = @PlanVersion 
		and (t1.[ItemType] <> @Repetitive
				or (t1.[ItemType] = @Repetitive and t1.[WorkCalendarDSDate] = t1.[WorkCalendarEndDSDate]));

	--处理重复物料(开始日期<>结束日期)
	declare MPSProcessRep cursor for
	select 
		t1.[WorkCalendarDSDate],t1.[WorkCalendarEndDSDate],t1.[OBaseUOM],t1.[StoreMainUOM],t1.[DemandSMQty] - t1.[ExecQty],
		t1.[BaseQty],t1.[ID]
	from MRP_MPMapping_Temp t1 
--			inner join MRP_ExpandItemMapping_Temp t2 on t1.[PlanVersion] = t2.[PlanVersion] 
--													and t1.[Org] = t2.[Org]
--													and t1.[Item] = t2.[Item]
	Where t1.[PlanType] = @MPS 
		and t1.PlanVersion = @PlanVersion 
		and t1.[ItemType] = @Repetitive 
		and t1.[WorkCalendarDSDate] <> t1.[WorkCalendarEndDSDate];
	open MPSProcessRep;
	fetch next from MPSProcessRep 
	into @TmpStartDate,@TmpEndDate,@TmpOBaseUOM,@TmpSMUOM,@TmpSupplySMQty,@TmpSupplyBaseQty,@TmpID;
	
	while(@@fetch_status = 0)
	begin
		--计算开始日期到结束日期之间的工作日天数
		set @TmpDayCount = dbo.fn_MRP_GetIntervalWorkDays(@TmpStartDate,@TmpEndDate,@WorkCalendar);
		set @TmpCount = 1
		set @TmpSMQty = 0
		set @TmpBaseQty = 0
		set @TmpSUMSMQty = 0
		set @TmpSUMBaseQty = 0

		while (@TmpCount <= @TmpDayCount)
		begin
			set @TmpSupplyDate = dbo.fn_MRP_GetWorkDate(@WorkCalendar,@TmpStartDate,@TmpCount,1);
			if (@TmpCount < @TmpDayCount)
			begin
			--如果不是最后一次循环,则数量=@TmpDemandSMQty / @TmpDayCount,否则数量=@TmpDemandSMQty - 前几次循环的数量和
				if @TmpSMQty = 0
					set @TmpSMQty = dbo.fn_MRP_GetRoundValue(@TmpSMUOM,@TmpSupplySMQty / @TmpDayCount);
				if @TmpBaseQty = 0
					set @TmpBaseQty = dbo.fn_MRP_GetRoundValue(@TmpOBaseUOM,@TmpSupplyBaseQty / @TmpDayCount);
				set @TmpSUMSMQty = @TmpSUMSMQty + @TmpSMQty
				set @TmpSUMBaseQty = @TmpSUMBaseQty + @TmpBaseQty
				Insert Into MRP_SupplyTemp
				(
					[Item]	
					,[ItemVersion]
					,[FromDegree]
					,[ToDegree]
					,[FromPotency]
					,[ToPotency]
					,[DemandCode]
					,[Lot]	
					,[Supplier]
					,[OwnerOrg]
					,[WareHouse]
					,[SupplyType]
					,[originalSupply]
					,[TradeUOM]
					,[TradeQty]
					,[INVUOM]
					,[OriginalQty]
					,[SupplyQty]
					,[SupplyDate]
					,[RemainQty]
					,[PRI]
					,[PlanVersion]
					,[Org]
					,[LotInvalidDate]
					,[Factoryorg]
					,[IsReplaced]
					,[IsUrgent]
					,[IsFirm]
					,[OriginalSupplyDocNo]
					,[OriginalSupplyDocVersion]
					,[OriginalSupplyLineNum]
					,[OriginalSupplyPlanLineNum]
					,[IsByproduct]
					,[Project]
					,[Task]
					,[ActionDate]
					,[StartDate]
					,[ProductionLine]
					,[ReserveQty]
					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,[originalSupplyHeader]
					,[PlanOrderSupplyType]
					,[ForecastOrderType]
					,[MultiHierarchyExpandFlag]
					,[ByHand]
					,[BOMMaster]
					,[AlternateType]  --生产目的  yanx于2012.10.29添加
				)
				Select 
					[Item]			
					,[ItemVersion]
					,[FromDegree]
					,[ToDegree]
					,[FromPotency]
					,[ToPotency]
					,[DemandCode]
					,[Lot]
					,[Supplier]
					,[OwnerOrg]
					,[WareHouse]
					,4							--MPS计划
					,[MasterPlandetail]
					,[OBaseUOM]
					,@TmpBaseQty
					,[StoreMainUOM]
					,@TmpSMQty
					,@TmpSMQty 
					,@TmpSupplyDate
					,@TmpSMQty
					,[PRI]
					,[PlanVersion]
					,[Org]
					,'9999-12-31'
					,[Org]
					,0
					,0
					,[IsFirm]
					,''
					,''
					,0
					,0
					,0
					,[Project]
					,[Task]
					,'1900-01-01'
					,'1900-01-01'
					,null
					,0
					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,[MasterPlan]
					,[PlanOrderSupplyType]
					,[ForecastOrderType]
					,[MultiHierarchyExpandFlag]
					,[ByHand]
					,[BOMMaster]
					,[AlternateType]  --生产目的  yanx于2012.10.29添加
				from MRP_MPMapping_Temp 
				where [ID] = @TmpID;
			end
			else
			begin
				Insert Into MRP_SupplyTemp
				(
					[Item]	
					,[ItemVersion]
					,[FromDegree]
					,[ToDegree]
					,[FromPotency]
					,[ToPotency]
					,[DemandCode]
					,[Lot]	
					,[Supplier]
					,[OwnerOrg]
					,[WareHouse]
					,[SupplyType]
					,[originalSupply]
					,[TradeUOM]
					,[TradeQty]
					,[INVUOM]
					,[OriginalQty]
					,[SupplyQty]
					,[SupplyDate]
					,[RemainQty]
					,[PRI]
					,[PlanVersion]
					,[Org]
					,[LotInvalidDate]
					,[Factoryorg]
					,[IsReplaced]
					,[IsUrgent]
					,[IsFirm]
					,[OriginalSupplyDocNo]
					,[OriginalSupplyDocVersion]
					,[OriginalSupplyLineNum]
					,[OriginalSupplyPlanLineNum]
					,[IsByproduct]
					,[Project]
					,[Task]
					,[ActionDate]
					,[StartDate]
					,[ProductionLine]
					,[ReserveQty]
					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,[originalSupplyHeader]
					,[PlanOrderSupplyType]
					,[ForecastOrderType]
					,[MultiHierarchyExpandFlag]
					,[ByHand]
					,[BOMMaster]
					,[AlternateType]  --生产目的  yanx于2012.10.29添加
				)
				Select 
					[Item]			
					,[ItemVersion]
					,[FromDegree]
					,[ToDegree]
					,[FromPotency]
					,[ToPotency]
					,[DemandCode]
					,[Lot]
					,[Supplier]
					,[OwnerOrg]
					,[WareHouse]
					,4							--MPS计划
					,[MasterPlandetail]
					,[OBaseUOM]
					,@TmpSupplyBaseQty - @TmpSUMBaseQty
					,[StoreMainUOM]
					,@TmpSupplySMQty - @TmpSUMSMQty
					,@TmpSupplySMQty - @TmpSUMSMQty 
					,@TmpSupplyDate
					,@TmpSupplySMQty - @TmpSUMSMQty
					,[PRI]
					,[PlanVersion]
					,[Org]
					,'9999-12-31'
					,[Org]
					,0
					,0
					,[IsFirm]
					,''
					,''
					,0
					,0
					,0
					,[Project]
					,[Task]
					,'1900-01-01'
					,'1900-01-01'
					,null
					,0
					,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
					,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
					,[MasterPlan]
					,[PlanOrderSupplyType]
					,[ForecastOrderType]
					,[MultiHierarchyExpandFlag]
					,[ByHand]
					,[BOMMaster]
					,[AlternateType]  --生产目的  yanx于2012.10.29添加
				from MRP_MPMapping_Temp 
				where [ID] = @TmpID;
			end
			set @TmpCount = @Tmpcount + 1
		end
		fetch next from MPSProcessRep into @TmpStartDate,@TmpEndDate,@TmpOBaseUOM,@TmpSMUOM,@TmpSupplySMQty,@TmpSupplyBaseQty,@TmpID;
	end
	close MPSProcessRep;
	deallocate MPSProcessRep;
--	end

	--将物料库存可用量也作为供应写入供应暂存表，其供应日期为计划开始日期
	--物料库存应为当天，吴峥于2009.07.10修改
	--在现存量收集时没有做分组合并的动作,所以在预处理时需要做分组合并操作;
	Insert Into MRP_SupplyTemp
	(
		[Item]	
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[DemandCode]
		,[Lot]	
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,[SupplyType]
		,[originalSupply]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[OriginalQty]
		,[SupplyQty]
		,[SupplyDate]
		,[RemainQty]
		,[PRI]
		,[PlanVersion]
		,[Org]
		,[LotInvalidDate]
		,[Factoryorg]
		,[IsReplaced]
		,[IsUrgent]
		,[IsFirm]
		,[OriginalSupplyDocNo]
		,[OriginalSupplyDocVersion]
		,[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum]
		,[IsByproduct]
		,[Project]
		,[Task]
		,[ActionDate]
		,[StartDate]
		,[ProductionLine]
		,[ReserveQty]
		,[LotUsedDate]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
	)
	Select 
		[Item]		
		,[ItemVersion]
		,[Degree]
		,[Degree]
		,[Potency]
		,[Potency]
		,-1
		,[Lot]
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,0
		,OhHand--null 改用在手量头ID，用于实时追溯区分现存量
		,[StoreMainUOM]
		,sum([SMQty])
		,[StoreMainUOM]
		,sum([SMQty])
		,sum([SMQty])
		--将getDate转为年/月/日格式,吴峥于2009.07.10修改
		,cast(convert(nvarchar(20),@CurrentDate,112) as datetime)
		,sum([SMQty])
		,[PRI]
		,@PlanVersion
		,[Org]
		,isnull([LotEffectiveDate],'9999-12-31')
		,[Org]
		,0
		,0
		,0
		,''
		,''
		,0
		,0
		,0
		,[Project]
		,[Task]
		,'1900-01-01'
		,'1900-01-01'
		,null	
		,0	
		,max([LotUsedDate])
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
	from MRP_ItemCurQtyMapping_Temp
	Where [PlanVersion] = @PlanVersion
	group by [Org],[Item],[ItemVersion],[Degree],[Potency],[Warehouse],[Supplier],[Lot],
		[StoreMainUOM],[LotEffectiveDate],[OwnerOrg],[Project],[Task],[SeiBan],[SeiBanCode],OhHand,[PRI]
	having sum([SMQty]) > 0;

	--将库存在途量作为供应写入供应暂存表(New)
	Insert Into MRP_SupplyTemp
	(
		[Item]	
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[DemandCode]
		,[Lot]	
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,[SupplyType]
		,[originalSupply]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[OriginalQty]
		,[SupplyQty]
		,[SupplyDate]
		,[RemainQty]
		,[PRI]
		,[PlanVersion]
		,[Org]
		,[LotInvalidDate]
		,[Factoryorg]
		,[IsReplaced]
		,[IsUrgent]
		,[IsFirm]
		,[OriginalSupplyDocNo]
		,[OriginalSupplyDocVersion]
		,[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum]
		,[IsByproduct]
		,[Project]
		,[Task]
		,[ActionDate]
		,[StartDate]
		,[ProductionLine]
		,[ReserveQty]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[originalSupplyHeader]
	)
	Select 
		A.[Item]		
		,A.[ItemVersion]
		,A.[Degree]
		,A.[Degree]
		,A.[Potency]
		,A.[Potency]
		,-1
		,A.[LotNo]
		,A.[Supplier]
		,A.[OwnerOrg]
		,A.[WH]
		,6
		,A.[TransOutSubLine]
		,A.[TUBaseUOM]
		,A.[TUBQty]
		,A.[StoreMainUOM]
		,A.[SMUQty]
		,A.[SMUQty]
		,A.[WCArriveDate]
		,A.[SMUQty]
		,A.[Priority]
		,A.[PlanVersion]
		,A.[TransOutOrg]
		,'9999-12-31'
		,A.[Org]
		,0
		,0
		,0
		,A.[DocNo]--''
		,A.[DocVersion]--''
		,A.[LineNum]
		,A.[PlanLineNum]
		,0
		,[Project]
		,[Task]
		,'1900-01-01'
		,'1900-01-01'
		,null	
		,0	
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,A.[TransOut]
	from MRP_OnRoadMapping_Temp A 
--		inner join MRP_ExpandItemMapping_Temp B on A.[PlanVersion] = B.[PlanVersion] 
--											and A.[Org] = B.[Org] 
--											and A.[Item] = B.[Item]
	Where A.[PlanVersion] = @PlanVersion;
	--sylviahj 07/12/17 删除掉不在计划名称开始/结束日期范围内的供需
--	delete from MRP_DemandTemp where [PlanVersion] = @PlanVersion and ([WorkCalendarDemandDate] < @StartDate or [WorkCalendarDemandDate] > @EndDate);
--	delete from MRP_SupplyTemp where [PlanVersion] = @PlanVersion and ([SupplyDate] < @StartDate or [SupplyDate] > @EndDate);

	--将外部需求来源映像中需求数量小于零的座位供应写到供应暂存表（需求小于零表示为联副产品的供应）	
	Insert Into MRP_SupplyTemp
	(
		[Item],[ItemVersion],[FromDegree],[ToDegree],[FromPotency]
		,[ToPotency],[DemandCode],[Lot]	,[Supplier],[OwnerOrg],[WareHouse],[SupplyType]
		,[originalSupply],[TradeUOM],[TradeQty],[INVUOM],[OriginalQty],[SupplyQty],[SupplyDate]
		,[RemainQty],[PRI],[PlanVersion],[Org],[LotInvalidDate],[Factoryorg],[IsReplaced]
		,[IsUrgent],[IsFirm],[OriginalSupplyDocNo],[OriginalSupplyDocVersion],[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum],[IsByproduct],[Project],[Task],[ActionDate],[StartDate]
		,[ProductionLine],[ReserveQty],[ForecastOrderType]
	)
	Select 
		t1.[Item],t1.[ItemVersion],t1.[FromDegree],t1.[ToDegree],t1.[FromPotency],t1.[ToPotency],
		t1.[DemandCode],t1.[Lot],t1.[Supplier],t1.[OwnerOrg],t1.[WareHouse],4--(联副产品)
		,t1.[SourceDocLine],t1.[OBaseUOM],abs(t1.[OBaseQty]),t1.[StoreMainUOM],abs(t1.[DemandSMQty]),
		abs(t1.[DemandSMQty]),t1.[WorkCalendarStartDate],abs(t1.[DemandSMQty]),@MinPri,
		t1.[PlanVersion],t1.[SourceOrg],'9999-12-31',t1.[Org],0,0,t1.[IsFirm],isnull(t1.[SourceDocNo],''),
		t1.[SourceDocVersion],t1.[Linenum],t1.[PlanLineNum],1,t1.[Project],t1.[Task],'1900-1-1',
		'1900-1-1',null,0,t1.[ForecastOrderType]
	from MRP_DemandInterfaceMapping_Temp t1
	Where t1.[PlanVersion] = @PlanVersion 
		and t1.[SourceType] = 5 and t1.[DemandSMQty] < 0; --5来源于MPS
		
	
	--调拨申请单
	if(@isNewPlanPattern=0 and @isOnRoad=1) or(@isNewPlanPattern<>0 and @IsConsiderOnRoad = 1)
	begin
		Insert Into MRP_SupplyTemp
	(
		[Item]	
		,[ItemVersion]
		,[FromDegree]
		,[ToDegree]
		,[FromPotency]
		,[ToPotency]
		,[DemandCode]
		,[Lot]	
		,[Supplier]
		,[OwnerOrg]
		,[WareHouse]
		,[SupplyType]
		,[originalSupply]
		,[TradeUOM]
		,[TradeQty]
		,[INVUOM]
		,[OriginalQty]
		,[SupplyQty]
		,[SupplyDate]
		,[RemainQty]
		,[PRI]
		,[PlanVersion]
		,[Org]
		,[LotInvalidDate]
		,[Factoryorg]
		,[IsReplaced]
		,[IsUrgent]
		,[IsFirm]
		,[OriginalSupplyDocNo]
		,[OriginalSupplyDocVersion]
		,[OriginalSupplyLineNum]
		,[OriginalSupplyPlanLineNum]
		,[IsByproduct]
		,[Project]
		,[Task]
		,[ActionDate]
		,[StartDate]
		,[ProductionLine]
		,[ReserveQty]
		,[originalSupplyHeader]
		,[originalSupplyLine]
		,[SeiBan]--增加Senban维度，吴峥于2009.06.10增加
		,[SeiBanCode]--增加SenbanCode冗余维度，吴峥于2009.06.10增加
		,[POBusinessType]
		,[BOMMaster]  --委外PR行记录BOMMaster yanx于2011.10.11添加
		,[IsSubcontract]--委外标识 yanx于2011.10.16添加
	)
	Select 
		A.[TransInItem]		
		,A.[ItemVersion]
		,A.[Degree]
		,A.[Degree]
		,A.[Potency]
		,A.[Potency]
		,-1
		,A.[LotNo]
		,A.[Supplier]
		,A.[TransInOrg]   ------临时修改成本组织
		,A.[TransInWH]
		,11
		,A.[TransApplyLine]
		,A.[TradeUOM] 
		,A.[TUQty]
		,A.[StoreMainUOM]
        ,A.[TUQty]
		,A.[SMUQty] 
		,A.[RequireDate]
		,A.[SMUQty] 
		,0
		,A.[PlanVersion]
		,A.[TransOutOrg]
		,'9999-12-31'
		,A.[TransInOrg]
		,0
		,0
		,0
		,isnull(A.[DocNo],'')
		,0
		,0
		,0
		,0
		,A.[Project]
		,0
		,'1900-01-01'
		,'1900-01-01'
		,null
		,0
		,A.[TransferApply]
		,null
		,A.[SeiBan]
		,NULL
		,NULL
		,NULL 
		,NULL
	from [MRP_TransApplyMapping_Temp] A 
	Where A.[PlanVersion] = @PlanVersion and A.[TUQty] > 0 and A.[TransInItem] > 0;

	--对调拨单进行存储地点过滤 by qinhjc on 20161223
	if(@isNewPlanPattern=0)--老计划
	BEGIN
		IF(@isWHOnlyControlStock<>1 and @whyn=1)--1.1 未勾选存储地点只控制库存，需求需要进行存储地点进行控制
		BEGIN
			delete A from MRP_SupplyTemp A
			WHERE A.[SupplyType]=11  and A.[PlanVersion]=@PlanVersion
			--AND A.[Factoryorg] IN
			--(
			--	select C.Org from MRP_PlanVersion as D 
		 --       inner join MRP_PlanName as B on B.ID = D.[PlanName] and D.ID = @PlanVersion
		 --       inner join MRP_PlanWareHouse as C on C.[PlanStrategy] = B.[PlanStrategy]
			--)
			AND not exists
			(
				select top 1 0 from MRP_PlanVersion as D 
		        inner join MRP_PlanName as B on B.ID = D.[PlanName] and D.ID = @PlanVersion
		        inner join MRP_PlanWareHouse as C on C.[PlanStrategy] = B.[PlanStrategy]
				WHERE A.[WareHouse]=C.WareHouse 
			);
		END
	END
	end
	

/**********************************************************************************************************
------------------------------所有供应写入供应暂存表结束---------------------------------------------------
**********************************************************************************************************/


/**********************************************************************************************************
------------------------------根据计划组织过滤供应暂存表开始-----------------------------------------------
**********************************************************************************************************/
--根据计划组织过滤收集的供应 By jiangjief 2018-08-20
--供应保留 组织=计划组织.工厂组织；或者计划组织的工厂-营运组织有工厂/物流-采购的组织间业务关系，组织=计划组织.营运组织
delete A from MRP_SupplyTemp A
inner join #MRP_PlanOrg_Temp B on A.[Factoryorg] = B.[DSOrg]
left join (
select FactoryOrg as PlanOrg from #MRP_PlanOrg_Temp 
union
select DSOrg as PlanOrg from #MRP_PlanOrg_Temp P 
inner join CBO_OrgBusinessRelation B on P.[DSOrg] = B.[ToOrg] and P.[FactoryOrg] = B.[FromOrg] and B.BusinessRelationType in (32,42) --物流-采购、工厂-采购
) C on A.[Factoryorg] = C.PlanOrg
where A.[PlanVersion] = @PlanVersion and C.PlanOrg is null


--考虑过期供应 过滤供应 By jiangjief 2019-02-18
if(@isNewPlanPattern = 0 and @isOverDemand = 1 and @isOverSupply = 0)
begin
	--旧计划模式 勾选了处理过期供需，但是没有勾选考虑过期供应
	delete from MRP_SupplyTemp where SupplyDate < @StartDate
end
else if(@isNewPlanPattern <> 0 and @OverDateDays >0 and @isOverSupply = 0)
begin
	--新计划模式 设置了过期供需天数，但是没有勾选考虑过期供应
	delete from MRP_SupplyTemp where SupplyDate < DateAdd(day,@OverDateDays,@StartDate)
end

   

/**********************************************************************************************************
------------------------------根据计划组织过滤供应暂存表结束-----------------------------------------------
**********************************************************************************************************/


/**********************************************************************************************************
------------------------------更新需求供应的LLC------------------------------------------------------------
------------------------------此过程可以在写入需求供应的时候进行，有时间进行重构，吴峥于2009.09.05注释-----
**********************************************************************************************************/

	--sylviahj 08.05.06 按新方法作,此处不需要了
--	Execute MRP_ProcessFTLI @planversion;
	--sylviahj 070517 处理需求暂存和供应暂存上的LLC，净算构造内存对象时使用
	update A 
		set A.[LLC] = B.[LowLevelCode]
	from MRP_DemandTemp A 
		inner join MRP_ExpandItemMapping_Temp B on A.[Item] = B.[Item] 
												and A.[PlanVersion] = B.[PlanVersion]
	where A.[PlanVersion] = @PlanVersion;

	update A 
		set A.[LLC] = B.[LowLevelCode]
	from MRP_SupplyTemp A 
		inner join MRP_ExpandItemMapping_Temp B
	on A.[Item] = B.[Item] 
		and A.[PlanVersion] = B.[PlanVersion]
	where A.[PlanVersion] = @PlanVersion;

/**********************************************************************************************************
------------------------------如果读入了MPS供应,则向下展开,并将子件的计划方法为MPS的物料写入需求暂存中-----
------------------------------MPS子件需求改在净算过程中产生，吴峥于2010.03.17修改--------------------------
**********************************************************************************************************/

--	if ((@IsMPS = 1) and (@PlanMethod in (@PlanMethodMPS,@PlanMethodMPSDRP)))
--	begin
--		exec MRP_GenMPSComponent @PlanVersion,@WorkCalendar,1,1;
--	end

/**********************************************************************************************************
------------------------------如果不考虑批号，则清空供需暂存表中的批号，并置供应暂存表中现存量的优先级为零-
**********************************************************************************************************/

	declare @SupplyType_OnHand int
	set @SupplyType_OnHand = 0 --现存量
	declare @PRI_Max int
	set @PRI_Max = 0 --0表示最大
 	if (@IsLot = 0)
	begin
		--update MRP_DemandTemp set [Lot] = ''
		--where [PlanVersion] = @PlanVersion;

		update MRP_SupplyTemp set [PRI] = @PRI_Max
		where [PlanVersion] = @PlanVersion and [SupplyType] = @SupplyType_OnHand and isnull([Lot],'') <> '';

		--update MRP_SupplyTemp set [Lot] = ''
		--where [PlanVersion] = @PlanVersion;
	end

/**********************************************************************************************************
------------------------------如果物料为ute料,则不考虑安全库存,置demandtemp表的IsSaftyQty为false-----------
**********************************************************************************************************/

	update A 
		set A.[IsSecurityStock] = 0 
	from MRP_DemandTemp A
	where exists
		(
			select 0 
			from CBO_BOMComponent B 
				inner join CBO_BOMMaster C on B.[BOMMaster] = C.[ID] 
			where C.[Status] = @BOMStatus_Approved
				and A.[Item] = B.[ItemMaster] 
				and B.[SubstituteStyle] = @SubStyleReplace
		) and A.[PlanVersion] = @PlanVersion and A.[IsSecurityStock] = 1;
		
		
	update A 
		set A.[IsSecurityStock] = B.IsSecurityStock  
	from MRP_DemandTemp A 
		inner join MRP_ExpandItemMapping_temp B on A.Item =B.Item 
										and A.Factoryorg =B.Org 
										and A.[PlanVersion] = @PlanVersion 
										and B.PlanVersion = @PlanVersion
	where A.IsSecurityStock is null

/**********************************************************************************************************
------------------------------处理di和picklist记录---------------------------------------------------------
**********************************************************************************************************/

	exec mrp_processdiandpl @planversion;
	update mrp_demandtemp 
		set transoutwh = [WareHouse] 
	where planversion = @planversion and transoutwh is null

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=29
    insert into [MRP_ProcessLog] values(@planversion,0,30,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

	--sylviahj 07/11/09 对demandtemp或supplytemp中存在物料受版本控制，但又没有给出版本的记录，更新为当前有效版本
--	update A set A.[ItemVersion] = C.[Version]
--	from MRP_DemandTemp A inner join MRP_ExpandItemMapping_Temp B on A.[PlanVersion] = B.[PlanVersion]
--	and A.[Item] = B.[Item] inner join CBO_ItemMasterVersion C on B.[Item] = C.[Item]
--	where A.[PlanVersion] = @PlanVersion and B.[IsVersionControl] = 1 and isnull(A.[ItemVersion],'') = ''
--	and A.[WorkCalendarDemandDate] between C.[Effective_EffectiveDate] and C.[Effective_DisableDate];
--
--	update A set A.[ItemVersion] = C.[Version]
--	from MRP_SupplyTemp A inner join MRP_ExpandItemMapping_Temp B on A.[PlanVersion] = B.[PlanVersion]
--	and A.[Item] = B.[Item] inner join CBO_ItemMasterVersion C on B.[Item] = C.[Item]
--	where A.[PlanVersion] = @PlanVersion and B.[IsVersionControl] = 1 and isnull(A.[ItemVersion],'') = ''
--	and A.[SupplyDate] between C.[Effective_EffectiveDate] and C.[Effective_DisableDate];

	--净改变时，需要将计划参数中最近一次计划版本的资源需求读入
	--由于净改变是在原计划版本上执行，而不是新建一个计划版本，所以不需要将上次计划版本的资源需求读入
--	if @netchangeyn = 1			
--	Begin
--		Insert Into MRP_MoresMapping_Temp
--		(					
--			[Factoryorg]
--			,[Mores]
--			,[PlanVersion]
--			,[MO]				
--			,[ResQtyUOM]
--			,[ResUsageUOM]
--			,[ResBasis]
--			,[ResQty]
--			,[PlanTotalQty]
--			,[Res]					--新增
--			,[Item]
--			,[ItemVersion]
--			,[StartDate]
--			,[ActualTotalQty]
--			,[OpSeq]
--			,[ResSeq]
--			,[IsRouting]
--		)
--		Select 				
--			t3.[Org]
--			,t3.[MODocRes_EntityID]
--			,t3.[PlanVersion]
--			,t3.[Doc_EntityID]				
--			,t3.[ResQtyUOM]
--			,t3.[ResUsageUOM]
--			,t3.[UsageBasis]
--			,t3.[ResQty]
--			,t3.[DemandQty]
--			,t3.[Res]
--			,t3.[Item]
--			,t3.[ItemVersion]
--			,t3.[StartDate]
--			,t3.[DemandQty]
--			,t3.[OpSeq]
--			,t3.[ResSeq]
--			,t3.[IsRouting]
--		from MRP_PlanParams t1 inner join MRP_PlanVersion t2 on
--		t1.[LatestMRPlanName] = t2.[ID] inner join MRP_ResDemand t3 on
--		t2.[ID] = t3.[PlanVersion]
--		where not exists(select 0 from MRP_ExpandItemMapping_Temp t4
--		where t3.[Org] = t4.[Org] and t3.[Item] = t4.[Item];
--	End

/**********************************************************************************************************
------------------------------获得预留---------------------------------------------------------------------
**********************************************************************************************************/

	exec MRP_GetReservation @PlanVersion;
--没有必要在处理一边预留量的单位了，吴峥于2009.09.05注释
--	update MRP_SupplyTemp 
--		set [ReserveQty] = dbo.fn_MRP_GetConvertRatio(A.[ReserveQty], A.[TradeUOM], A.[INVUOM], A.[Item], B.[ConvertRule])
--	from MRP_SupplyTemp as A 
--		inner join MRP_ExpandItemMapping_Temp as B on A.planversion=@PlanVersion 
--													and A.[ReserveQty] > 0 and A.[Item]=B.[Item]
--													and A.[Factoryorg] = B.[Org]
--	--where A.[ReserveQty] > 0 and A.planversion=@PlanVersion
--	update MRP_DemandTemp 
--		set [ReserveQty] = dbo.fn_MRP_GetConvertRatio(A.[ReserveQty], A.[TradeUOM], A.[INVUOM], A.[Item], B.[ConvertRule])
--	from MRP_DemandTemp as A 
--		inner join MRP_ExpandItemMapping_Temp as B on A.[ReserveQty] > 0 
--													and A.planversion=@PlanVersion 
--													and A.[Item]=B.[Item]
--													--增加组织过滤条件--吴峥于2009.04.02增加此逻辑
--													and A.[Org] = B.[Org]
--													--where A.[ReserveQty] > 0 and A.planversion=@PlanVersion

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=30
    insert into [MRP_ProcessLog] values(@planversion,0,31,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
-----------------计划易用性改进支持计划区域的存储地点和需求分类范围 --yanx于2014.09.25添加-----------------
**********************************************************************************************************/
	if(ISNULL(@planEOUScope,'') > '0')
	begin
		declare @IsOnlyWH	bit;
		declare @IsExcudeDC		bit;
		--如果没有对应的记录，值将为null
		select top 1 @IsOnlyWH = B.IsOnlyWH
		from MRP_PlanEOUScopeRegion A inner join MRP_PlanEOURegion B on B.ID = A.PlanEOURegion
			inner join MRP_PlanEOURegionWH C on C.PlanEOURegion = B.ID
		where A.PlanEOUScope = @planEOUScope;
		
		select top 1 @IsExcudeDC = B.IsExculdeDemand
		from MRP_PlanEOUScopeRegion A inner join MRP_PlanEOURegion B on B.ID = A.PlanEOURegion
			inner join MRP_PlanEOURegionDC C on C.PlanEOURegion = B.ID
		where A.PlanEOUScope = @planEOUScope;
		
		if @IsOnlyWH = 0
		begin
			update A set A.IsExecByWh = 1
			from MRP_PlanName A inner join MRP_PlanVersion B on B.PlanName = A.ID and B.ID = @PlanVersion;
			
			delete A from MRP_DemandTemp A
			where A.PlanVersion = @PlanVersion and not exists
			(
				select top 1 0 from MRP_PlanEOUScopeRegion B
					inner join MRP_PlanEOURegionWH C on C.PlanEOURegion = B.PlanEOURegion
				where B.PlanEOUScope = @planEOUScope and C.Wharehouse = A.Warehouse
			);
		end
		
		if @IsOnlyWH is NOT NULL
        
   --     SELECT @isWHOnlyControlStock=isnull(E.IsWHOnlyControlStock,0)  
   --         FROM MRP_PlanVersion A 
   --         left JOIN MRP_PlanName B ON A.PlanName=B.ID
			--left JOIN MRP_PlanEOUScope C ON C.ID =B.PlanScope
   --         left JOIN MRP_PlanEOUScopeRegion D ON D.PlanEOUScope=C.ID AND D.PlanEOURegion IS NOT NULL
   --         left JOIN MRP_PlanEOURegion E ON E.ID=D.PlanEOURegion
			--WHERE A.ID=@PlanVersion; 
			
		begin
			delete A from MRP_SupplyTemp A
			where A.PlanVersion = @PlanVersion AND
			((@isWHOnlyControlStock=0 AND not exists
			(
				select top 1 0 from MRP_PlanEOUScopeRegion B
					inner join MRP_PlanEOURegionWH C on C.PlanEOURegion = B.PlanEOURegion
				where B.PlanEOUScope = @planEOUScope and C.Wharehouse = A.Warehouse
			)) 
			OR (@isWHOnlyControlStock=1 AND A.SupplyType=0 AND not exists
			(
				select top 1 0 from MRP_PlanEOUScopeRegion B
					inner join MRP_PlanEOURegionWH C on C.PlanEOURegion = B.PlanEOURegion
				where B.PlanEOUScope = @planEOUScope and C.Wharehouse = A.Warehouse
			)));
		end

		if @IsExcudeDC = 0
		begin
			delete A from MRP_DemandTemp A
			where A.PlanVersion = @PlanVersion and isnull(A.DemandCode,-1) > -1 and not exists
			(
				select top 1 0 from MRP_PlanEOUScopeRegion B
					inner join MRP_PlanEOURegionDC C on C.PlanEOURegion = B.PlanEOURegion
				where B.PlanEOUScope = @planEOUScope and C.DemandCode = A.DemandCode
			);

			delete A from MRP_SupplyTemp A
			where A.PlanVersion = @PlanVersion and isnull(A.DemandCode,-1) > -1 and not exists
			(
				select top 1 0 from MRP_PlanEOUScopeRegion B
					inner join MRP_PlanEOURegionDC C on C.PlanEOURegion = B.PlanEOURegion
				where B.PlanEOUScope = @planEOUScope and C.DemandCode = A.DemandCode
			);
		end
		
		if @IsExcudeDC = 1
		begin
			delete A from MRP_DemandTemp A
			where A.PlanVersion = @PlanVersion and isnull(A.DemandCode,-1) > -1 and exists
			(
				select top 1 0 from MRP_PlanEOUScopeRegion B
					inner join MRP_PlanEOURegionDC C on C.PlanEOURegion = B.PlanEOURegion
				where B.PlanEOUScope = @planEOUScope and C.DemandCode = A.DemandCode
			);

			delete A from MRP_SupplyTemp A
			where A.PlanVersion = @PlanVersion and isnull(A.DemandCode,-1) > -1 and exists
			(
				select top 1 0 from MRP_PlanEOUScopeRegion B
					inner join MRP_PlanEOURegionDC C on C.PlanEOURegion = B.PlanEOURegion
				where B.PlanEOUScope = @planEOUScope and C.DemandCode = A.DemandCode
			);
		end
		
	end
    ELSE
    BEGIN
    	--SELECT @isWHOnlyControlStock=B.IsWHOnlyControlStock
	    --FROM MRP_PlanName A
	    --INNER JOIN MRP_PlanStrategy B ON B.ID=A.PlanStrategy
	    --INNER JOIN MRP_PlanVersion C ON C.PlanName=A.ID
	    --WHERE A.IsExecByPlanStrategy=1 AND C.ID=@PlanVersion;
	    IF(@isWHOnlyControlStock=1)
	    BEGIN
	    	delete A from MRP_SupplyTemp A
			where A.PlanVersion = @PlanVersion AND A.SupplyType=0 
			--AND A.[Factoryorg] IN
			--(
			--	select C.Org from MRP_PlanVersion as D 
		 --       inner join MRP_PlanName as B on B.ID = D.[PlanName] and D.ID = @PlanVersion
		 --       inner join MRP_PlanWareHouse as C on C.[PlanStrategy] = B.[PlanStrategy]
			--) 
			AND not exists
			(
				select top 1 0 from MRP_PlanVersion as D 
		        inner join MRP_PlanName as B on B.ID = D.[PlanName] and D.ID = @PlanVersion
		        inner join MRP_PlanWareHouse as C on C.[PlanStrategy] = B.[PlanStrategy]
				WHERE A.WareHouse=C.WareHouse 
			);
	    END
    END

/**********************************************************************************************************
----------------------------更新需求表的需求日期,供应表的供应日期,去掉时分秒-----------------------------
**********************************************************************************************************/

	update MRP_SupplyTemp 
		set [SupplyDate]=cast(convert(nvarchar(20),[SupplyDate],112) as datetime)
	where PlanVersion = @planVersion

	update MRP_DemandTemp 
		set [DemandDate]=cast(convert(nvarchar(20),[DemandDate],112) as datetime)
	where PlanVersion = @PlanVersion

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=31
    insert into [MRP_ProcessLog] values(@planversion,0,32,getdate(),'1900-1-1',0)
    set @LastDate=getdate()

/**********************************************************************************************************
----------------------------去掉删除bom母项是虚拟件的bom映像--吴峥于2009.03.18修改此逻辑-------------------
----------------------------去掉删除无需求的零阶bom数据--吴峥于2009.05.31修改此逻辑------------------------
***********************************************************************************************************/
    --删除bom母项是虚拟件的bom映像--吴峥于2009.03.18注释
--	delete A from MRP_BOMMapping_Temp A inner join MRP_ExpandItemMapping_Temp B on 
--	A.[PlanVersion] = B.[PlanVersion] and A.[BOMMasterItem] = B.[Item]
--	and A.[Org] = B.[Org] and A.planversion=@PlanVersion  and B.itemtype=@PHANTOM

    --删除没有需求的LLC=0的BOM映像
--	delete A from mrp_bommapping_temp A inner join mrp_expanditemmapping_temp B 
--	on A.bommasteritem=b.item and A.planversion=B.planversion and A.planversion=@PlanVersion 
--	where b.lowlevelcode =0 and  B.itemcode not in(select b.itemcode from mrp_demandtemp A inner join mrp_expanditemmapping_temp B 
--	on A.item=b.item and A.planversion=B.planversion and A.planversion=@PlanVersion)

/**********************************************************************************************************
------------------------------增加项目、任务、厂牌的向工厂组织的转化--吴峥于2009.04.03增加此逻辑-----------
**********************************************************************************************************/

	declare @IsProjectSend bit;
	select @IsProjectSend = IsSend from CBO_BaseObject A inner join UBF_MD_Class B on B.Local_ID = A.EntityType
	where B.FullName in('UFIDA.U9.CBO.SCM.ProjectTask.Project');
	
	--项目为参照模式不再找默认参照组织的ID，直接用来源ID即可  yanx于2014.07.31修改
	if @IsProjectSend = 1
	begin
		update A set
		A.[Project] = isnull(B.[ID],C.[ID])
		from MRP_DemandTemp as A
		inner join CBO_Project as Z on A.[Project] = Z.[ID] 
								and A.Planversion = @Planversion
		left join CBO_Project as B on Z.[Code] = B.[Code] and A.[FactoryOrg] = B.[Org]
		left join CBO_SendObject as D on D.[Org] = A.[FactoryOrg] and D.[Org] <> D.[RefOrg] and D.[BaseObject] = @ProjectTaskObject
		left join CBO_Project as C on Z.[Code] = C.[Code] and C.[Org] = D.[RefOrg]
		where 
		A.[Org] <> A.[FactoryOrg] 
	--	and ((B.[ID] is not null) or (C.[ID] is not null))

		update A set
		A.[Task] = isnull(B.[ID],C.[ID])
		from MRP_DemandTemp as A
		inner join CBO_Task as Z on A.[Task] = Z.[ID] 
								and A.Planversion = @Planversion
		left join CBO_Task as B on Z.[Code] = B.[Code] and A.[FactoryOrg] = B.[Org]
								and A.project = B.project
		left join CBO_SendObject as D on D.[Org] = A.[FactoryOrg] and D.[Org] <> D.[RefOrg] and D.[BaseObject] = @ProjectTaskObject
		left join CBO_Task as C on Z.[Code] = C.[Code] and C.[Org] = D.[RefOrg]
								and A.project = C.project
		where 
		A.[Org] <> A.[FactoryOrg]
	--	and ((B.[ID] is not null) or (C.[ID] is not null))

		update A set
		A.[Project] = isnull(B.[ID],C.[ID])
		from MRP_SupplyTemp as A
		inner join CBO_Project as Z on A.[Project] = Z.[ID]
									and A.Planversion = @Planversion 
		left join CBO_Project as B on Z.[Code] = B.[Code] and A.[FactoryOrg] = B.[Org]
		left join CBO_SendObject as D on D.[Org] = A.[FactoryOrg] and D.[Org] <> D.[RefOrg] and D.[BaseObject] = @ProjectTaskObject
		left join CBO_Project as C on Z.[Code] = C.[Code] and C.[Org] = D.[RefOrg]
		where 
		A.[Org] <> A.[FactoryOrg]
	--	and ((B.[ID] is not null) or (C.[ID] is not null))

		update A set
		A.[Task] = isnull(B.[ID],C.[ID])
		from MRP_SupplyTemp as A
		inner join CBO_Task as Z on A.[Task] = Z.[ID] 
									and A.Planversion = @Planversion
		left join CBO_Task as B on Z.[Code] = B.[Code] and A.[FactoryOrg] = B.[Org]
									and A.project = B.project
		left join CBO_SendObject as D on D.[Org] = A.[FactoryOrg] and D.[Org] <> D.[RefOrg] and D.[BaseObject] = @ProjectTaskObject
		left join CBO_Task as C on Z.[Code] = C.[Code] and C.[Org] = D.[RefOrg]
									and A.project = C.project
		where 
		A.[Org] <> A.[FactoryOrg]
	--	and ((B.[ID] is not null) or (C.[ID] is not null))
	end
	
	update A set
	A.[Supplier] = isnull(B.[ID],C.[ID])
	from MRP_DemandTemp as A
	--A.[Task]-->A.[Supplier]  yanx于2013.04.04修改
	inner join CBO_Supplier as Z on A.[Supplier] = Z.[ID] 
								and A.Planversion = @Planversion
	left join CBO_Supplier as B on Z.[Code] = B.[Code] and A.[FactoryOrg] = B.[Org]
	left join CBO_SendObject as D on D.[Org] = A.[FactoryOrg] and D.[Org] <> D.[RefOrg] and D.[BaseObject] = @SupplierObject
	left join CBO_Supplier as C on Z.[Code] = C.[Code] and C.[Org] = D.[RefOrg]
	where 
	A.[Org] <> A.[FactoryOrg]
--	and ((B.[ID] is not null) or (C.[ID] is not null))

	update A set
	A.[Supplier] = isnull(B.[ID],C.[ID])
	from MRP_SupplyTemp as A
	--A.[Task]-->A.[Supplier]  yanx于2013.04.04修改
	inner join CBO_Supplier as Z on A.[Supplier] = Z.[ID] 
								and A.Planversion = @Planversion
	left join CBO_Supplier as B on Z.[Code] = B.[Code] and A.[FactoryOrg] = B.[Org]
	left join CBO_SendObject as D on D.[Org] = A.[FactoryOrg] and D.[Org] <> D.[RefOrg] and D.[BaseObject] = @SupplierObject
	left join CBO_Supplier as C on Z.[Code] = C.[Code] and C.[Org] = D.[RefOrg]
	where 
	A.[Org] <> A.[FactoryOrg]
--	and ((B.[ID] is not null) or (C.[ID] is not null))

 --   --删除ChannelQoh映像
	--delete A from MRP_ChannelQohMapping_Temp A 
	--where A.planversion=@PlanVersion

/**********************************************************************************************************
------------------------------处理Seiban传递问题--吴峥于2009.04.03增加此逻辑-------------------------------
**********************************************************************************************************/

	update D set
		D.[SeiBan] = 0,
		D.[SeiBanCode] = ''
	from MRP_DemandTemp as D
		inner join MRP_OrgRelation_Temp as O on O.FromOrg = D.Org
											and O.ToOrg = D.FactoryOrg
											and D.FactoryOrg <> D.Org
											and O.IsTransforSeiban = 0
											and D.Planversion = @Planversion
											and O.Planversion = @Planversion

	update S set
		S.[SeiBan] = 0,
		S.[SeiBanCode] = ''
	from MRP_SupplyTemp as S
		inner join MRP_OrgRelation_Temp as O on O.FromOrg = S.Org
											and O.ToOrg = S.FactoryOrg
											and S.FactoryOrg <> S.Org
											and O.IsTransforSeiban = 0
											and S.Planversion = @Planversion
											and O.Planversion = @Planversion

/**********************************************************************************************************
------------------------------ 处理备料厂牌组织问题 By jiangjief 2020-12-28 -------------------------------
**********************************************************************************************************/

	if exists(select top 1 0 from MRP_MOComponentSupplierMapping_Temp WHERE PlanVersion = @PlanVersion  and Supplier IS NOT NULL)
	begin
		update B set
			B.Supplier=D.ID
		from MRP_DemandTemp as A
		inner join MRP_MOComponentSupplierMapping_Temp B on A.PlanVersion=b.PlanVersion and A.originalDemand=B.PickListID
		inner join CBO_Supplier C on B.Supplier=C.ID and A.Factoryorg!=C.Org
		INNER JOIN CBO_Supplier D on C.Code=D.Code and A.Factoryorg=D.Org
		WHERE A.PlanVersion = @PlanVersion and A.originalDemandStatus IN (4,8,31,32) and B.Supplier IS NOT NULL
	end

/**********************************************************************************************************
------------------------------删除MRP计划中收集MPS料的需求信息以及非MPS供应信息--吴峥于2010.03.15增加此逻辑
**********************************************************************************************************/

	IF (@PlanMethod=@PlanMethodMRP or @PlanMethod = @PlanMethodMRPDRP)
	Begin

		IF object_id('tempdb..#MPSItemID') is not null
		Begin
			truncate table #MPSItemID
			drop table #MPSItemID
		End

		Create Table #MPSItemID
		(
			ItemID bigint default 0
		)
		
		insert into #MPSItemID
		(
			ItemID 
		)
		select distinct
			A.Item
		from MRP_ExpandItemMapping_Temp A
		where A.[PlanType] in (0,4)--MPS or DRP/MPS
		and A.Planversion = @Planversion

		--删除需求记录
		delete A
		from MRP_DemandTemp A 
			inner join #MPSItemID B on A.Item = B.ItemID
									and A.Planversion = @Planversion

		--删除非MPS的供应记录
		if @IsCalcByMPS = 0
			delete A 
			from MRP_SupplyTemp A	
				inner join #MPSItemID B on A.Item = B.ItemID
										and A.Planversion = @Planversion
			where A.[SupplyType] <> 4--MPS
		--按MPS料的计划订单直接计算  yanx于2014.10.08添加
		if @IsCalcByMPS = 1
			delete A 
			from MRP_SupplyTemp A	
				inner join #MPSItemID B on A.Item = B.ItemID
										and A.Planversion = @Planversion
			where A.[SupplyType] <> 4 and A.[SupplyType] <> 5 --MPS和计划订单
	End
		

/**********************************************************************************************************
------------------------------先删除当前计划版本的UOM记录，做重新收集，吴峥于2009.07.17增加此逻辑----------
**********************************************************************************************************/

	delete from MRP_UOM 
	where planversion = @PlanVersion

	delete from MRP_ItemConvertRatioInClass
	where planversion = @PlanVersion

	delete from MRP_ItemConvertRatioOverClass
	where planversion = @PlanVersion

/**********************************************************************************************************
------------------------------实时追溯供需净量处理  yanx于2015.05.10添加----------
**********************************************************************************************************/
--如果勾选运算前清除实时供需数据参数，则按当前组织删除实时供需表(cbo_rtdsinfo)中的所有内容 by qinhjc on 20160811
IF @IsCleanRTDSInfo=1
BEGIN
DELETE FROM CBO_RTDSInfo WHERE Org=@Org;	
END

if @IsRTPegging = 1
begin
	update A set
		A.NetQty = B.NetQty,A.RTDSInfoID = B.ID
	from MRP_DemandTemp A inner join CBO_RTDSInfo B on B.OriginalDoc_EntityID = A.originalDemand
	where A.PlanVersion = @PlanVersion;
	
	update A set
		A.ALCQty = (B.SMQty - B.NetQty),A.RTDSInfoID = B.ID
	from MRP_SupplyTemp A inner join CBO_RTDSInfo B on B.OriginalDoc_EntityID = A.originalSupply
	where A.PlanVersion = @PlanVersion;
end

/**********************************************************************************************************
------------------------------将计划名称结束时间重置为日期形式---------------------------------------------
**********************************************************************************************************/
	update A
		set A.[EndDate] = cast(Convert(nvarchar(20),A.[EndDate],112) as Datetime)
	from MRP_PlanName as A 
		inner join MRP_PlanVersion B on A.[ID]=B.[PlanName] and B.[ID]=@PlanVersion

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=32
    insert into [MRP_ProcessLog] values(@planversion,0,33,getdate(),'1900-1-1',0)
    set @LastDate=getdate();

/**********************************************************************************************************
---------------将需求PRI统一设置是为99，用于客户可开自己的需求排序--by qinhjc on 20170804----------------
**********************************************************************************************************/
	update A
		set A.[PRI] = 99
	from MRP_DemandTemp as A 
	where A.PlanVersion = @PlanVersion;

	update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=33;

END