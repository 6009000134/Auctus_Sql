select AA.[存储地点_编码] as [存储地点_编码],AA.存储地点_名称 as [存储地点_名称],AA.主分类_编码 as [主分类_编码],AA.主分类_名称 as [主分类_名称],AA.料品_料号 as [料品_料号],AA.料品_品名 as [料品_品名],AA.料品_规格 as [料品_规格],AA.库存单位_名称 as [库存单位_名称],AA.库存单位_编码 as [库存单位_编码],sum(AA.实到数量) as [到货数量],sum(AA.成品入库数量) as [成品入库数量],sum(AA.完工申报待入库数量) as [完工申报待入库数量],sum(AA.生产退料数量) as [生产退料数量],sum(AA.杂收数量) as [杂收数量],sum(AA.生产领料数量) as [生产领料数量],sum(AA.杂发数量) as [杂发数量],sum(AA.[标准出货数量]) as [标准出货数量],sum(AA.[采购退货数量]) as [采购退货数量],sum(AA.[调出单在途数量]) as [调出单在途数量],sum(AA.[现存量_库存数量]) as [现存量_库存数量],sum(AA.[销售退回待入库数量]) as [销售退回待入库数量],(sum(AA.[现存量_库存数量])+sum(AA.实到数量)+sum(AA.成品入库数量)+sum(AA.完工申报待入库数量)+sum(AA.生产退料数量)+sum(AA.杂收数量)+sum(AA.[销售退回待入库数量])-sum(AA.生产领料数量)-sum(AA.杂发数量)-sum(AA.[标准出货数量])-sum(AA.[采购退货数量])-sum(AA.[调出单在途数量])) as [库存可用量],AA.[组织_编码] AS [组织_编码],AA.[组织_名称] AS [组织_名称] from (
--标准收货待入库数量
select  A2.[Code] as [存储地点_编码], A3.[Name] as [存储地点_名称], A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称], A4.[Code] as [料品_料号], A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格], A8.[Name] as [库存单位_名称], A7.[Code] as [库存单位_编码],sum(A1.[ArriveQtySU]) as [实到数量], 0 as [成品入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量],0 as [采购退货数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A13.[Code] as [组织_编码], A14.[Name] as [组织_名称]
from  PM_Receivement as A  
inner join [PM_RcvLine] as A1 on (A.[ID] = A1.[Receivement])  
left join [CBO_Wh] as A2 on (A1.[Wh] = A2.[ID])  
left join [CBO_Wh_Trl] as A3 on (A3.SysMlFlag = 'zh-CN') and (A2.[ID] = A3.[ID])  left join [CBO_ItemMaster] as A4 on (A1.[ItemInfo_ItemID] = A4.[ID])  
left join [CBO_Category] as A5 on (A4.[MainItemCategory] = A5.[ID])  
left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  
left join [Base_UOM] as A7 on (A1.[StoreUOM] = A7.[ID])  
left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID]) 
left join [Base_Organization] as A13 on (A1.[CurrentOrg] = A13.[ID])  
left join [Base_Organization_Trl] as A14 on (A14.SysMlFlag = 'zh-CN') and (A13.[ID] = A14.[ID])
left join [PM_RcvDocType] as A15 on (A.[RcvDocType] = A15.[ID])
 where A.[Status] !=5 and A2.[Code] !='' and A1.[ArriveQtySU] > 0 and (A15.[Code] ='001' or A15.[Code] ='002'or A15.[Code] ='003'or A15.[Code] ='004'or A15.[Code] ='006'or A15.[Code] ='010'or A15.[Code] ='999'  )
 group by A4.[Code],A2.[Code], A3.[Name], A5.[Code], A6.[Name], A4.[Name], A4.[SPECS], A8.[Name], A7.[Code],A13.[Code],A14.[Name]

union all 

