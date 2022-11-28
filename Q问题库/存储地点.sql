SELECT a.Org,a.Code,a1.name,a.Effective_IsEffective,a.Effective_EffectiveDate,a.Effective_DisableDate
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.StorageTypeEnum',b.StorageType,'zh-cn')存储类型
,CASE WHEN b.IsCanMRP=1 THEN '可MRP' ELSE '' END 
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.NetableTypeEnum',b.NetableType,'zh-cn')可用类型
FROM dbo.CBO_Wh a INNER JOIN dbo.CBO_Wh_Trl a1 ON a.id=a1.id INNER JOIN dbo.CBO_WhStorageType b ON a.ID=b.Warehouse
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID
WHERE o.Code='500' AND a.Effective_IsEffective=1
--481,011	










--PRINT 44+7+25+3+7+3

--PRINT 15000*3+14310.34+15750+14504.31+14223.72+12500*4+14062.50+26197.36+11942.92

--PRINT 163961.97+60000+30000-14000

