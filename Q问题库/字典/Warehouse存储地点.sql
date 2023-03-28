SELECT 
a.ID
,a.Org 组织ID
,o.Code 组织编码
,o1.Name 组织名称
,a.Code 编码
,a1.Name 名称
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.StorageTypeEnum',a.StorageType,'zh-cn')默认存储类型
--,b.StorageType
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.StorageTypeEnum',b.StorageType,'zh-cn')存储类型
--,b.NetableType
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.NetableTypeEnum',b.NetableType,'zh-cn')可用类型
,a.Effective_IsEffective 是否生效
,a.Effective_EffectiveDate 生效日期
,a.Effective_DisableDate 失效日期
,a.Location 位置
--,a.LocationType 位置属性
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.LocationTypeEnum',a.LocationType,'zh-cn')位置属性
--,a.NormalWhType 普通仓
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.NormalWhTypeEnum',a.LocationType,'zh-cn')普通仓
--,a.OutboundType
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.OutboundTypeEnum',a.OutboundType,'zh-cn')寄外仓
--,a.DepositType
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.DepositTypeEnum',a.DepositType,'zh-cn')外寄仓
,CASE WHEN a.IsStage=1 THEN'是' ELSE '否' END  待出货区
,CASE WHEN a.IsKeepTax=1 THEN'是' ELSE '否' END  保税仓
,CASE WHEN a.IsCountReplenish=1 THEN'是' ELSE '否' END  盘点再补货
,CASE WHEN a.IsAllowNegative=1 THEN '是' ELSE '否' END  允许负库存
,CASE WHEN a.IsCountFrozen=1 THEN '是' ELSE '否' END  盘点冻结
,CASE WHEN a.IsBin=1 THEN '是' ELSE '否' END  库位管理
,CASE WHEN a.IsLot=1 THEN '是' ELSE '否' END  批号管理
,CASE WHEN a.IsSerial=1 THEN '是' ELSE '否' END  序列号管理
FROM dbo.CBO_Wh a INNER JOIN dbo.CBO_Wh_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID 
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_WhStorageType b ON a.ID=b.Warehouse LEFT JOIN dbo.CBO_WhStorageType_Trl b1 ON b.id=b1.ID AND b1.SysMLFlag='zh-cn'
WHERE a.Org=1001708020135665
AND a.Effective_IsEffective=1
AND GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate
--AND a.Code='101'
ORDER BY a.Code,b.NetableType,b.StorageType