--成品入库待入库数量
select A3.[Code] as [存储地点_编码], A4.[Name] as [存储地点_名称],A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称],A2.[Code] as [料品_料号], A2.[Name] as [料品_品名], A2.[SPECS] as [料品_规格], A8.[Name] as [库存单位_名称],A7.[Code] as [库存单位_编码],0 as [标准收货],sum(A.[RcvQtyByWhUOM]) as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量],0 as [采购退货数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A13.[Code] as [组织_编码], A14.[Name] as [组织_名称]
from  Complete_RcvRptDocLine as A  
left join [Complete_RcvRptDoc] as A1 on (A.[RcvRptDoc] = A1.[ID])  
left join [CBO_ItemMaster] as A2 on (A.[Item] = A2.[ID])  
left join [CBO_Wh] as A3 on (A.[Wh] = A3.[ID])  
left join [CBO_Wh_Trl] as A4 on (A4.SysMlFlag = 'zh-CN') and (A3.[ID] = A4.[ID])  left join [CBO_Category] as A5 on (A2.[MainItemCategory] = A5.[ID])  
left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  
left join [Base_UOM] as A7 on (A.[StoreUOM] = A7.[ID])  
left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID])
left join [Base_Organization] as A13 on (A1.[Org] = A13.[ID])  
left join [Base_Organization_Trl] as A14 on (A14.SysMlFlag = 'zh-CN') and (A13.[ID] = A14.[ID])
 where A1.[DocState] !=2  and A.[RcvQtyByWhUOM] > 0 and A3.[Code] !=''  group by A2.[Code], A3.[Code], A4.[Name], A5.[Code], A6.[Name], A2.[Name], A2.[SPECS], A8.[Name],A7.[Code],A13.[Code],A14.[Name]


union all 

--完工申报-所有成品入库
 select * from (select   A3.[Code] as [完工存储地点_编码],A4.[Name] as [完工存储地点_名称],A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称],A2.[Code] as [料品_料号],A2.[Name] as [料品_品名], A2.[SPECS] as [料品_规格],A8.[Name] as [库存单位_名称],A7.[Code] as [库存单位_编码],0 as [标准收货],0 as [成品入库_入库数量],
sum(A.[EligibleQty])-(case when (select sum(case when A00.[RcvQtyByWhUOM]>0 then A00.[RcvQtyByWhUOM] else 0 end) as [入库数量]  
from  Complete_RcvRptDocLine as A00  
left join [CBO_ItemMaster] as A02 on (A00.[Item] = A02.[ID])  
left join [CBO_Wh] as A03 on (A00.[Wh] = A03.[ID])  
 where A03.[Code] =A3.[Code] and A02.[Code]=A2.[Code])>0 then (select sum(case when A00.[RcvQtyByWhUOM]>0 then A00.[RcvQtyByWhUOM] else 0 end) as [入库数量] 
from  Complete_RcvRptDocLine as A00  
left join [CBO_ItemMaster] as A02 on (A00.[Item] = A02.[ID])  
left join [CBO_Wh] as A03 on (A00.[Wh] = A03.[ID])  
 where A03.[Code] =A3.[Code] and A02.[Code]=A2.[Code])else 0 end ) as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量],0 as [采购退货数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A13.[Code] as [组织_编码], A14.[Name] as [组织_名称] 
from  Complete_CompleteApplyDocLine as A  
inner join [Complete_CompleteApplyDoc] as A1 on (A.[CompleteApplyDoc] = A1.[ID])  inner join [CBO_ItemMaster] as A2 on (A.[Item] = A2.[ID])  
left join [CBO_Wh] as A3 on (A.[CompleteWh] = A3.[ID])  
left join [CBO_Wh_Trl] as A4 on (A4.SysMlFlag = 'zh-CN') and (A3.[ID] = A4.[ID])  left join [CBO_Category] as A5 on (A2.[MainItemCategory] = A5.[ID])  
left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  
left join [Base_UOM] as A7 on (A2.[InventorySecondUOM] = A7.[ID])  
left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID])
left join [Base_Organization] as A13 on (A1.[Org] = A13.[ID])  
left join [Base_Organization_Trl] as A14 on (A14.SysMlFlag = 'zh-CN') and (A13.[ID] = A14.[ID])
where A3.[Code] !='' and A.[EligibleQty] > 0 
group by A4.[Name],A3.[Code],A5.[Code], A6.[Name],A2.[Code],A2.[Name], A2.[SPECS],A8.[Name],A7.[Code],A13.[Code],A14.[Name]) AA where AA.[完工申报待入库数量] > 0

 union all 
 
 --生产退料单-待入库数量
 select  A5.[Code] as [存储地点_编码], A6.[Name] as [存储地点_名称], A10.[Code] as [主分类_编码], A11.[Name] as [主分类_名称], A4.[Code] as [料品_料号], A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格],  A13.[Name] as [库存单位_名称],A12.[Code] as [库存单位_编码], 0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量],sum(A.[IssuedQty]) as [领料单明细_实发数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量],0 as [采购退货数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A14.[Code] as [组织_编码], A15.[Name] as [组织_名称]
 from  MO_IssueDocLine as A  
 inner join [MO_IssueDoc] as A1 on (A.[IssueDoc] = A1.[ID])  
 left join [MO_IssueDocType] as A2 on (A1.[IssueDocType] = A2.[ID])  
 inner join [CBO_ItemMaster] as A4 on (A.[Item] = A4.[ID])  
 left join [CBO_Wh] as A5 on (A.[Wh] = A5.[ID])  
 left join [CBO_Wh_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])   
 left join [CBO_Category] as A10 on (A4.[MainItemCategory] = A10.[ID])  
 left join [CBO_Category_Trl] as A11 on (A11.SysMlFlag = 'zh-CN') and (A10.[ID] = A11.[ID])
 left join [Base_UOM] as A12 on (A.[WhUOM] = A12.[ID])  
 left join [Base_UOM_Trl] as A13 on (A13.SysMlFlag = 'zh-CN') and (A12.[ID] = A13.[ID]) 
 left join [Base_Organization] as A14 on (A1.[Org] = A14.[ID])  
