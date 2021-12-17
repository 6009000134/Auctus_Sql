alter VIEW v_cust_FATag4OA
as
SELECT 
b.ID--�ʲ���ǩID
,b.Code--�ʲ���ǩ����
,b.CreatedOn
,a.StartDate
,a.ID CardID--�ʲ���ƬID
,a.DocNo--��Ƭ���
,b.AssetLocation,c1.Name--λ��
,o.ID OrgID,o.Code OrgCode,o1.Name OrgName
FROM dbo.FA_AssetCard a INNER JOIN dbo.FA_AssetTag b ON a.ID=b.AssetCard
INNER JOIN dbo.FA_Location c ON b.AssetLocation=c.ID INNER JOIN dbo.FA_Location_Trl c1 ON c.ID=c1.ID
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID 
LEFT JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND ISNULL(o1.SysMLFlag,'zh-cn')='zh-cn'
WHERE b.Statues=0
       AND ( NOT EXISTS ( SELECT   1
                           FROM     FA_AssetCardAccountInformation AS t
                           WHERE    ( ( ( t.[AssetCard] = b.[AssetCard] )
                                        AND ( t.[CurrentBusiness] != 4 )
                                      )
                                      AND ( t.[CurrentDocID] != ( -( 5 ) ) )
                                    ) )
            )
