DECLARE @MaterialVerId VARCHAR(50)='6a1418ac-d88f-430f-899a-59eb4b6d510d'

--DECLARE @BomCode VARCHAR(100)='102020015'
--DECLARE @BomCode VARCHAR(100)='202010656'
--DECLARE @BomCode VARCHAR(100)='309010013' 


DECLARE cc CURSOR
FOR 
SELECT MaterialVerId FROM dbo.MAT_MaterialVersion WHERE IsEffect=1 AND Code IN (
'101010034',
'101010039',
'101010065',
'101010066',
'101010201',
'101010202',
'101010203',
'101010204',
'101010206',
'101010207',
'101010218',
'101010287',
'101010288',
'101010402',
'101010420',
'101010422',
'101010423',
'101010433',
'101010438',
'101010440',
'101010441',
'101010448',
'101010457',
'101010458',
'101010459',
'101010460',
'101010461',
'101010462',
'101010463',
'101010480',
'101010481',
'101010482',
'101010496',
'101010497',
'101010506',
'101010538',
'101010556',
'101010564',
'101010565',
'101010566',
'101010573',
'101010574',
'101010587',
'101010588',
'101010589',
'101010590',
'101010593',
'101010594',
'101010595',
'101010596',
'101010597',
'101010598',
'101010599',
'101010600',
'101010601',
'101010602',
'101010603',
'101010604',
'101010605',
'101010606',
'101010608',
'101010610',
'101010611',
'101010612',
'101010613',
'101010614',
'101010615',
'101010616',
'101010617',
'101010625',
'101010627',
'101010629',
'101010643',
'101010645',
'101010646',
'101010648',
'101010650',
'101010660',
'101010665',
'101010666',
'101010668',
'101010670',
'101010671',
'101010692',
'101010699',
'101010700',
'101010716',
'101010717',
'101010720',
'101010728',
'101010729',
'101010730',
'101010734',
'101010735',
'101010736',
'101010737',
'102010006',
'102020005',
'102020006',
'102020012',
'102020014',
'102020015',
'102020020',
'102020037',
'102020039',
'103010100',
'103010101',
'103010102',
'103010103',
'103010152',
'103010153'
)
OPEN cc
FETCH NEXT FROM cc INTO @MaterialVerId
		WHILE @@FETCH_STATUS=0
BEGIN
	PRINT @MaterialVerId
	;
WITH data1 AS--料品数据
(
SELECT a.MaterialVerId,a.Code,a.Name,a.Spec,a.IsEffect,a.IsFrozen,a.IsBlankOut,a.Weight,a.BOMUnit,a.ArtificialCost,a.VerCode FROM dbo.MAT_MaterialVersion a --WHERE a.IsEffect=1
),
Relations AS--料品关系
(
SELECT a.RelationId,a.ParentVerId,a.ChildVerId,a.ChildCount,a.Radix,a.Waste,a.AssemblyPlace,a.Remark,a.DisplaySeq,a.ParentBasetId,a.ChildBasetId FROM dbo.MAT_MaterialRelation a 
),
MainMaterials AS--展出BOM
(
SELECT a.MaterialVerId,b.ParentVerId,b.ChildVerId,0 ComponentType,b.Radix,b.ChildCount,b.AssemblyPlace,b.Remark,b.Waste,b.DisplaySeq
,1 Level,FORMAT(ROW_NUMBER()OVER(ORDER BY b.DisplaySeq),'####') shunxu 
FROM data1 a INNER JOIN Relations b ON a.MaterialVerId=b.ParentVerId 
WHERE a.MaterialVerId=@MaterialVerId
AND a.IsEffect=1
UNION ALL
SELECT 
a.MaterialVerId,b.ParentVerId,b.ChildVerId,0 ComponentType,b.Radix,b.ChildCount,b.AssemblyPlace,b.Remark,b.Waste,a.DisplaySeq,a.Level+1 Level,a.shunxu+'.'+FORMAT(ROW_NUMBER()OVER(ORDER BY b.DisplaySeq),'####')shunxu
FROM MainMaterials a INNER JOIN Relations b ON a.ChildVerId=b.ParentVerId
),
SubMaterials AS--替代料列表
(
SELECT a.MaterialVerId,a.ParentVerId,b.TargetVerId ChildVerID,1 ComponentType,b.Radix,b.ChildCount,b.AssemblyPlace,b.Remark,b.Waste,b.DisplaySeq,a.Level,a.shunxu
FROM MainMaterials a INNER JOIN dbo.MAT_Substitute b ON a.ParentVerId=b.ParentVerId AND a.ChildVerId=b.SourceVerId
),
ExtendData AS
(
SELECT e.ObjectId,e.PropertyValue,es.ExtendName FROM dbo.MAT_Extend e INNER JOIN dbo.PS_ExtendSettings es ON e.SettingsId=es.SettingsId AND es.ExtendName='品牌/型号'
),
Result AS
(
SELECT * FROM MainMaterials a
UNION ALL 
SELECT * FROM SubMaterials a
)
--INSERT INTO TempTable0906
SELECT a.*,CASE WHEN a.IsFrozen=0 THEN '否' ELSE '是' END IsFrozenName,b.Content--,e.PropertyValue
,e.ExtendName
--,CASE WHEN CHARINDEX('/',e.PropertyValue)>0 THEN '否' ELSE '是' END IsOnlyOne
,STUFF((SELECT '/'+t.Name FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH('')),1,1,'')
PropertyValue
,CASE WHEN PATINDEX('30701%',a.Code)>0 OR PATINDEX('30801%',a.Code)>0 THEN '否'
WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>1
THEN '否' ELSE '是' END IsOnlyOne
,CASE WHEN a.ComponentType=0 THEN a.shunxu ELSE a.shunxu+dbo.fun_NumberToChars(a.DisplaySeq)END  RN
FROM (
SELECT a.MaterialVerId ID,NULL ParentVerId,a.MaterialVerId,a.Code,a.Name,a.Spec,NULL ComponentType,NULL ChildCount,NULL Radix,a.VerCode,a.ArtificialCost,a.Weight
,a.BOMUnit,NULL Waste,NULL AssemblyPlace,NULL Remark,a.IsEffect,a.IsFrozen,a.IsBlankOut,'0' shunxu,NULL DisplaySeq  
FROM dbo.MAT_MaterialVersion a WHERE a.IsEffect=1 AND a.MaterialVerId=@MaterialVerId
UNION ALL 
SELECT a.MaterialVerId ID,a.ParentVerId,m.MaterialVerId,m.Code,m.Name,m.Spec,a.ComponentType,a.ChildCount,a.Radix,m.VerCode,m.ArtificialCost,m.Weight
,m.BOMUnit,a.Waste,a.AssemblyPlace,a.Remark,m.IsEffect,m.IsFrozen,m.IsBlankOut
,a.shunxu
,a.DisplaySeq
FROM Result a
LEFT JOIN dbo.MAT_MaterialVersion m ON a.ChildVerId=m.MaterialVerId
) a  LEFT JOIN PS_BaseData b ON a.BOMUnit=b.DataId
LEFT JOIN ExtendData e ON a.MaterialVerId=e.ObjectId
ORDER BY  a.ID, dbo.fun_SplitAndConnectStr(a.shunxu),a.ComponentType,a.DisplaySeq
	FETCH NEXT FROM cc INTO @MaterialVerId

END 
CLOSE cc
DEALLOCATE cc