left join [Base_Organization_Trl] as A15 on (A15.SysMlFlag = 'zh-CN') and (A14.[ID] = A15.[ID])
 where  A2.[Code] ='035' and A1.[DocState] !=2   group by A4.[Code],A5.[Code], A6.[Name], A10.[Code], A11.[Name], A4.[Name], A4.[SPECS], A12.[Code], A13.[Name],A14.[Code], A15.[Name]
 
 union all 
 
 --杂收-待入库数量
 select  A2.[Code] as [存储地点_编码], A3.[Name] as [存储地点_名称], A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称], A4.[Code] as [料品_料号], A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格],  A8.[Name] as [库存单位_名称],A7.[Code] as [库存单位_编码], 0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],sum(A1.[StoreUOMQty]) as [杂收单行_库存数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量],0 as [采购退货数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A13.[Code] as [组织_编码], A14.[Name] as [组织_名称] 
 from  InvDoc_MiscRcvTrans as A  
 left join [InvDoc_MiscRcvTransL] as A1 on (A.[ID] = A1.[MiscRcvTrans])  
 left join [CBO_Wh] as A2 on (A1.[Wh] = A2.[ID])  
 left join [CBO_Wh_Trl] as A3 on (A3.SysMlFlag = 'zh-CN') and (A2.[ID] = A3.[ID])  left join [CBO_ItemMaster] as A4 on (A1.[ItemInfo_ItemID] = A4.[ID])  
 left join [CBO_Category] as A5 on (A4.[MainItemCategory] = A5.[ID])  
 left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  
 left join [Base_UOM] as A7 on (A1.[StoreUOM] = A7.[ID])  
 left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID])
 left join [Base_Organization] as A13 on (A1.[Org] = A13.[ID])  
