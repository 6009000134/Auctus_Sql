ALTER VIEW v_cust_FACard4OA
as
SELECT a.ID
,a.DocNo--卡片编号
,a.ItemCode--资产编号
,a1.AssetName
,a.Org OrgID,o.Code OrgCode,o1.Name OrgName--组织
,b.OriginalValue*dbo.fn_GetCurrentRate(b.Currency,1,GETDATE(),2) OriginalValue--资产原值（人民币）
FROM dbo.FA_AssetCard a INNER JOIN FA_AssetCardAccountInformation b ON a.ID=b.AssetCard
INNER JOIN dbo.FA_AssetCard_Trl a1 ON a.ID=a1.ID
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
WHERE a.Statues=2
AND EXISTS(SELECT 1 FROM dbo.FA_AssetTag t WHERE t.AssetCard=a.ID AND t.Statues=0)
AND NOT EXISTS ( select 1 from FA_AssetCardAccountInformation
                                                              as t1
                                                           where
                                                              ( ( ( t1.[AssetCard] = A.ID )
                                                              and ( t1.[CurrentBusiness] != 4 )
                                                              )
                                                              and ( t1.[CurrentDocID] != ( -( 5 ) ) )
                                                              ) ) 
GO
