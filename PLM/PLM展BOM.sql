/*
PLM展BOM
*/
ALTER PROC [dbo].[sp_Auctus_ExpandBom]
(
@MaterialVerId VARCHAR(50)
)
AS
BEGIN

--DECLARE @BomCode VARCHAR(100)='102020015'
--DECLARE @BomCode VARCHAR(100)='202010656'
--DECLARE @BomCode VARCHAR(100)='309010013' 
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
SELECT b.ParentVerId,b.ChildVerId,0 ComponentType,b.Radix,b.ChildCount,b.AssemblyPlace,b.Remark,b.Waste,b.DisplaySeq
,1 Level,FORMAT(ROW_NUMBER()OVER(ORDER BY b.DisplaySeq),'####') shunxu 
FROM data1 a INNER JOIN Relations b ON a.MaterialVerId=b.ParentVerId 
WHERE a.MaterialVerId=@MaterialVerId AND a.IsEffect=1
UNION ALL
SELECT 
b.ParentVerId,b.ChildVerId,0 ComponentType,b.Radix,b.ChildCount,b.AssemblyPlace,b.Remark,b.Waste,a.DisplaySeq,a.Level+1 Level,a.shunxu+'.'+FORMAT(ROW_NUMBER()OVER(ORDER BY b.DisplaySeq),'####')shunxu
FROM MainMaterials a INNER JOIN Relations b ON a.ChildVerId=b.ParentVerId
),
SubMaterials AS--替代料列表
(
SELECT a.ParentVerId,b.TargetVerId ChildVerID,1 ComponentType,b.Radix,b.ChildCount,b.AssemblyPlace,b.Remark,b.Waste,b.DisplaySeq,a.Level,a.shunxu
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
SELECT a.*,b.Content--,e.PropertyValue,e.ExtendName
--,CASE WHEN CHARINDEX('/',e.PropertyValue)>0 THEN '否' ELSE '是' END IsOnlyOne
,(SELECT t.Name+'/' FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId FOR XML PATH(''))
PropertyValue
,CASE WHEN (SELECT COUNT(1) FROM dbo.MAT_Brands t INNER JOIN dbo.MAT_BrandsMaterialRelation t1 ON t.BrandsId=t1.BrandsId AND ISNULL(t1.ParentVerId,'')='' AND t1.MaterialVerId=a.MaterialVerId)>0
THEN '否' ELSE '是' END IsOnlyOne
,CASE WHEN a.ComponentType=0 THEN a.shunxu ELSE a.shunxu+dbo.fun_NumberToChars(a.DisplaySeq)END  RN
FROM (
SELECT NULL ParentVerId,a.MaterialVerId,a.Code,a.Name,a.Spec,NULL ComponentType,NULL ChildCount,NULL Radix,a.VerCode,a.ArtificialCost,a.Weight
,a.BOMUnit,NULL Waste,NULL AssemblyPlace,NULL Remark,a.IsEffect,a.IsFrozen,a.IsBlankOut,'0' shunxu,NULL DisplaySeq  FROM dbo.MAT_MaterialVersion a WHERE a.IsEffect=1 AND a.MaterialVerId=@MaterialVerId
UNION ALL 
SELECT a.ParentVerId,m.MaterialVerId,m.Code,m.Name,m.Spec,a.ComponentType,a.ChildCount,a.Radix,m.VerCode,m.ArtificialCost,m.Weight
,m.BOMUnit,a.Waste,a.AssemblyPlace,a.Remark,m.IsEffect,m.IsFrozen,m.IsBlankOut
,a.shunxu
,a.DisplaySeq
FROM Result a
LEFT JOIN dbo.MAT_MaterialVersion m ON a.ChildVerId=m.MaterialVerId
) a  LEFT JOIN PS_BaseData b ON a.BOMUnit=b.DataId
--LEFT JOIN ExtendData e ON a.MaterialVerId=e.ObjectId
ORDER BY    dbo.fun_SplitAndConnectStr(a.shunxu),a.ComponentType,a.DisplaySeq



END 