left join [Base_Organization_Trl] as A14 on (A14.SysMlFlag = 'zh-CN') and (A13.[ID] = A14.[ID]) where A.[Status] !=2 and A1.[StoreUOMQty] > 0 group by  A4.[Code],A2.[Code], A3.[Name], A5.[Code], A6.[Name], A4.[Name], A4.[SPECS], A7.[Code], A8.[Name],A13.[Code], A14.[Name]
 
 union all 
 --调拨单
 
 --待领料数量状态非关闭状态
 select  A5.[Code] as [存储地点_编码],A6.[Name] as [存储地点_名称],A10.[Code] as [主分类_编码], A11.[Name] as [主分类_名称],A4.[Code] as [料品_料号],A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格], A13.[Name] as [库存单位_名称],A12.[Code] as [库存单位_编码],0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],sum(A.[IssueQty]) as [领料单明细_应发数量],0 as [杂发数量], 0 as [标准出货数量],0 as [采购退货数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A14.[Code] as [组织_编码], A15.[Name] as [组织_名称] 
 from  MO_IssueDocLine as A  inner join [MO_IssueDoc] as A1 on (A.[IssueDoc] = A1.[ID])  left join [MO_IssueDocType] as A2 on (A1.[IssueDocType] = A2.[ID])  left join [MO_IssueDocType_Trl] as A3 on (A3.SysMlFlag = 'zh-CN') and (A2.[ID] = A3.[ID])  inner join [CBO_ItemMaster] as A4 on (A.[Item] = A4.[ID])  left join [CBO_Wh] as A5 on (A.[Wh] = A5.[ID])  left join [CBO_Wh_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  left join [Base_Organization] as A7 on (A1.[Org] = A7.[ID])  left join [Base_Organization_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID])  left join [Lot_LotMaster] as A9 on (A.[LotMaster] = A9.[ID])  left join [CBO_Category] as A10 on (A4.[MainItemCategory] = A10.[ID])  left join [CBO_Category_Trl] as A11 on (A11.SysMlFlag = 'zh-CN') and (A10.[ID] = A11.[ID])  left join [Base_UOM] as A12 on (A.[WhUOM] = A12.[ID])  left join [Base_UOM_Trl] as A13 on (A13.SysMlFlag = 'zh-CN') and (A12.[ID] = A13.[ID]) left join [Base_Organization] as A14 on (A1.[Org] = A14.[ID])  
left join [Base_Organization_Trl] as A15 on (A15.SysMlFlag = 'zh-CN') and (A14.[ID] = A15.[ID])
 where A2.[Code] !='037' and A2.[Code] !='035' and A2.[Code] !='003' and A2.[Code] !='007' and A1.[DocState]!='2' group by A5.[Code],A4.[Code],A10.[Code],A6.[Name],A11.[Name],A4.[Name],A4.[SPECS],A12.[Code],A13.[Name],A14.[Code], A15.[Name]
 
 --杂发待发料数量	状态为非核准(2)
 union all 
 select  A2.[Code] as [存储地点_编码], A3.[Name] as [存储地点_名称], A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称], A4.[Code] as [料品_料号], A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格],  A8.[Name] as [库存单位_名称],A7.[Code] as [库存单位_编码],0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量], sum(A1.[StoreUOMQty]) as [杂收单行_库存数量], 0 as [标准出货数量],0 as [采购退货数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A14.[Code] as [组织_编码], A15.[Name] as [组织_名称] from  InvDoc_MiscRcvTrans as A  left join [InvDoc_MiscRcvTransL] as A1 on (A.[ID] = A1.[MiscRcvTrans])  left join [CBO_Wh] as A2 on (A1.[Wh] = A2.[ID])  left join [CBO_Wh_Trl] as A3 on (A3.SysMlFlag = 'zh-CN') and (A2.[ID] = A3.[ID])  left join [CBO_ItemMaster] as A4 on (A1.[ItemInfo_ItemID] = A4.[ID])  left join [CBO_Category] as A5 on (A4.[MainItemCategory] = A5.[ID])  left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  left join [Base_UOM] as A7 on (A1.[StoreUOM] = A7.[ID])  left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID])
 left join [Base_Organization] as A14 on (A1.[Org] = A14.[ID])  
left join [Base_Organization_Trl] as A15 on (A15.SysMlFlag = 'zh-CN') and (A14.[ID] = A15.[ID]) where A.[Status]!='2'  group by A2.[Code], A3.[Name], A5.[Code], A6.[Name], A4.[Code], A4.[Name], A4.[SPECS], A7.[Code], A8.[Name],A14.[Code], A15.[Name]
 
 union all 
 
 --待出货数量 状态为非已核准()
select  A2.[Code] as [存储地点_编码], A3.[Name] as [存储地点_名称], A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称], A4.[Code] as [料品_料号], A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格],  A8.[Name] as [库存单位_名称],A7.[Code] as [库存单位_编码],0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], sum(A1.[ShipQtyInvAmount]) as [出货行_出货数量],0 as [采购退货数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A14.[Code] as [组织_编码], A15.[Name] as [组织_名称] from  SM_Ship as A  inner join [SM_ShipLine] as A1 on (A.[ID] = A1.[Ship])  left join [CBO_Wh] as A2 on (A1.[WH] = A2.[ID])  left join [CBO_Wh_Trl] as A3 on (A3.SysMlFlag = 'zh-CN') and (A2.[ID] = A3.[ID])  left join [CBO_ItemMaster] as A4 on (A1.[ItemInfo_ItemID] = A4.[ID])  left join [CBO_Category] as A5 on (A4.[MainItemCategory] = A5.[ID])  left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  left join [Base_UOM] as A7 on (A1.[InvUom] = A7.[ID])  left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID]) left join [Base_Organization] as A14 on (A1.[Org] = A14.[ID])  
left join [Base_Organization_Trl] as A15 on (A15.SysMlFlag = 'zh-CN') and (A14.[ID] = A15.[ID])
 where A.[Status] !='3' group by A2.[Code], A3.[Name], A5.[Code], A6.[Name], A4.[Code], A4.[Name], A4.[SPECS], A7.[Code], A8.[Name],A14.[Code], A15.[Name]

