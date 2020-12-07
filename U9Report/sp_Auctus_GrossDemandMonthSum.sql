
/*
毛需求按月汇总
*/
ALTER PROC [dbo].[sp_Auctus_GrossDemandMonthSum]
AS
BEGIN

--DROP TABLE #tempMonth
--;
--WITH MonthData AS
--(
--SELECT DISTINCT  FORMAT(DemandDate ,'yyyy-MM')DemandDate 
-- from  MRP_DSInfo  a1
--  inner  join cbo_ItemMaster a2 on a2.ID=a1.Item
--  where  a1.DSType=0  and a1.Org=1001708020135665
--   and  exists (select 1  from MRP_PlanVersion where id=a1.PlanVersion
--       and  PlanName    in (1001905310034916,1001905311704957))
--  and  DATEDIFF(day,getdate(),  DemandDate) <=56
--  and   a2.Code   not like '1%'
--  )
--  SELECT *,'W'+CONVERT(VARCHAR(10),ROW_NUMBER()OVER(ORDER BY MonthData.DemandDate))RN
--  INTO #tempMonth
--  FROM MonthData

;
WITH  t as
(
SELECT   a1.Org,a2.Code,a2.Name
,a2.SPECS --[规格]
,(case a2.DescFlexField_PrivateDescSeg22
 when 'MRP100' then '内部生产'
 when 'MRP101' then 'SMT委外'
 when 'MRP103' then '马来西亚'
 when 'MRP104' then '电子'
 when 'MRP105' then '包材'
 when 'MRP106' then '结构'
 when 'MRP107' then '结构委外'
 when 'MRP108' then '低值易耗品'
 when 'MRP109' then '软件'
 when 'MRP112' then '客供料'
 when 'MRP111' then '生产辅料'
 when 'MRP113' then '配件'
 when 'MRP114' then '委外材料'
 ELSE a2.DescFlexField_PrivateDescSeg22  end) MRPCategory--分类  
 ,(isnull(BeforeAdjustSMQty,0)) ReqQtyTotal
 ,FORMAT(DemandDate ,'yyyy-MM')DemandDate 
 ,(select p2.name  from  CBO_Operators p1
  inner join  CBO_Operators_trl p2 on p1.id=p2.id   where p1.code=a2.DescFlexField_PrivateDescSeg23)  Buyer--执行采购员
 ,(select p2.name  from  CBO_Operators p1
  inner join  CBO_Operators_trl p2 on p1.id=p2.id   where p1.code=a2.DescFlexField_PrivateDescSeg24)  MCName--MC责任人
 from  MRP_DSInfo  a1
  inner  join cbo_ItemMaster a2 on a2.ID=a1.Item
  where  a1.DSType=0  and a1.Org=1001708020135665
   and  exists (select 1  from MRP_PlanVersion where id=a1.PlanVersion
       and  PlanName    in (1001905310034916,1001905311704957))
  and  DATEDIFF(day,getdate(),  DemandDate) <=56
  and   a2.Code   not like '1%'
  ),Result AS
  (
  SELECT t.Code,t.Name,t.SPECS,t.MRPCategory,t.DemandDate,t.Buyer,t.MCName,SUM(CONVERT(INT,t.ReqQtyTotal))ReqQtyTotal
  FROM  t GROUP BY t.org,t.Code,t.Name,t.SPECS,t.MRPCategory,t.DemandDate,t.Buyer,t.MCName
  )
  SELECT *
  FROM Result a --WHERE a.code='333040031'
  ORDER BY a.DemandDate,a.Code
 END 