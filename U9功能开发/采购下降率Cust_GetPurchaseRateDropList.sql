USE [AuctusERP]
GO
/****** Object:  StoredProcedure [dbo].[Cust_GetPurchaseRateDropList]    Script Date: 2023/1/6 10:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--  1、查询指定区间（当期）收货单(样品收货除外、赠品收货除外、作废单据除外、来料拒收除外、内部往来收货除外)实收的物料；
--  2、当期物料单价的计算等于总金额除以数量再按指定的区间加权平均；
--  3、如果对应收货的物料有替代料（收货物料作为主料，按BOM替代关系取BOM中的所有替代料），替代料的价格取指定供应商“9.0.001 "价表的有效未税价格；
--  4、上期价格等于主料及替代料价格的加权平均价（主料价格取指定供应商“9.0.001 "价表的有效未税价格；）；
--  5、单价差异等于当期未税价格减去上期未税价格；
--  注：供应商“9.0.001 "价表由陈晴虹统一维护。

ALTER   procedure [dbo].[Cust_GetPurchaseRateDropList] 
as
BEGIN
	DECLARE @Day INT=DATEPART(DAY,GETDATE())
	--每月1号备份数据
	IF @Day!=1
	BEGIN
		RETURN;
	END 
	declare @Organization bigint
	declare @ItemID  bigint
	declare @ItemCode  varchar(80)
	declare @ItemName varchar(300)
	declare @SPECS   varchar(500)
	declare @ItemCategory varchar(50)
	declare @PriceUOM  varchar(10)
	declare @RcvQtyPU   Decimal(18,4)
	declare @MnyTCPrice Decimal(18,4)
	declare @NetMnyTCPrice  Decimal(18,4)
	declare @FinallyPriceTC   Decimal(18,4)
	declare @TotalMnyTC Decimal(18,4)
	declare @TotalNetMnyTC Decimal(18,4)
	declare @LastYearNetMnyAVGPric Decimal(18,4)
	declare @LastYearMnyAVGPric  Decimal(18,4)
	declare @LastYearNetMnyDiffPric Decimal(18,4)
	declare @LastYearNetMnyDiffTotal Decimal(18,4)

	declare @RepMnyTCPrice Decimal(18,4)
	declare @RepNetMnyTCPrice  Decimal(18,4)

	set @RepMnyTCPrice=0;
	set @RepNetMnyTCPrice=0;

    if object_id('tempdb.dbo.#Cust_TabTmp1') is not  null
	   drop  table #Cust_TabTmp1
     ---- 需优化
	 select a2.Org,a1.ItemInfo_ItemID,a1.ItemInfo_ItemCode,ItemInfo_ItemName
	,(select SPECS  from  CBO_ItemMaster  where id=a1.ItemInfo_ItemID) SPECS 
	,(select c1.Name from  CBO_Category_trl   c1 inner join  cbo_itemMaster c2 on c1.id = c2.MainItemCategory where c2.id=a1.ItemInfo_ItemID ) ItemCategory
	,(select  Name from   Base_UOM_trl where  id=PriceUOM) PriceUOM 
	,(case when a2.ReceivementType=0 then RcvQtyPU else -RcvQtyPU end) RcvQtyPU
	,a2.TC
	,dbo.Cust_fn_GetCurrencyByID(a2.TC,1) CurrencyName 
	,ACToFCExchRate
	,a1.TaxRate
	,a1.IsPriceIncludeTax
	,a1.FinallyPriceTC*a1.ACToFCExchRate*a1.TCToACExchRate FinallyPriceTC
	,a1.TotalMnyTC*a1.ACToFCExchRate*a1.TCToACExchRate  TotalMnyTC--价税合计
	,a1.TotalNetMnyTC*a1.ACToFCExchRate*a1.TCToACExchRate TotalNetMnyTC ---未税金额
    into   #Cust_TabTmp1
	from   PM_RcvLine a1
	inner  join  PM_Receivement a2 on a2.id=a1.Receivement  
	where a1.IsPresent !=1  and a1.Status !=0 and a1.Cancel_Canceled=0  and a2.ReceivementType <=1 and RcvQtyPU >0
	and  a1.RcvQtyPU >0
	--含委外
	--and not  exists (select 1 from  CBO_ItemMaster item  where  id=a1.ItemInfo_ItemID and    ItemFormAttribute =10 )
	and  not exists (select t.id from PM_RcvDocType t　　
	　　　　　　　　　　　inner join   PM_RcvDocType_trl t2 on t.id=t2.id 
					　　　where t.Org=a2.Org   and a2.RcvDocType=t.id and  t2.Name like N'%内部%')
	and  not  exists(select 1 from CBO_Supplier  where  DescFlexField_PrivateDescSeg3 =N'NEI01' and ID=a2.Supplier_Supplier)
	and  not  exists(select 1 from  PM_PurchaseOrder  where id=a1.SrcDoc_SrcDoc_EntityID and IsReDo=1)  ---返工订单
	and  (DATEDIFF(day,dateadd(month,datediff(month,0,  dateadd(month,-1,getdate())),0),a1.ConfirmDate) >= 0 
	and DATEDIFF(day,dateadd(month,datediff(month,-1, dateadd(month,-1,getdate())), -1),a1.ConfirmDate) <= 0 )  

 
	if object_id('tempdb.dbo.#Cust_TabTmp2') is not  null
	 drop  table #Cust_TabTmp2

	 create table  #Cust_TabTmp2(
		Org bigint,
		ItemInfo_ItemID  bigint,
		ItemInfo_ItemCode  varchar(80),
		ItemInfo_ItemName varchar(300),
		SPECS   varchar(500),
		ItemCategory varchar(50),
		PriceUOM  varchar(10),
		RcvQtyPU   Decimal(24,9),
		MnyTCPrice Decimal(24,9),
		NetMnyTCPrice  Decimal(24,9),
		FinallyPriceTC   Decimal(24,9),
		TotalMnyTC Decimal(24,9),
		TotalNetMnyTC Decimal(24,9),
		LastYearNetMnyAVGPric Decimal(24,9),
		LastYearMnyAVGPric  Decimal(24,9),
		LastYearNetMnyDiffPric Decimal(24,9),
		LastYearNetMnyDiffTotal Decimal(24,9)
	 )

	insert into #Cust_TabTmp2 select Org,ItemInfo_ItemID,ItemInfo_ItemCode,ItemInfo_ItemName,SPECS,ItemCategory,PriceUOM,sum(RcvQtyPU) RcvQtyPU 
	,avg(TotalMnyTC/isnull(NULLIF(RcvQtyPU,0),1))  MnyTCPrice
	,avg(TotalNetMnyTC/isnull(NULLIF(RcvQtyPU,0),1))  NetMnyTCPrice
	,avg(FinallyPriceTC) FinallyPriceTC
	,sum(TotalMnyTC) TotalMnyTC
	,sum(TotalNetMnyTC)  TotalNetMnyTC
	,0 LastYearNetMnyAVGPric
	,0 LastYearMnyAVGPric
	,0 LastYearNetMnyDiffPric
	,0 LastYearNetMnyDiffTotal  from #Cust_TabTmp1
	group by Org,ItemInfo_ItemID,ItemInfo_ItemCode,ItemInfo_ItemName,SPECS,ItemCategory,PriceUOM
 

	---更新上年期末价格 取价表
	update  a1 set  
	 LastYearNetMnyAVGPric=isnull(Price,0)
	,LastYearMnyAVGPric=isnull(Price,0)
	from  #Cust_TabTmp2  a1
	left join  PPR_PurPriceLine a2 on a1.ItemInfo_ItemID=a2.ItemInfo_ItemID 
	inner join PPR_PurPriceList a3 on a2.PurPriceList=a3.id  and a1.Org=a3.Org 
	where  exists (select 1 from CBO_Supplier where id=a3.Supplier and Code=N'9.0.001') 
	and a3.Status=2 and a3.Cancel_Canceled=0  
	and a2.Active=1  and  datediff(day,a2.ToDate,'2125-01-01') < 0

	--游标有问题待优化
	declare Cust_RcvItemListCursor cursor
	for  select a1.Org,a1.ItemInfo_ItemID,a1.ItemInfo_ItemCode,a1.ItemInfo_ItemName,a1.SPECS,a1.ItemCategory,a1.PriceUOM,a1.RcvQtyPU,a1.MnyTCPrice
				,a1.NetMnyTCPrice,a1.FinallyPriceTC,a1.TotalMnyTC,a1.TotalNetMnyTC,LastYearNetMnyAVGPric,LastYearMnyAVGPric,LastYearNetMnyDiffPric,LastYearNetMnyDiffTotal 
		  from #Cust_TabTmp2 a1
	open Cust_RcvItemListCursor;

	fetch next from Cust_RcvItemListCursor 
	into   @Organization,@ItemID,@ItemCode,@ItemName,@SPECS,@ItemCategory,@PriceUOM,@RcvQtyPU,@MnyTCPrice,@NetMnyTCPrice,@FinallyPriceTC,@TotalMnyTC,@TotalNetMnyTC
		  ,@LastYearNetMnyAVGPric,@LastYearMnyAVGPric,@LastYearNetMnyDiffPric,@LastYearNetMnyDiffTotal 
	while(@@fetch_status = 0)
	begin
	   with Component as
		(select a1.id,a1.ItemMaster,a2.BOMVersion,a2.BOMVersionCode 
		from   CBO_BOMComponent  a1
		inner  join  CBO_BOMMaster a2 on  a1.BOMMaster =a2.id
	    ---inner  join  CBO_ItemMaster a3 on a1.ItemMaster=a3.ID  and a3.Effective_IsEffective=1
		where    a2.Org=@Organization    and   a1.ItemMaster=@ItemID) --- a3.Code='313030055'  

    select @RepMnyTCPrice=avg(isnull(Price,0)),@RepNetMnyTCPrice=avg(isnull(Price,0))
		from   PPR_PurPriceLine a2   
		inner  join PPR_PurPriceList a3 on a2.PurPriceList=a3.id   
		inner  join  CBO_ItemMaster a4 on a2.ItemInfo_ItemID=a4.ID   
		where  exists (select 1 from CBO_Supplier where id=a3.Supplier and Code=N'9.0.001') 
				and a3.Status=2 and a3.Cancel_Canceled=0  
				and a2.Active=1  
				and a4.Effective_IsEffective=1
				--and Org=a3.org  
				and  datediff(day,a2.ToDate,'2125-01-01') < 0  --取最新价格
				and exists (select 1  from  CBO_BOMComponent com2 
										where  com2.SubstitutedComp  
										in  (select id from Component where com2.ItemMaster=a2.ItemInfo_ItemID) )
      if(@RepMnyTCPrice > 0)
	   begin
	   if(isnull(@LastYearMnyAVGPric,0) > 0)
		set @LastYearMnyAVGPric =(@LastYearMnyAVGPric+@RepMnyTCPrice)/2 
		else  
		set @LastYearMnyAVGPric =@RepMnyTCPrice
		
		if(isnull(@LastYearNetMnyAVGPric,0) > 0)
		set @LastYearNetMnyAVGPric=(@LastYearNetMnyAVGPric+@RepNetMnyTCPrice)/2 
		else  
		set  @LastYearNetMnyAVGPric=@RepNetMnyTCPrice
	end

	set @LastYearNetMnyDiffPric=isnull(@NetMnyTCPrice,0)-isnull(@LastYearNetMnyAVGPric,0);
	set @LastYearNetMnyDiffTotal=@LastYearNetMnyDiffPric*@RcvQtyPU

	 insert into  Auctus_PurchaseRateDropTabList(Organization,ItemID,ItemCode,ItemName,SPECS,ItemCategory,PriceUOM,RcvQtyPU,MnyTCPrice,NetMnyTCPrice,FinallyPriceTC,TotalMnyTC,TotalNetMnyTC,
		          LastYearNetMnyAVGPric,LastYearMnyAVGPric,LastYearNetMnyDiffPric,LastYearNetMnyDiffTotal,StartDate,EndDate)  
		values(@Organization,@ItemID,@ItemCode,@ItemName,@SPECS,@ItemCategory,@PriceUOM,@RcvQtyPU,@MnyTCPrice,@NetMnyTCPrice,@FinallyPriceTC,@TotalMnyTC,@TotalNetMnyTC
		,@LastYearNetMnyAVGPric,@LastYearMnyAVGPric,@LastYearNetMnyDiffPric,@LastYearNetMnyDiffTotal,dateadd(month,datediff(month,0,  dateadd(month,-1,getdate())),0),dateadd(month,datediff(month,-1, dateadd(month,-1,getdate())), -1))

		fetch next from Cust_RcvItemListCursor 
		into  @Organization,@ItemID,@ItemCode,@ItemName,@SPECS,@ItemCategory,@PriceUOM,@RcvQtyPU,@MnyTCPrice,@NetMnyTCPrice,@FinallyPriceTC,@TotalMnyTC,@TotalNetMnyTC
			 ,@LastYearNetMnyAVGPric,@LastYearMnyAVGPric,@LastYearNetMnyDiffPric,@LastYearNetMnyDiffTotal 
		end   

		close Cust_RcvItemListCursor
		deallocate Cust_RcvItemListCursor	

	 if object_id('tempdb.dbo.#Cust_TabTmp1') is not  null
	 drop  table #Cust_TabTmp1

	 if object_id('tempdb.dbo.#Cust_TabTmp2') is not  null
	 drop  table #Cust_TabTmp2

end
 
 