union all 

--采购退货单 待入库
select  A2.[Code] as [存储地点_编码], A3.[Name] as [存储地点_名称],A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称],A4.[Code] as [料品_料号], A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格],A8.[Name] as [库存单位_名称],A7.[Code] as [库存单位_编码],0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量], sum(A1.[ArriveQtySU]) as [收货行信息_实到数量],0 as [调出单在途数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A13.[Code] as [组织_编码], A14.[Name] as [组织_名称] from  PM_Receivement as A  inner join [PM_RcvLine] as A1 on (A.[ID] = A1.[Receivement])  left join [CBO_Wh] as A2 on (A1.[Wh] = A2.[ID])  left join [CBO_Wh_Trl] as A3 on (A3.SysMlFlag = 'zh-CN') and (A2.[ID] = A3.[ID])  left join [CBO_ItemMaster] as A4 on (A1.[ItemInfo_ItemID] = A4.[ID])  left join [CBO_Category] as A5 on (A4.[MainItemCategory] = A5.[ID])  left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  left join [Base_UOM] as A7 on (A1.[StoreUOM] = A7.[ID])  left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID])  left join [PM_Receivement_Trl] as A9 on (A9.SysMlFlag = 'zh-CN') and (A.[ID] = A9.[ID])  left join [Lot_LotMaster] as A10 on (A1.[InvLot] = A10.[ID])
left join [PM_RcvDocType] as A15 on (A.[RcvDocType] = A15.[ID]) 
left join [Base_Organization] as A13 on (A.[Org] = A13.[ID])  
left join [Base_Organization_Trl] as A14 on (A14.SysMlFlag = 'zh-CN') and (A13.[ID] = A14.[ID])
 where A.[Status] !='5' and (A15.[Code] ='008' or A15.[Code] ='009'or A15.[Code] ='011'or A15.[Code] ='888' ) group by A2.[Code], A3.[Name],A5.[Code], A6.[Name],A4.[Code], A4.[Name], A4.[SPECS],A7.[Code],A8.[Name],A13.[Code], A14.[Name]

union all 

--调出单非关闭
select  A2.[Code] as [存储地点_编码], A3.[Name] as [存储地点_名称], A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称], A4.[Code] as [料品_料号], A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格], A8.[Name] as [调出库存单位_名称],A7.[Code] as [调出库存单位_编码], 0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量],0 as [采购退货数量], sum(A1.[StoreUOMQty]) as [调出单行_调出数量],0 as [现存量_库存数量],0 as [销售退回待入库数量],A14.[Code] as [组织_编码], A15.[Name] as [组织_名称] from  InvDoc_TransferOut as A  inner join [InvDoc_TransOutLine] as A1 on (A.[ID] = A1.[TransferOut])  left join [CBO_Wh] as A2 on (A1.[TransOutWh] = A2.[ID])  left join [CBO_Wh_Trl] as A3 on (A3.SysMlFlag = 'zh-CN') and (A2.[ID] = A3.[ID])  left join [CBO_ItemMaster] as A4 on (A1.[ItemInfo_ItemID] = A4.[ID])  left join [CBO_Category] as A5 on (A4.[MainItemCategory] = A5.[ID])  left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  left join [Base_UOM] as A7 on (A1.[StoreUOM] = A7.[ID])  left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID]) left join [Base_Organization] as A14 on (A1.[Org] = A14.[ID])  
left join [Base_Organization_Trl] as A15 on (A15.SysMlFlag = 'zh-CN') and (A14.[ID] = A15.[ID]) where A.[Status]!='2' group by A2.[Code], A3.[Name], A5.[Code], A6.[Name], A4.[Code], A4.[Name], A4.[SPECS], A7.[Code],A8.[Name],A14.[Code], A15.[Name]

