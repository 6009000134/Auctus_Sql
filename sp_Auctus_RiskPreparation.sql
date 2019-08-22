--风险备料报表
/*
逻辑：
1）按条件提取风险备料单物料明细；
2）根据风险备料明细中的物料匹配最新BOM，提取采购处理提前期大于24天的物料；
3）按BOM的用量汇总计算物料需求量 
 参考公式：
 需求数量=进位（数量/母件底数量*用量）  
 需求数量=进位（向上取整（数量/母件底数量）*用量） ---BOM中选择了取整
*/
ALTER PROC sp_Auctus_RiskPreparation
(
@Org BIGINT,
@DocNo VARCHAR(50),--风险备料单号
@Code VARCHAR(50),--整机料号
@SD DATE,--开始时间 与交期比较
@ED DATE--结束时间
)
AS
BEGIN

--DECLARE @DocNo VARCHAR(50)
--DECLARE @Code VARCHAR(50)
--DECLARE @SD DATE,@ED DATE
--DECLARE @Org BIGINT=1001708020135665
--SET @SD='2019-6-1'
--SET @ED='2019-6-30'
IF ISNULL(@SD,'')=''
SET @SD='2000-01-01'
IF ISNULL(@ED,'')=''
SET @ED='9999-01-01'
SET @ED=DATEADD(DAY,1,@ED)
SET @Code='%'+ISNULL(@Code,'')+'%'
SET @DocNo='%'+ISNULL(@DocNo,'')+'%'

 IF object_id('tempdb.dbo.#tempDefineValue') is NULL
 CREATE TABLE #tempDefineValue(Code VARCHAR(50),Name NVARCHAR(255),Type VARCHAR(50))
 ELSE
 TRUNCATE TABLE #tempDefineValue
 --MRP分类值集
 INSERT INTO #tempDefineValue
         ( Code, Name, Type )
SELECT T.Code,T.Name,'MRPCategory' FROM ( SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name], A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A2.[Code] as SysMlFlag
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='MRPCategory') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))) T WHERE T.rownum>  0 and T.rownum<= 130



SELECT --f.DocNo,a.DocLineNo,a.Code,a.Name,a.Qty,d.SumLT,
itemmaster.Code 料号,itemmaster.Name 品名,itemmaster.SPECS 规格--,SUM(c.ThisUsageQty)ThisUsageQty,SUM(a.Qty)Qty
,SUM(a.Qty*c.ThisUsageQty) 需求数量,a.DeliveryDate 交期,MIN(d.SumLT) 采购周期
,op1.Name 开发采购,op21.Name 执行采购,op31.Name MC责任人,MRP.Name MRP分类
FROM dbo.Auctus_ForecastLine a INNER JOIN dbo.Auctus_Forecast f ON a.Forecast=f.ID INNER JOIN dbo.CBO_BOMMaster b ON a.Itemmaster=b.ItemMaster AND b.Org=@Org
INNER JOIN dbo.Auctus_NewestBom c ON b.ID=c.MasterBom AND c.Org=@Org INNER JOIN dbo.CBO_MrpInfo d ON c.MID=d.ItemMaster
INNER JOIN dbo.CBO_ItemMaster itemmaster ON c.MID=itemmaster.ID AND itemmaster.ItemFormAttribute=9--采购件
LEFT JOIN dbo.CBO_Operators op ON itemmaster.DescFlexField_PrivateDescSeg6=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op2 ON itemmaster.DescFlexField_PrivateDescSeg23=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.ID AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_Operators op3 ON itemmaster.DescFlexField_PrivateDescSeg24=op3.Code LEFT JOIN dbo.CBO_Operators_Trl op31 ON op3.ID=op31.ID AND ISNULL(op31.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN #tempDefineValue MRP ON itemmaster.DescFlexField_PrivateDescSeg22=MRP.Code AND MRP.Type='MRPCategory'
WHERE ISNULL(d.SumLT,0)>24
AND a.DeliveryDate>=@SD AND a.DeliveryDate<@ED
AND PATINDEX(@DocNo,f.DocNo)>0
AND PATINDEX(@Code,a.Code)>0
AND c.ComponentType=0
GROUP BY itemmaster.Code,itemmaster.Name,itemmaster.SPECS,a.DeliveryDate,op1.Name,op21.Name,op31.Name,MRP.Name
ORDER BY itemmaster.Code

--SELECT --f.DocNo,a.DocLineNo,a.Code,a.Name,a.Qty,d.SumLT,
--itemmaster.Code,itemmaster.Name,itemmaster.SPECS,c.ThisUsageQty,a.Qty,a.Qty*c.ThisUsageQty 需求数量,a.DeliveryDate 交期,d.SumLT 采购周期
--,op1.Name 开发采购,op21.Name 执行采购,op31.Name MC责任人,MRP.Name MRP分类
--FROM dbo.Auctus_ForecastLine a INNER JOIN dbo.Auctus_Forecast f ON a.Forecast=f.ID INNER JOIN dbo.CBO_BOMMaster b ON a.Itemmaster=b.ItemMaster AND b.Org=1001708020135665
--INNER JOIN dbo.Auctus_NewestBom c ON b.ID=c.MasterBom AND c.Org=1001708020135665 INNER JOIN dbo.CBO_MrpInfo d ON c.MID=d.ItemMaster
--INNER JOIN dbo.CBO_ItemMaster itemmaster ON c.MID=itemmaster.ID AND itemmaster.ItemFormAttribute=9--采购件
--LEFT JOIN dbo.CBO_Operators op ON itemmaster.DescFlexField_PrivateDescSeg6=op.Code LEFT JOIN dbo.CBO_Operators_Trl op1 ON op.ID=op1.ID AND ISNULL(op1.SysMLFlag,'zh-cn')='zh-cn'
--LEFT JOIN dbo.CBO_Operators op2 ON itemmaster.DescFlexField_PrivateDescSeg23=op2.Code LEFT JOIN dbo.CBO_Operators_Trl op21 ON op2.ID=op21.ID AND ISNULL(op21.SysMLFlag,'zh-cn')='zh-cn'
--LEFT JOIN dbo.CBO_Operators op3 ON itemmaster.DescFlexField_PrivateDescSeg24=op3.Code LEFT JOIN dbo.CBO_Operators_Trl op31 ON op3.ID=op31.ID AND ISNULL(op31.SysMLFlag,'zh-cn')='zh-cn'
--LEFT JOIN #tempDefineValue MRP ON itemmaster.DescFlexField_PrivateDescSeg22=MRP.Code AND MRP.Type='MRPCategory'
--WHERE ISNULL(d.SumLT,0)>24
--AND a.DeliveryDate>=@SD AND a.DeliveryDate<@ED
--AND PATINDEX(@Code,a.Code)>0
--AND c.ComponentType=0
----GROUP BY itemmaster.Code,itemmaster.Name,itemmaster.SPECS,a.DeliveryDate,op1.Name,op21.Name,op31.Name,MRP.Name
--ORDER BY itemmaster.Code

END 