
/*
获取模具信息（用于模具变更功能）
*/
ALTER PROC [dbo].[sp_GetMouldDetailByCode]
(
@Code VARCHAR(100)
)
AS
BEGIN
SELECT 
a.ID,a.CreateBy 
,a.CreateDate 
,a.HoleNum 
,a.Code 
,a.Name 
,a.SPECS 
,a.TotalNum
,a.DailyCapacity 
,a.DailyNum 
,a.RemainNum 
,a.Holder 
,a.Manufacturer 
,a.CycleTime 
,a.DealDate 
,a.ProductWeight 
,a.NozzleWeight 
,a.EffectiveDate 
,a.Remark 
FROM dbo.Mould a
WHERE a.Deleted=0 
AND a.Code=@Code
--SELECT 
--a.ID,a.CreateBy 创建人
--,a.CreateDate 创建日期
--,a.HoleNum 穴数
--,a.Code 模具料号
--,a.Name 模具名称
--,a.SPECS 模具规格
--,a.TotalNum '总次数(K)'
--,a.DailyCapacity 日产能
--,a.DailyNum 日模次
--,a.RemainNum 剩余模次
--,a.Holder 使用委外商
--,a.Manufacturer 制造厂商
--,a.CycleTime '成型周期(s)'
--,a.DealDate 购买日期
--,a.ProductWeight '产品重量(g)'
--,a.NozzleWeight '水口重量(g)'
--,a.EffectiveDate 启用日期
--,a.Remark 备注
--FROM dbo.Mould a
--WHERE a.Deleted=0 
--AND a.Code=@Code
--SELECT * FROM dbo.Mould

END 