union all
--现存量
select  A9.[Code] as [存储地点_编码], A10.[Name] as [存储地点_名称], A11.[Code] as [主分类_编码], A12.[Name] as [主分类_名称],A.[ItemInfo_ItemCode] as [料品_料号],A.[ItemInfo_ItemName] as [料品_品名], A8.[SPECS] as [料品_规格], A7.[Name] as [库存单位_名称], A6.Code as [库存单位_编码], 0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量],0 as [采购退货数量],0 as [调出单在途数量], SUM(case when A.[Direction] =0 then A.[StoreUOMQty] when A.[Direction] =1 then (-1*A.[StoreUOMQty]) end) as [现存量_库存数量],0 as [销售退回待入库数量],A14.[Code] as [组织_编码], A15.[Name] as [组织_名称]
from  InvTrans_TransLine as A    
left join [Base_UOM] as A6 on (A.[StoreUOM] = A6.[ID])  
left join [Base_UOM_Trl] as A7 on (A7.SysMlFlag = 'zh-CN') and (A6.[ID] = A7.[ID])  left join [CBO_ItemMaster] as A8 on (A.[ItemInfo_ItemID] = A8.[ID])  
left join [CBO_Wh] as A9 on (A.[Wh] = A9.[ID])  
left join [CBO_Wh_Trl] as A10 on (A10.SysMlFlag = 'zh-CN') and (A9.[ID] = A10.[ID])  left join [CBO_Category] as A11 on (A8.[MainItemCategory] = A11.[ID])  
left join [CBO_Category_Trl] as A12 on (A12.SysMlFlag = 'zh-CN') and (A11.[ID] = A12.[ID])
left join [Base_Organization] as A14 on (A.[Org] = A14.[ID])  
left join [Base_Organization_Trl] as A15 on (A15.SysMlFlag = 'zh-CN') and (A14.[ID] = A15.[ID])
  group by A9.[Code], A10.[Name], A11.[Code], A12.[Name],A.[ItemInfo_ItemCode],A.[ItemInfo_ItemName], A8.[SPECS], A7.[Name],A14.[Code], A15.[Name],A6.Code
  
  union all 

--销售退回 待入库
select  A2.[Code] as [存储地点_编码], A3.[Name] as [存储地点_名称],A5.[Code] as [主分类_编码], A6.[Name] as [主分类_名称],A4.[Code] as [料品_料号], A4.[Name] as [料品_品名], A4.[SPECS] as [料品_规格],A8.[Name] as [库存单位_名称],A7.[Code] as [库存单位_编码],0 as [标准收货],0 as [成品入库_入库数量],0 as [完工申报待入库数量], 0 as [生产退料数量],0 as [杂收数量],0 as [生产领料数量],0 as [杂发数量], 0 as [标准出货数量], 0 as [采购退货单],0 as [调出单在途数量],0 as [现存量_库存数量],sum(A1.[ArriveQtySU]) as [销售退回待入库数量],A13.[Code] as [组织_编码], A14.[Name] as [组织_名称] from  PM_Receivement as A  inner join [PM_RcvLine] as A1 on (A.[ID] = A1.[Receivement])  left join [CBO_Wh] as A2 on (A1.[Wh] = A2.[ID])  left join [CBO_Wh_Trl] as A3 on (A3.SysMlFlag = 'zh-CN') and (A2.[ID] = A3.[ID])  left join [CBO_ItemMaster] as A4 on (A1.[ItemInfo_ItemID] = A4.[ID])  left join [CBO_Category] as A5 on (A4.[MainItemCategory] = A5.[ID])  left join [CBO_Category_Trl] as A6 on (A6.SysMlFlag = 'zh-CN') and (A5.[ID] = A6.[ID])  left join [Base_UOM] as A7 on (A1.[StoreUOM] = A7.[ID])  left join [Base_UOM_Trl] as A8 on (A8.SysMlFlag = 'zh-CN') and (A7.[ID] = A8.[ID])  left join [PM_Receivement_Trl] as A9 on (A9.SysMlFlag = 'zh-CN') and (A.[ID] = A9.[ID])  left join [Lot_LotMaster] as A10 on (A1.[InvLot] = A10.[ID])
left join [PM_RcvDocType] as A15 on (A.[RcvDocType] = A15.[ID]) 
left join [Base_Organization] as A13 on (A.[Org] = A13.[ID])  
left join [Base_Organization_Trl] as A14 on (A14.SysMlFlag = 'zh-CN') and (A13.[ID] = A14.[ID])  where A.[Status] !='5' and (A15.[Code] ='012' or A15.[Code] ='013') group by A2.[Code], A3.[Name],A5.[Code], A6.[Name],A4.[Code], A4.[Name], A4.[SPECS],A7.[Code],A8.[Name],A13.[Code], A14.[Name]

) as AA 
 
group by AA.[存储地点_编码],AA.存储地点_名称,AA.主分类_编码,AA.主分类_名称,AA.料品_料号,AA.料品_品名,AA.料品_规格,AA.库存单位_名称,AA.库存单位_编码,AA.[组织_编码],AA.[组织_名称]

