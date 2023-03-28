SELECT 
a.ID
,a.Org ��֯ID
,o.Code ��֯����
,o1.Name ��֯����
,a.Code ����
,a1.Name ����
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.StorageTypeEnum',a.StorageType,'zh-cn')Ĭ�ϴ洢����
--,b.StorageType
,dbo.F_GetEnumName('UFIDA.U9.CBO.Enums.StorageTypeEnum',b.StorageType,'zh-cn')�洢����
--,b.NetableType
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.NetableTypeEnum',b.NetableType,'zh-cn')��������
,a.Effective_IsEffective �Ƿ���Ч
,a.Effective_EffectiveDate ��Ч����
,a.Effective_DisableDate ʧЧ����
,a.Location λ��
--,a.LocationType λ������
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.LocationTypeEnum',a.LocationType,'zh-cn')λ������
--,a.NormalWhType ��ͨ��
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.NormalWhTypeEnum',a.LocationType,'zh-cn')��ͨ��
--,a.OutboundType
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.OutboundTypeEnum',a.OutboundType,'zh-cn')�����
--,a.DepositType
,dbo.F_GetEnumName('UFIDA.U9.CBO.SCM.Warehouse.DepositTypeEnum',a.DepositType,'zh-cn')��Ĳ�
,CASE WHEN a.IsStage=1 THEN'��' ELSE '��' END  ��������
,CASE WHEN a.IsKeepTax=1 THEN'��' ELSE '��' END  ��˰��
,CASE WHEN a.IsCountReplenish=1 THEN'��' ELSE '��' END  �̵��ٲ���
,CASE WHEN a.IsAllowNegative=1 THEN '��' ELSE '��' END  �������
,CASE WHEN a.IsCountFrozen=1 THEN '��' ELSE '��' END  �̵㶳��
,CASE WHEN a.IsBin=1 THEN '��' ELSE '��' END  ��λ����
,CASE WHEN a.IsLot=1 THEN '��' ELSE '��' END  ���Ź���
,CASE WHEN a.IsSerial=1 THEN '��' ELSE '��' END  ���кŹ���
FROM dbo.CBO_Wh a INNER JOIN dbo.CBO_Wh_Trl a1 ON a.ID=a1.ID AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization o ON a.Org=o.ID 
INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID AND o1.SysMLFlag='zh-cn'
LEFT JOIN dbo.CBO_WhStorageType b ON a.ID=b.Warehouse LEFT JOIN dbo.CBO_WhStorageType_Trl b1 ON b.id=b1.ID AND b1.SysMLFlag='zh-cn'
WHERE a.Org=1001708020135665
AND a.Effective_IsEffective=1
AND GETDATE() BETWEEN a.Effective_EffectiveDate AND a.Effective_DisableDate
--AND a.Code='101'
ORDER BY a.Code,b.NetableType,b.StorageType



