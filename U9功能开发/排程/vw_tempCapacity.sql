ALTER  VIEW vw_tempCapacity
as
 --生产周期：固定提前期+（数量/批次数量）*变动提前期
 with  Items as (
 select a1.Org, Code,Name,SPECS,a2.FixedLT,a2.LTBatch,VarietyLT 
 ,a1.DescFlexField_PrivateDescSeg11 标准总工时
,a1.DescFlexField_PrivateDescSeg18  工序UPPH
  ,ceiling(convert(decimal(18,4),isnull(a1.DescFlexField_PrivateDescSeg18,0))*11
  * (case a1.DescFlexField_PrivateDescSeg22 
   when 'MRP100' then  10
   when 'MRP101' then  11
   when 'MRP107' then  7
   when 'MRP114' then  7
   when 'MRP115' then  3   
   when 'MRP116' then  7
 end))   批量
  ,(case a1.DescFlexField_PrivateDescSeg22 
   when 'MRP100' then  10
   when 'MRP101' then  11
   when 'MRP107' then  7
   when 'MRP114' then  7
   when 'MRP115' then  3   
   when 'MRP116' then  7
 end)   资源人数
  ,(case a1.DescFlexField_PrivateDescSeg22 
   when 'MRP100' then  '包装'
   when 'MRP101' then  '组装'
   when 'MRP102' then  '整机委外'
   when 'MRP103' then  '对讲机SMT委外'
   when 'MRP104' then  '电子'
   when 'MRP105' then  '包材'
   when 'MRP106' then  '结构'
   when 'MRP107' then  '前加工'
   when 'MRP108' then  '低值易耗品'
   when 'MRP109' then  '软件'
   when 'MRP111' then  '生产辅料'
   when 'MRP112' then  '客供料'
   when 'MRP113' then  '配件'  
   when 'MRP114' then  '委外材料'  
   when 'MRP115' then  '功放'  
   when 'MRP116' then  '后焊'  
   when 'MRP117' then  '功放SMT委外'  
   when 'MRP118' then  '软件烧录'  
   when 'MRP119' then  '前加工委外'  
 end)   MRP分类
 from   cbo_itemMaster a1
LEFT join  CBO_MrpInfo a2 on a1.id=a2.ItemMaster  
where  a1.ItemFormAttribute=10 and a1.Effective_IsEffective=1
and  org=1001708020135665
and  a1.DescFlexField_PrivateDescSeg18 !=''
and   a1.DescFlexField_PrivateDescSeg22  in ('MRP100','MRP101','MRP107','MRP114','MRP115','MRP116')
 )
 select *     from Items a

 
  
 
  