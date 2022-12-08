--SELECT 
--a.ID,a.Code,a1.Name,a.DescFlexField_PrivateDescSeg1 集成OA
--FROM dbo.PM_RcvDocType a INNER JOIN dbo.PM_RcvDocType_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
--WHERE a.Org=1001708020135435

--SELECT 
--a.ID,a.Code,a1.Name,a.DescFlexField_PrivateDescSeg1 集成OA
--FROM dbo.SM_ShipDocType a INNER JOIN dbo.SM_ShipDocType_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
--WHERE a.Org=1001708020135435

--SELECT 
--a.ID,a.Code,a1.Name,a.DescFlexField_PrivateDescSeg1 集成OA
--FROM dbo.InvDoc_MiscRcvDocType a INNER JOIN dbo.InvDoc_MiscRcvDocType_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
--WHERE a.Org=1001708020135435

--SELECT 
--a.ID,a.Code,a1.Name,a.DescFlexField_PrivateDescSeg1 集成OA
--FROM dbo.InvDoc_MiscShipDocType a INNER JOIN dbo.InvDoc_MiscShipDocType_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
--WHERE a.Org=1001708020135435

SELECT 
a.ID,a.Code,a1.Name,a.DescFlexField_PrivateDescSeg1 集成OA
FROM dbo.InvDoc_TransInDocType a INNER JOIN dbo.InvDoc_TransInDocType_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
WHERE a.Org=1001708020135435 AND a.Effective_IsEffective=1

