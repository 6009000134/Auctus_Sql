--供需资料追溯
EXEC MRP_PeggingTreeRunUpAndDown @DSInfoID=1002210125949956,@RunType=1,@TraceType=0
--供需资料汇总
EXEC MRP_GetDSInfoByTimeBucket @planversion=1001905311704959,@item=1002011160048651,@FactoryOrg=1001708020135665,@itemversion=N'',@bucket=1001709230110300,@project=-1,@task=-1

/*
SELECT  *
FROM    ( SELECT    A.[ID] AS [ID] ,
                    A.[SysVersion] AS [SysVersion] ,
                    A.[FactoryOrg] AS [FactoryOrg] ,
                    A.[Org] AS [Org] ,
                    A.[Item] AS [Item] ,
                    A.[FromDegree] AS [FromDegree] ,
                    A.[OwnerOrg] AS [OwnerOrg] ,
                    A.[PlanVersion] AS [PlanVersion] ,
                    A1.[Code] AS [StoreMainUOM_Code] ,
                    A2.[Name] AS [StoreMainUOM_Name] ,
                    A.[Sub] AS [Sub] ,
                    A5.[Round_Precision] AS [Item_InventoryUOM_Round_Precision] ,
                    A5.[Round_RoundType] AS [Item_InventoryUOM_Round_RoundType] ,
                    A5.[Round_RoundValue] AS [Item_InventoryUOM_Round_RoundValue] ,
                    A6.[Code] AS [Task_Code] ,
                    A7.[Name] AS [Task_Name] ,
                    A.[SupplyType] AS [SupplyType] ,
                    A.[BeforeAdjustSMQty] AS [BeforeAdjustSMQty] ,
                    A.[BeforeAdjustDemandDate] AS [BeforeAdjustDemandDate] ,
                    A.[Seiban] AS [Seiban] ,
                    A8.[SeibanNO] AS [Seiban_SeibanNO] ,
                    A.[OriginalDocHeader_EntityID] AS [OriginalDocHeader_EntityID] ,
                    A.[IsOptimized] AS [IsOptimized] ,
                    A.[IsFirmPlannedMO] AS [IsFirmPlannedMO] ,
                    A.[IsSubcontract] AS [IsSubcontract] ,
                    A.[SrcShipLineNo] AS [SrcShipLineNo] ,
                    A.[ItemVersion] AS [ItemVersion] ,
                    A.[ToDegree] AS [ToDegree] ,
                    A.[FromPotency] AS [FromPotency] ,
                    A.[ToPotency] AS [ToPotency] ,
                    A.[Warehouse] AS [Warehouse] ,
                    A.[Lot] AS [Lot] ,
                    A.[LotInValidDate] AS [LotInValidDate] ,
                    A.[Supplier] AS [Supplier] ,
                    A.[DSType] AS [DSType] ,
                    A.[DocNo] AS [DocNo] ,
                    A.[DocVersion] AS [DocVersion] ,
                    A.[DocType] AS [DocType] ,
                    A.[LineNum] AS [LineNum] ,
                    A.[PlanLineNum] AS [PlanLineNum] ,
                    A.[TradeBaseUOM] AS [TradeBaseUOM] ,
                    A.[TradeBaseQty] AS [TradeBaseQty] ,
                    A.[StoreMainUOM] AS [StoreMainUOM] ,
                    A.[SMQty] AS [SMQty] ,
                    A.[ReserveQty] AS [ReserveQty] ,
                    A.[DemandDate] AS [DemandDate] ,
                    A.[IsFirm] AS [IsFirm] ,
                    A.[Project] AS [Project] ,
                    A.[Task] AS [Task] ,
                    A.[DemandCode] AS [DemandCode] ,
                    A.[PreDemandLine] AS [PreDemandLine] ,
                    A.[PreItemOrg] AS [PreItemOrg] ,
                    A.[PreItem] AS [PreItem] ,
                    A.[PreDocNo] AS [PreDocNo] ,
                    A.[PreDocVersion] AS [PreDocVersion] ,
                    A.[PreDocLineNum] AS [PreDocLineNum] ,
                    A.[PreDocPlanLineNum] AS [PreDocPlanLineNum] ,
                    A.[SrcPCDocNo] AS [SrcPCDocNo] ,
                    A.[SrcPCLineNo] AS [SrcPCLineNo] ,
                    A.[OriginalDoc_EntityID] AS [OriginalDoc_EntityID] ,
                    A9.[Code] AS [FactoryOrg_Code] ,
                    A10.[Name] AS [FactoryOrg_Name] ,
                    A11.[Code] AS [Org_Code] ,
                    A12.[Name] AS [Org_Name] ,
                    A13.[Code] AS [OwnerOrg_Code] ,
                    A14.[Name] AS [OwnerOrg_Name] ,
                    A4.[Code] AS [Item_Code] ,
                    A4.[Name] AS [Item_Name] ,
                    A15.[Code] AS [Warehouse_Code] ,
                    A16.[Name] AS [Warehouse_Name] ,
                    A17.[Code] AS [Project_Code] ,
                    A18.[Name] AS [Project_Name] ,
                    A19.[Code] AS [Supplier_Code] ,
                    A20.[Name] AS [Supplier_Name] ,
                    A.[OriginalDoc_EntityType] AS [OriginalDoc_EntityType] ,
                    A.[OriginalDocHeader_EntityType] AS [OriginalDocHeader_EntityType] ,
                    A23.[Code] AS [BOMComponent_BOMMaster_ItemMaster_Code] ,
                    A3.[Code] AS SysMlFlag ,
                    ROW_NUMBER() OVER ( ORDER BY A.[DemandDate] ASC, A.[DSType] ASC, ( A.[ID]
                                                              + 17 ) ASC ) AS rownum
          FROM      MRP_DSInfo AS A
                    LEFT JOIN [Base_UOM] AS A1 ON ( A.[StoreMainUOM] = A1.[ID] )
                    LEFT JOIN Base_Language AS A3 ON ( A3.Effective_IsEffective = 1 )
                    LEFT JOIN [Base_UOM_Trl] AS A2 ON ( A2.SysMLFlag = A3.Code )
                                                      AND ( A1.[ID] = A2.[ID] )
                    LEFT JOIN [CBO_ItemMaster] AS A4 ON ( A.[Item] = A4.[ID] )
                    LEFT JOIN [Base_UOM] AS A5 ON ( A4.[InventoryUOM] = A5.[ID] )
                    LEFT JOIN [CBO_Task] AS A6 ON ( A.[Task] = A6.[ID] )
                    LEFT JOIN [CBO_Task_Trl] AS A7 ON ( A7.SysMLFlag = A3.Code )
                                                      AND ( A6.[ID] = A7.[ID] )
                    LEFT JOIN [CBO_SeibanMaster] AS A8 ON ( A.[Seiban] = A8.[ID] )
                    LEFT JOIN [Base_Organization] AS A9 ON ( A.[FactoryOrg] = A9.[ID] )
                    LEFT JOIN [Base_Organization_Trl] AS A10 ON ( A10.SysMLFlag = A3.Code )
                                                              AND ( A9.[ID] = A10.[ID] )
                    LEFT JOIN [Base_Organization] AS A11 ON ( A.[Org] = A11.[ID] )
                    LEFT JOIN [Base_Organization_Trl] AS A12 ON ( A12.SysMLFlag = A3.Code )
                                                              AND ( A11.[ID] = A12.[ID] )
                    LEFT JOIN [Base_Organization] AS A13 ON ( A.[OwnerOrg] = A13.[ID] )
                    LEFT JOIN [Base_Organization_Trl] AS A14 ON ( A14.SysMLFlag = A3.Code )
                                                              AND ( A13.[ID] = A14.[ID] )
                    LEFT JOIN [CBO_Wh] AS A15 ON ( A.[Warehouse] = A15.[ID] )
                    LEFT JOIN [CBO_Wh_Trl] AS A16 ON ( A16.SysMLFlag = A3.Code )
                                                     AND ( A15.[ID] = A16.[ID] )
                    LEFT JOIN [CBO_Project] AS A17 ON ( A.[Project] = A17.[ID] )
                    LEFT JOIN [CBO_Project_Trl] AS A18 ON ( A18.SysMLFlag = A3.Code )
                                                          AND ( A17.[ID] = A18.[ID] )
                    LEFT JOIN [CBO_Supplier] AS A19 ON ( A.[Supplier] = A19.[ID] )
                    LEFT JOIN [CBO_Supplier_Trl] AS A20 ON ( A20.SysMLFlag = A3.Code )
                                                           AND ( A19.[ID] = A20.[ID] )
                    LEFT JOIN [CBO_BOMComponent] AS A21 ON ( A.[BOMComponent] = A21.[ID] )
                    LEFT JOIN [CBO_BOMMaster] AS A22 ON ( A21.[BOMMaster] = A22.[ID] )
                    LEFT JOIN [CBO_ItemMaster] AS A23 ON ( A22.[ItemMaster] = A23.[ID] )
          WHERE     ( ( ( ( ( A.[PlanVersion] = 1001905311704959 )
                            AND ( A.[FactoryOrg] = 1001708020135665 )
                          )
                          AND ( A4.[Code] = N'201010457' )
                        )
                        AND ( A.[ItemVersion] = '' )
                      )
                      AND ( A.[BeforeAdjustSMQty] > 0 )
                    )
        ) T; 
*/