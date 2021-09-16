/*
资产卡片-使用状况
*/
CREATE VIEW v_Cust_FACardUseState
as
SELECT a.ID,a.Code,a.Org,a.IsLeaf,a1.Name
FROM dbo.FA_UseState a INNER JOIN dbo.FA_UseState_Trl a1 ON a.ID=a1.ID
WHERE a.IsLeaf=1 AND a.Effective_IsEffective=1