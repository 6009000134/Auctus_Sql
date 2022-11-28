declare
	@PlanVersion    bigint=1001905311704959,
	@maxllc			int=99,
	@IsReCalcLLC	bit=1,
	@IsSub          int=1

BEGIN
	

	declare @llc	int
	declare @Count  int
	declare @BOMMaster bigint
	declare @CurrLevel int

    declare @LastDate datetime


	--常量：产品类型(联副产品)
	declare @CoProduct int
	declare @ByProduct int
	set @CoProduct = 2
	set @ByProduct = 1

	--常量：替代类型
	declare @All int
	declare @Part int
	set @All = 1
	set @Part = 2

	if((@IsReCalcLLC<>0 and @IsReCalcLLC <> 1) or (@maxllc < 0) or (@PlanVersion is null))
	begin
		select -2;
	end	

	--建立临时表，存储所有BOM母项，子项（不包括UTE物料）及联副产品
	create table #BOMMaster
	(
		[Org] bigint,
		[Item] bigint,
		[ItemCode] nvarchar(255),
		[BOMMaster] bigint,
		[BOMComponent] bigint
	)

	CREATE NONCLUSTERED INDEX [ItemCode_wuzheng] ON #BOMMaster 
	(
		[ItemCode] ASC
	)
	CREATE NONCLUSTERED INDEX [BOMMaster_wuzheng] ON #BOMMaster 
	(
		[BOMMaster] ASC
	)

	create table #BOMComponent
	(
		[Item] bigint,
		[Org] bigint,
		[IssueOrg] bigint,
		[UTEBOMComponent] bigint,
		[ItemCode] nvarchar(255),
		[BOMMaster] bigint,
		[BOMComponent] bigint,
		[Level] int
	)



	CREATE NONCLUSTERED INDEX [BOMComponent_sylvia_987] ON #BOMComponent 
	(
		[Item] ASC
	)
	CREATE NONCLUSTERED INDEX [BOMMaster_wuzheng] ON #BOMComponent 
	(
		[BOMMaster] ASC
	)

	--记录BOM子项标准件和替代件料品对应关系
	create table #BOMComponentSubItem
	(
		[Item] bigint,
		[SubItem] bigint
	)

	--根据BOM映像资料，读入所有BOM母项、子项(不包括UTE)到临时表中
    insert into [MRP_ProcessLog] values(@planversion,0,31,getdate(),'1900-1-1',0) 

	insert into #BOMMaster([Org],[Item],[ItemCode],[BOMMaster])
	select distinct A.[Org],A.[BOMMasterItem],B.[ItemCode],A.[BOMMaster]
	from MRP_BOMMapping_Temp A inner join MRP_ExpandItemMapping_Temp B on A.[PlanVersion] = B.[PlanVersion]
	and A.[Org] = B.[Org] and A.[BOMMasterItem] = B.[Item]
	where A.[PlanVersion] = @PlanVersion;

	insert into #BOMComponent([Item],[Org],[IssueOrg],[UTEBOMComponent],[ItemCode],
	[BOMMaster],[BOMComponent],[Level])
	select A.[BOMComponentItem],A.[Org],A.[IssueOrg],A.[UTEBOMComponent],A.[CompCode],
	A.[BOMMaster],A.[BOMComponent],0
	from MRP_BOMMapping_Temp A
	where A.[PlanVersion] = @PlanVersion and not exists(select 0 from MRP_BOMMapping_Temp C 
	where A.[BOMComponent] = isnull(C.[UTEBOMComponent],-1) and C.planversion =@planversion) OPTION( HASH JOIN) ;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=31
    insert into [MRP_ProcessLog] values(@planversion,0,32,getdate(),'1900-1-1',0)  

	--构造联副产品的母子关系（即母项为母，联副产品为子）
	insert into #BOMComponent([Item],[Org],[IssueOrg],[UTEBOMComponent],[ItemCode],
	[BOMMaster],[BOMComponent],[Level])
	select B.[ItemMaster],A.[Org],A.[Org],null,B.[ItemCode],A.[BOMMaster],null,-1
	from #BOMMaster A inner join MRP_DegreePercentMapping_Temp B on A.[BOMMaster] = B.[BOMMaster]
	where B.[ProductType] in(@CoProduct,@ByProduct) and B.[PlanVersion] = @PlanVersion;

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=32
    insert into [MRP_ProcessLog] values(@planversion,0,33,getdate(),'1900-1-1',0)  

	--由于替代件现在可以定义为A的替代件为A1，A1的替代件为A，则会出现死循环所以取消替代件计算低阶码逻辑
	--即替代件与子件具有相同的低阶码--吴峥于2009.11.06注释
	--构造替代件的母子关系（即子件作为母，替代件作为子）

	if (@IsSub <> 0)
	begin
		select @Count = count(0) from MRP_BOMMapping_Temp A where A.[PlanVersion] = @PlanVersion and A.[SubstituteType] in(@All,@Part);
		if (@Count > 0)
		begin
			insert into #BOMComponent
			(
				[Item],[Org],[IssueOrg],[UTEBOMComponent],[ItemCode],
				[BOMMaster],[BOMComponent],[Level]
			)
			select 
				A.[SubItem],B.[Org],B.[Org],null,A.[ItemCode],B.[BOMMaster],null,0
			from MRP_SubstituteMapping_Temp A inner join MRP_BOMMapping_Temp B on A.PlanVersion=B.PlanVersion and A.[BOMComponent] = B.[BOMComponent]
			where A.[PlanVersion] = @PlanVersion;


			--替代关系中，因为标准件和替代件的LLC要相同，这里对标准件和替代件拍平建立联系
			--记录BOM子项标准件和替代件料品对应关系
			create table #BOMComponentSubItem_First
			(
				[Item1] bigint,
				[Item2] bigint
			)

			create table #BOMComponentSubItem_Second
			(
				[Item1] bigint,
				[Item2] bigint
			)

			insert into #BOMComponentSubItem_First
			select distinct
				B.BOMComponentItem, A.[SubItem]
				from MRP_SubstituteMapping_Temp A 
			inner join MRP_BOMMapping_Temp B on A.PlanVersion=B.PlanVersion and A.[BOMComponent] = B.[BOMComponent]
			where A.[PlanVersion] = @PlanVersion;

			insert into #BOMComponentSubItem_Second([Item1],[Item2]) 			
			select  
				A.[Item1],A.[Item2]  
			from #BOMComponentSubItem_First A 

			insert into #BOMComponentSubItem_Second([Item1],[Item2]) 			
			select  
				A.[Item1],B.[Item2]  
			from #BOMComponentSubItem_First A 
			inner join #BOMComponentSubItem_First B on A.Item2=B.Item1 and A.Item1!=B.Item2-- A - B,B - C==>A - C 
			union
			select  
				A.[Item2],B.[Item2]  
			from #BOMComponentSubItem_First A 
			inner join #BOMComponentSubItem_First B on A.Item1=B.Item1 and A.Item2!=B.Item2-- A - B,A - C==>B - C
			union
			select  
				A.[Item1],B.[Item1]  
			from #BOMComponentSubItem_First A 
			inner join #BOMComponentSubItem_First B on A.Item2=B.Item2 and A.Item1!=B.Item1-- A - C,B - C==>A - B
			
			insert into #BOMComponentSubItem([Item],[SubItem]) 
			select  
				[Item1],[Item2]  
			from #BOMComponentSubItem_Second
			union
			select  
				[Item2],[Item1]  
			from #BOMComponentSubItem_Second

			truncate table #BOMComponentSubItem_First
			truncate table #BOMComponentSubItem_Second
			drop table #BOMComponentSubItem_First
			drop table #BOMComponentSubItem_Second
		end
	end

    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=33
    insert into [MRP_ProcessLog] values(@planversion,0,34,getdate(),'1900-1-1',0)  

	--构造UTE的母子关系（即被替代件为母，替代件为子）
	set @CurrLevel = 0;
	select @Count = count(0) from #BOMComponent A where A.[Level] = @CurrLevel and A.[UTEBOMComponent] is not null;
	while (@Count > 0)
	begin
		exec AllocSerials @Count,@BOMMaster output;

		insert into #BOMMaster([Org],[Item],[ItemCode],[BOMMaster],[BOMComponent])
		select A.[Org],A.[Item],A.[ItemCode],@BOMMaster + row_number() over(order by A.[Item]) - 1,A.[BOMComponent]
		from #BOMComponent A
		where A.[Level] = @CurrLevel and A.[UTEBOMComponent] is not null;

		insert into #BOMComponent([Item],[Org],[IssueOrg],[UTEBOMComponent],[ItemCode],
		[BOMMaster],[BOMComponent],[Level])
		select B.[BOMComponentItem],B.[Org],B.[IssueOrg],B.[UTEBOMComponent],B.[CompCode],
		D.[BOMMaster],B.[BOMComponent],@CurrLevel + 1
		from #BOMComponent A inner join MRP_BOMMapping_Temp B on A.[UTEBOMComponent] = B.[BOMComponent]
		inner join #BOMMaster D on A.[BOMComponent] = D.[BOMComponent]
		where B.[PlanVersion] = @PlanVersion and A.[Level] = @CurrLevel and A.[UTEBOMComponent] is not null;;
		
		set @CurrLevel = @CurrLevel + 1;

		select @Count = count(0) from #BOMComponent A where A.[Level] = @CurrLevel and A.[UTEBOMComponent] is not null;
	end
    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=34
    insert into [MRP_ProcessLog] values(@planversion,0,35,getdate(),'1900-1-1',0)  




	--下面为计算LLC逻辑：根据上面构造出的BOM母、子项临时表，计算LLC

	--建立临时表，存储所有展开出来的父项／子项料号
	create table #Itemllc
	(
		[Item]		      bigint,
		[Code]            nvarchar(255),
		[Org]             bigint,
		[IssueOrg]	      bigint,
		[llc]		      int
	)

	CREATE NONCLUSTERED INDEX [Itemllc_sylvia_987] ON #Itemllc 
	(
		[llc] ASC
	)

	--首先写入根节点母件
	--sylviahj 改为按itemcode匹配
	set @llc = 0;

	insert into #Itemllc([Item],[Code],[Org],[IssueOrg],[llc])
	select distinct A.[Item],A.[ItemCode],A.[Org],A.[Org],@llc
	from #BOMMaster A
	where 
		not exists(
					select top 1 0 
					from #BOMComponent B 
					where A.[ItemCode] = B.[ItemCode]
				  )
		--或者该母项存在为其他母项的子项，但是其他母项不在本次的运算范围内
		or not exists
				 (
					select top 1 0	
					from #BOMComponent C
						inner join #BOMMaster D on C.[BOMMaster] = D.[BOMMaster]
						inner join MRP_ExpandItemMapping_Temp E on E.[ItemCode] = D.[ItemCode]
																and E.[Org] = D.[Org]
																and E.[PlanVersion] = @PlanVersion
					where A.[ItemCode] = C.[ItemCode]
				 );

	--对根节点母件做bom的逐级展开并计算LLC，直至bom展开结束或展开的阶数超出@maxllc；

	create table #Itemllc_Temp
	(
		[Item]		      bigint,
		[Code]            nvarchar(255),
		[Org]             bigint,
		[IssueOrg]	      bigint,
		[llc]		      int
	)

	while((exists(select top 1 0 from #Itemllc where [llc]=@llc)) and (@llc<=@maxllc))
	begin			
		insert into #Itemllc_Temp([Item],[Code],[Org],[IssueOrg],[llc])
		select distinct C.[Item],C.[ItemCode],C.[Org],C.[IssueOrg],@llc+1
		from #Itemllc A inner join #BOMMaster B on A.[Code] = B.[ItemCode]
		inner join #BOMComponent C on B.[BOMMaster] = C.[BOMMaster]
		where A.[llc] = @llc;

		--增加多组织间的物料，即子件发料组织不等于母项的组织，此时要到发料组织中查找物料Code等于
		--子件物料Code的物料，并写入临时表;
		--sylviahj 07.07.20 改为查找只要组织不同，物料编码相同的物料
		--sylviahj 07.08.21 仍改为如果发料组织不等于母项组织，才进行插入（具体见低阶码计算的存储过程说明）
--		insert into #Itemllc([Item],[Code],[Org],[IssueOrg],[llc])
--		select distinct B.[Item],B.[ItemCode],B.[Org],B.[Org],@llc+1
--		from #Itemllc A inner join MRP_ExpandItemMapping_Temp B on A.[Code] = B.[ItemCode] and A.[Org] <> B.[Org]
--		where A.[llc] = @llc + 1 and B.[PlanVersion] = @PlanVersion;
		insert into #Itemllc_Temp([Item],[Code],[Org],[IssueOrg],[llc])
		select distinct B.[Item],B.[ItemCode],B.[Org],B.[Org],@llc+1
		from #Itemllc A inner join MRP_ExpandItemMapping_Temp B on B.[PlanVersion] = @PlanVersion and A.[Code] = B.[ItemCode] and A.[IssueOrg] = B.[Org]
		where A.[llc] = @llc + 1 and A.[Org] <> A.[IssueOrg];
		
		--解决备料料品低阶码比MO料品低时,备料需求追溯不到MO问题,重算低阶码时加入MO备料抓取逻辑  by qinhjc on 20170412
		--会出现BOM循环,暂时回退 by qinhjc on 20170715
		--insert into #Itemllc([Item],[Code],[Org],[IssueOrg],[llc])
		--select distinct C.[ID],C.[Code],B.[FactoryOrg],B.[FactoryOrg],@llc+1
		--from #Itemllc A 
		--inner join MRP_MOComponentMapping_Temp B on A.[Item] = B.[BomMasterItem]
		--left join CBO_ItemMaster C on C.[ID]=B.[ComponentItem]
		--where A.[llc] = @llc 
		--and (B.[BOMComponent] is null or not exists (select 0 from CBO_BOMComponent D where D.[ID]=B.[BOMComponent] and D.[ItemMaster]=B.[ComponentItem]));
		if (@IsSub <> 0)
		begin
			--替代关系中，标准件和替代件是对应的，一个料的LLC改变，另一个料的LLC也要改变
			insert into #Itemllc_Temp([Item],[Code],[Org],[IssueOrg],[llc])
			select distinct B.[Item],B.[ItemCode],B.[Org],B.[Org],@llc + 1
				from #Itemllc_Temp A 
				inner join #BOMComponentSubItem C on A.[Item]=C.Item
				inner join MRP_ExpandItemMapping_Temp B on B.[PlanVersion] = @PlanVersion and C.SubItem = B.Item
				where A.[llc] = @llc + 1
		
		end

		--当前低阶码加1
		select @llc = @llc + 1	

		insert into #Itemllc([Item],[Code],[Org],[IssueOrg],[llc])
		select distinct [Item],[Code],[Org],[IssueOrg],[llc] 
		from #Itemllc_Temp a
		where not exists(select top 1 0 from #Itemllc b where a.Item=b.Item and a.llc=b.llc)

		truncate table #Itemllc_Temp

	end

	drop table #Itemllc_Temp

	update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=35
    insert into [MRP_ProcessLog] values(@planversion,0,36,getdate(),'1900-1-1',0)  

	--如果临时表中存在大于@maxllc的记录，说明出现了bom死循环或bom的层次大于最大低阶码
	if(exists(select 0 from #Itemllc where [llc] > @maxllc))
	begin
		
		--BOM循环信息输出
		if object_id(N'[MRP_ExceedItemLLC]', N'u') is not null
		begin
			truncate table MRP_ExceedItemLLC;
			drop table MRP_ExceedItemLLC;
		end

		select * into MRP_ExceedItemLLC
		from #Itemllc
		where  [llc] > -20;--暂时只输出20阶以上的记录
		
		truncate table #Itemllc
		drop table #Itemllc
		truncate table #BOMMaster
		drop table #BOMMaster
		truncate table #BOMComponent
		drop table #BOMComponent

		select -1;
	end
	
	else if(@IsReCalcLLC = 1)
	--更新物料展开映像档的低阶码
	begin
--		set transaction isolation level REPEATABLE read
--		begin transaction;
		with MaxLLC([ItemCode],[LLC]) as
		(
			select [Code],max([llc]) llc from #Itemllc group by [Code]
		)
		update B set B.[LowLevelCode] = A.[LLC]
		from MaxLLC A inner join MRP_ExpandItemMapping_Temp B on  A.[ItemCode] = B.[ItemCode] 
		where B.[PlanVersion] = @PlanVersion;
--		if (@@error <> 0)
--			rollback;
--		else
--			commit;
	end


    update [MRP_ProcessLog] set [EndTime]=getdate(),[UsedSecond]= DATEDIFF(second,@LastDate,getdate())
    where planversion=@planversion and [LogType]=0 and [Number]=36
    insert into [MRP_ProcessLog] values(@planversion,0,37,getdate(),'1900-1-1',0)  

	truncate table #Itemllc
	drop table #Itemllc
	truncate table #BOMMaster
	drop table #BOMMaster
	truncate table #BOMComponent
	drop table #BOMComponent
	truncate table #BOMComponentSubItem
	drop table #BOMComponentSubItem

	if (@llc = 0)
		select 0
	else
		select (@llc - 1);
END

