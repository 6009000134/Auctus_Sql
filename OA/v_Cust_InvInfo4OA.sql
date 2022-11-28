/*
库存报表
*/
ALTER  VIEW v_Cust_InvInfo4OA
as
WITH data1 AS
(
SELECT 
t.OrgID,t.OrgCode,t.OrgName,t.Wh_ID,t.Wh_Name,t.StorageType,t.ItemInfo_ItemID,m.Code,m.Name,m.SPECS
,t.PUToRetQty
,t.Round1_Precision
,t.InOnWayQty--调入在途数量
,t.OutOnWayQty--调出在途数量
,t.NotUseQty--库存不可用数量
,t.CanUseQty--库存可用量
,t.ReservQty--预留量
,t.BalQty--现存量
,t.SupplyQtySU--
,t.DemandQtySU--需求数量
,t.Round_Precision
,t.BalQty_Main
,t.Temp_PAB--可用量
FROM (

SELECT 
t.OrgID,t.OrgCode,t.OrgName,t.Wh_ID,t.Wh_Name,t.StorageType,t.ItemInfo_ItemID

,SUM(t.PUToRetQty)PUToRetQty,t.Round1_Precision,SUM(t.InOnWayQty)InOnWayQty,SUM(t.OutOnWayQty)OutOnWayQty
  ,SUM(t.NotUseQty)NotUseQty,SUM(t.CanUseQty)CanUseQty,SUM(t.ReservQty)ReservQty,SUM(t.BalQty)BalQty,SUM(t.SupplyQtySU)SupplyQtySU,SUM(t.DemandQtySU)DemandQtySU
,t.Round_Precision,SUM(t.BalQty_Main)BalQty_Main,SUM(t.Temp_PAB)Temp_PAB
 FROM 
(
	--调出在途    
    SELECT  a8.ID OrgID,a8.Code OrgCode,o1.Name OrgName,A9.[Name] AS [Wh_Name] ,a9.ID Wh_ID,
            A1.StorageType ,
            A1.ItemInfo_ItemID ,
            --A3.[Name] AS [ItemSeg_Name] ,
            0 AS [PUToRetQty] ,
            A4.[Round_Precision] AS [Round1_Precision] ,
            0 AS [InOnWayQty] ,
            SUM(( A.[StoreUOMQty] - A.[RcvQty] )) AS [OutOnWayQty] ,
            0 AS [NotUseQty] ,
            0 AS [CanUseQty] ,
            0 AS [ReservQty] ,
            0 AS [BalQty] ,
            0 AS [SupplyQtySU] ,
            0 AS [DemandQtySU] ,
            A6.[Round_Precision] AS [Round_Precision] ,
            0 AS [BalQty_Main] ,
            0 AS [Temp_PAB] 
            --A1.[ItemInfo_ItemID] AS [Item_ItemID] ,
            --A1.[StoreUOM] AS [W_Uom] ,
            --A3.[InventoryUOM] AS [MainBaseSU_ID]
    FROM    InvDoc_TransOutSubLine AS A
            LEFT JOIN [InvDoc_TransOutLine] AS A1 ON ( A.[TransOutLine] = A1.[ID] )
            LEFT JOIN [CBO_Wh] AS A2 ON ( A1.[TransOutWh] = A2.[ID] )
            --LEFT JOIN [CBO_ItemMaster] AS A3 ON ( A1.[ItemInfo_ItemID] = A3.[ID] )
            LEFT JOIN [Base_UOM] AS A4 ON ( A.[StoreUOM] = A4.[ID] )
            LEFT JOIN [CBO_ItemMaster] AS A5 ON ( A.[ItemInfo_ItemID] = A5.[ID] )
            LEFT JOIN [Base_UOM] AS A6 ON ( A5.[InventoryUOM] = A6.[ID] )
            LEFT JOIN [InvDoc_TransferOut] AS A7 ON ( A1.[TransferOut] = A7.[ID] )
            LEFT JOIN [Base_Organization] AS A8 ON ( A1.[TransOutOrg] = A8.[ID] )
			LEFT JOIN dbo.Base_Organization_Trl o1 ON a8.ID=o1.ID AND o1.SysMLFlag='zh-cn'
            LEFT JOIN [CBO_Wh_Trl] AS A9 ON ( A9.SysMLFlag = 'zh-CN' )
                                            AND ( A2.[ID] = A9.[ID] )
    WHERE   A.[BusiClose] = 0
            AND ( A7.[Status] = 2 )
            --AND ( A8.[Code] = N'300' )                  
             --   AND ( A1.[ItemInfo_ItemCode] = N'202010698' )
    GROUP BY a8.ID,a8.code,o1.name,A9.[Name] ,	a9.id,
            A1.StorageType ,
            A1.[ItemInfo_ItemCode] ,
            --A3.[Name] ,
            A4.[Round_Precision] ,
            A6.[Round_Precision] ,
            A1.[ItemInfo_ItemID] ,
            A1.[StoreUOM] --,
            --A3.[InventoryUOM]
    UNION ALL
    --调入在途
    SELECT  a7.ID OrgID,a7.Code OrgCode,o1.Name OrgName,
	A8.[Name] AS [Wh_Name] ,a8.ID Wh_ID,
            A.StorageType ,
            A.ItemInfo_ItemID ,
            --A2.[Name] AS [ItemSeg_Name] ,
            0 AS [PUToRetQty] ,
            A3.[Round_Precision] AS [Round1_Precision] ,
            SUM(( A.[StoreUOMQty] - A.[RcvQty] )) AS [InOnWayQty] ,
            0 AS [OutOnWayQty] ,
            0 AS [NotUseQty] ,
            0 AS [CanUseQty] ,
            0 AS [ReservQty] ,
            0 AS [BalQty] ,
            0 AS [SupplyQtySU] ,
            0 AS [DemandQtySU] ,
            A4.[Round_Precision] AS [Round_Precision] ,
            0 AS [BalQty_Main] ,
            0 AS [Temp_PAB] 
            --A.[ItemInfo_ItemID] AS [Item_ItemID] ,
            --A.[StoreUOM] AS [W_Uom] ,
            --A2.[InventoryUOM] AS [MainBaseSU_ID]
    FROM    InvDoc_TransOutSubLine AS A
            LEFT JOIN [CBO_Wh] AS A1 ON ( A.[TransInWh] = A1.[ID] )
            LEFT JOIN [CBO_ItemMaster] AS A2 ON ( A.[ItemInfo_ItemID] = A2.[ID] )
            LEFT JOIN [Base_UOM] AS A3 ON ( A.[StoreUOM] = A3.[ID] )
            LEFT JOIN [Base_UOM] AS A4 ON ( A2.[InventoryUOM] = A4.[ID] )
            LEFT JOIN [InvDoc_TransOutLine] AS A5 ON ( A.[TransOutLine] = A5.[ID] )
            LEFT JOIN [InvDoc_TransferOut] AS A6 ON ( A5.[TransferOut] = A6.[ID] )
            LEFT JOIN [Base_Organization] AS A7 ON ( A.[TransInOrg] = A7.[ID] )
			LEFT JOIN dbo.Base_Organization_Trl o1 ON a7.ID=o1.ID AND o1.SysMLFlag='zh-cn'
            LEFT JOIN [CBO_Wh_Trl] AS A8 ON ( A8.SysMLFlag = 'zh-CN' )
                                            AND ( A1.[ID] = A8.[ID] )
    WHERE   A.[BusiClose] = 0
            AND ( A6.[Status] = 2 )
          --  AND ( A7.[Code] = N'300' )
            --AND ( A.[ItemInfo_ItemCode] = N'202010698' )
    GROUP BY a7.ID,a7.Code,o1.Name,A8.[Name] ,a8.id,
            A.StorageType ,
            A.[ItemInfo_ItemCode] ,
            A2.[Name] ,
            A3.[Round_Precision] ,
            A4.[Round_Precision] ,
            A.[ItemInfo_ItemID] ,
            A.[StoreUOM] ,
            A2.[InventoryUOM]
			UNION all
			SELECT  a5.ID OrgID,a5.Code OrgCode,o1.Name OrgName,A6.[Name] AS [Wh_Name] ,a6.ID Wh_ID,
a.StorageType,
        A.ItemInfo_ItemID ,
        --ISNULL(CASE WHEN A2.[ItemFormAttribute] IN ( 16, 22 )
        --            THEN A.[ItemInfo_ItemName]
        --            ELSE A2.[Name]
        --       END, '') AS [ItemSeg_Name] ,
        A.[ToRetStQty] [PUToRetQty] ,--SUM
        A3.[Round_Precision] AS [Round1_Precision] ,
        CONVERT(DECIMAL(24, 9), 0) AS [InOnWayQty] ,
        CONVERT(DECIMAL(24, 9), 0) AS [OutOnWayQty] ,
        CASE WHEN ( ( ( ( A.[IsProdCancel] = 1 )
                            OR ( A.[MO_EntityID] != 0 )
                          )
                          OR A.[ProductDate] IS NOT NULL
                        )
                        OR ( A.[WP_EntityID] != 0 )
                      ) THEN A.[StoreQty]
                 ELSE CONVERT(DECIMAL(24, 9), 0)
            END AS [NotUseQty] ,--SUM
        ( ( ( A.[StoreQty] - A.[ResvStQty] ) - A.[ResvOccupyStQty] )
              - CASE WHEN ( ( ( ( A.[IsProdCancel] = 1 )
                                OR ( A.[MO_EntityID] != 0 )
                              )
                              OR A.[ProductDate] IS NOT NULL
                            )
                            OR ( A.[WP_EntityID] != 0 )
                          ) THEN A.[StoreQty]
                     ELSE CONVERT(DECIMAL(24, 9), 0)
                END ) AS [CanUseQty] ,--SUM
        A.[ResvStQty] AS [ReservQty] ,--SUM
        ( A.[StoreQty] + A.[ToRetStQty] ) AS [BalQty] ,--SUM
        A.[SupplyQtySU] AS [SupplyQtySU] ,--SUM
        A.[DemandQtySU] AS [DemandQtySU] ,--SUM
        A4.[Round_Precision] AS [Round_Precision] ,--MAX
        ( A.[StoreMainQty] + A.[ToRetStMainQty] ) AS [BalQty_Main] ,--SUM
        ( ( ( ( ( A.[StoreQty] - A.[ResvStQty] ) - A.[ResvOccupyStQty] )
                  - CASE WHEN ( ( ( ( A.[IsProdCancel] = 1 )
                                    OR ( A.[MO_EntityID] != 0 )
                                  )
                                  OR A.[ProductDate] IS NOT NULL
                                )
                                OR ( A.[WP_EntityID] != 0 )
                              ) THEN A.[StoreQty]
                         ELSE CONVERT(DECIMAL(24, 9), 0)
                    END ) + A.[SupplyQtySU] ) - A.[DemandQtySU] ) AS [Temp_PAB] --SUM
        --CONVERT(BIGINT, 0) AS [Item_ItemID] ,
        --CONVERT(BIGINT, 0) AS [W_Uom] ,
        --CONVERT(BIGINT, 0) AS [MainBaseSU_ID]
FROM    InvTrans_WhQoh AS A
        LEFT JOIN [CBO_Wh] AS A1 ON ( A.[Wh] = A1.[ID] )
        --LEFT JOIN [CBO_ItemMaster] AS A2 ON ( A.[ItemInfo_ItemID] = A2.[ID] )
        LEFT JOIN [Base_UOM] AS A3 ON ( A.[StoreUOM] = A3.[ID] )
        LEFT JOIN [Base_UOM] AS A4 ON ( A.[StoreMainUOM] = A4.[ID] )
        LEFT JOIN [Base_Organization] AS A5 ON ( A.[LogisticOrg] = A5.[ID] )
		LEFT JOIN dbo.Base_Organization_Trl o1 ON a5.ID=o1.ID AND o1.SysMLFlag='zh-cn'
        LEFT JOIN [CBO_Wh_Trl] AS A6 ON ( A6.SysMLFlag = 'zh-CN' )
                                        AND ( A1.[ID] = A6.[ID] )
WHERE   1=1 
) t 
GROUP BY t.OrgID,t.OrgCode,t.OrgName,t.Wh_ID,t.Wh_Name,t.StorageType,t.ItemInfo_ItemID,t.Round1_Precision,t.Round_Precision
)t LEFT JOIN dbo.CBO_ItemMaster m ON t.ItemInfo_ItemID=m.ID
WHERE 1=1 
)
SELECT 
CONVERT(VARCHAR(100),t.OrgID)+CONVERT(VARCHAR(100),t.Wh_ID)+CONVERT(VARCHAR(100),t.StorageType)+CONVERT(VARCHAR(100),t.ItemInfo_ItemID)ID
,t.OrgID,t.OrgCode,t.OrgName--组织
,t.Wh_ID,t.Wh_Name--存储地点
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.StorageTypeEnum',t.StorageType,'zh-cn')StorageType--存储类型
,t.ItemInfo_ItemID
,t.Code--料号
,t.Name--品名
,t.SPECS--规格
,t.PUToRetQty
,t.Round1_Precision
,t.InOnWayQty--调入在途数量
,t.OutOnWayQty--调出在途数量
,t.NotUseQty--库存不可用数量
,t.CanUseQty--库存可用量
,t.ReservQty--预留量
,t.BalQty--现存量
,t.SupplyQtySU--
,t.DemandQtySU--需求数量
,t.Round_Precision
,t.BalQty_Main
,t.Temp_PAB--可用量
FROM data1 t
--WHERE t.BalQty>0


