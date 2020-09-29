SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
--/*
--料品及库存可用量
--*/
ALTER VIEW  V_Cust_ItemAndWhQoh
AS

WITH WhQty AS
(
SELECT  *
FROM    ( SELECT    A.[ID] AS [ID] ,
                    --A.[SysVersion] AS [SysVersion] ,
                    A.ItemInfo_ItemID AS [ItemMasterID] ,
                    ISNULL(A.[StoreQty],0)-ISNULL(A.[ResvStQty],0)-ISNULL(A.[ResvOccupyStQty],0) AS [AbleUserNumber],
					a.LotInfo_LotCode,
                    A4.[Name] AS [LogisticOrg_Name] ,
                    A7.[Name] AS [Wh_Name] ,
					a6.Code AS Wh_Code,
					a5.ID AS Wh_ID,
                    A9.[Name] AS [ItemOwnOrg_Name] ,
                    A.StoreQty AS [Custom_StoreQty] ,
                    A.ResvStQty AS [Custom_ResvStQty] ,
                    A.ResvOccupyStQty AS [Custom_ResvOccupyStQty] ,
                    A2.[Round_Precision] AS [StoreUOM_Precision] ,
                    A2.[Round_RoundType] AS [StoreUOM_RoundType] ,
                    A2.[Round_RoundValue] AS [StoreUOM_RoundValue] ,
                    A.SupplyQtySU AS [SupplyQtySU] ,
                    A.DemandQtySU AS [DemandQtySU] ,
                    ISNULL(A.[StoreQty],0)- ISNULL(A.[ResvStQty],0)- ISNULL(A.[ResvOccupyStQty],0)+ ISNULL(A.[SupplyQtySU],0)- ISNULL(A.[DemandQtySU],0)  AS [TotalWhQty],
                    A.[ItemInfo_ItemName] AS [ItemInfo_ItemNameHidden] ,
                    A.[ItemOwnOrg] AS [ItemOwnOrg] ,
                    A.[LogisticOrg] AS [LogisticOrg] ,
                    A.[Wh] AS [Wh] ,
                    A5.[Code] AS SysMlFlag 
          FROM      InvTrans_WhQoh AS A
                    LEFT JOIN Base_UOM AS A2 ON ( A.StoreUOM = A2.[ID] )
                    LEFT JOIN [Base_Organization] AS A3 ON ( A.[LogisticOrg] = A3.[ID] )
                    LEFT JOIN Base_Language AS A5 ON ( A5.Code = 'zh-CN' )
                                                     AND ( A5.Effective_IsEffective = 1 )
                    LEFT JOIN [Base_Organization_Trl] AS A4 ON ( A4.SysMLFlag = 'zh-CN' )
                                                              AND ( A4.SysMLFlag = A5.Code )
                                                              AND ( A3.[ID] = A4.[ID] )
                    LEFT JOIN [CBO_Wh] AS A6 ON ( A.[Wh] = A6.[ID] )
                    LEFT JOIN [CBO_Wh_Trl] AS A7 ON ( A7.SysMLFlag = 'zh-CN' )
                                                    AND ( A7.SysMLFlag = A5.Code )
                                                    AND ( A6.[ID] = A7.[ID] )
                    LEFT JOIN [Base_Organization] AS A8 ON ( A.[ItemOwnOrg] = A8.[ID] )
                    LEFT JOIN [Base_Organization_Trl] AS A9 ON ( A9.SysMLFlag = 'zh-CN' )
                                                              AND ( A9.SysMLFlag = A5.Code )
                                                              AND ( A8.[ID] = A9.[ID] )
        ) T
)
SELECT  *
FROM    ( SELECT    A.[ID] AS [ItemMasterID] ,
                    A.[Code] AS [Code] ,
                    A.[Name] AS [Name] ,
					a.Org,o.Code OrgCode,o1.Name OrgName,
                    A.[InventoryUOM] AS [InventoryUOM] ,
                    A3.[Code] AS [InventoryUOM_Code] ,
                    A4.[Name] AS [InventoryUOM_Name] ,
					b.AbleUserNumber 		-					ISNULL((SELECT SUM(t1.CostUOMQty)
					FROM dbo.InvDoc_MiscShip t INNER JOIN dbo.InvDoc_MiscShipL t1 ON t.ID=t1.MiscShip
		WHERE t.Status=1 AND t.Org=A.Org AND t1.ItemInfo_ItemID=a.ID
		GROUP BY t1.ItemInfo_ItemID,t.Org),0) 
		 AbleUserNumber,				--可用量
					b.Wh_Name,b.Wh,b.Wh_Code--存储地点
					,b.LotInfo_LotCode AS LotCode--批号
					,b.ID WhQohID--库存ID
                    ,ROW_NUMBER() OVER ( ORDER BY A.[Code] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
          FROM      CBO_ItemMaster AS A INNER JOIN WhQty B ON a.ID=b.ItemMasterID
                    LEFT JOIN Base_UOM AS A1 ON ( A.[InventorySecondUOM] = A1.[ID] )
                    LEFT JOIN CBO_ItemConvertRatioInClass AS A2 ON ( ( A.[ID] = A2.[ItemMaster] )
                                                              AND ( A1.[ID] = A2.[UOM] )
                                                              )
                    LEFT JOIN [Base_UOM] AS A3 ON ( A.[InventoryUOM] = A3.[ID] )
                    LEFT JOIN Base_Language AS A5 ON ( A5.Code = 'zh-CN' )
                                                     AND ( A5.Effective_IsEffective = 1 )
                    LEFT JOIN [Base_UOM_Trl] AS A4 ON ( A4.SysMLFlag = 'zh-CN' )
                                                      AND ( A4.SysMLFlag = A5.Code )
                                                      AND ( A3.[ID] = A4.[ID] )
													  LEFT JOIN dbo.Base_Organization o ON a.Org=o.ID
													  LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-CN'
          WHERE     ( (  (  ( ( A.[IsInventoryEnable] = 1 )
                                    AND ( ( A.[ItemFormAttribute] IN ( 4, 5, 9,10, 2, 11, 15,16, 19, 20, 21,6, 14, 22 )OR ( A.[ItemFormAttribute] = 22 )                                          )                                          OR ( A.[ItemFormAttribute] = 18 )                                        )                                  )                            )                      )                      AND ( ( ( A.[Effective_IsEffective] = 1 )
                              AND ( A.[Effective_EffectiveDate] <= GETDATE() ))AND ( A.[Effective_DisableDate] >= GETDATE() )
                          )
                    ) AND b.AbleUserNumber>0--库存可用量>0
        ) T



GO
