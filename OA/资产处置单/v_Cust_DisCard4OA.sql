/*
�ɱ��Ͽ�Ƭ
�ʲ���Ƭ�����۾�δ��ѡ�ģ�����ʱ���۾���Ϣ,��ֵ�;�ֵ����
*/
ALTER VIEW v_Cust_DisCard4OA
as
SELECT A.[ID] AS [ID] ,
        A1.[ID] AS [OwnerOrg_ID] ,
        A1.[Code] AS [OwnerOrg_Code] ,
        A2.[Name] AS [OwnerOrg_Name] ,
        A.[DocNo] AS [DocNo] ,
        A.[ItemCode] AS [ItemCode] ,
        A3.[AssetName] AS [AssetName] ,
        A5.[Name] AS [UOM_Name] ,
        A.[Qty] AS [Qty] ,
        A3.[AssetDescription] AS [AssetDescription] ,
        ROW_NUMBER() OVER ( ORDER BY A.[DocNo] ASC, ( A.[ID] + 17 ) ASC ) AS rownum
 FROM   FA_AssetCard AS A
        LEFT JOIN [Base_Organization] AS A1 ON ( A.[OwnerOrg] = A1.[ID] )
        LEFT JOIN [Base_Organization_Trl] AS A2 ON ( A2.SysMLFlag = 'zh-CN' )
                                                   AND ( A1.[ID] = A2.[ID] )
        LEFT JOIN [FA_AssetCard_Trl] AS A3 ON ( A3.SysMLFlag = 'zh-CN' )
                                              AND ( A.[ID] = A3.[ID] )
        LEFT JOIN [Base_UOM] AS A4 ON ( A.[UOM] = A4.[ID] )
        LEFT JOIN [Base_UOM_Trl] AS A5 ON ( A5.SysMLFlag = 'zh-CN' )
                                          AND ( A4.[ID] = A5.[ID] )
        LEFT JOIN [Base_Organization] AS A6 ON ( A.[Org] = A6.[ID] )
 WHERE  A.[Statues] = 2
        AND A.[Qty] > 0
        AND A.[ID] IN ( SELECT  B.[AssetCard]
                        FROM    FA_AssetTag AS B
                        WHERE   B.[Statues] = 0 )--����״̬
        --AND ( A.[Org] = 1001708020135435 )
        --AND ( A.[OwnerOrg] = 1001708020135435 )
        AND A.[ID] NOT IN ( SELECT  B.[AssetCard]
                            FROM    FA_AssetCardAccountInformation AS B
                            WHERE   B.[CurrentBusiness] != 4 --��ǰҵ��4-����
                                    AND B.[CurrentDocID] != -2 );
       
