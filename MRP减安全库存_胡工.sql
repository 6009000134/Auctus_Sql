
SET NOCOUNT ON 
DECLARE @Org BIGINT
SET @Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
DECLARE @n INT
DECLARE @BackUpVersion TABLE(PID BIGINT,PlanCode NVARCHAR(50),EndTime DATETIME,EndTime2 DATETIME,RN INT)
DECLARE @Date DATETIME=GETDATE()

INSERT INTO @BackUpVersion
SELECT a.ID PID,b.PlanCode,ISNULL(a.EndTime,c.EndTime)EndTime,c.EndTime EndTime2,ISNULL(c.RN,0)RN
FROM dbo.MRP_PlanVersion a LEFT JOIN dbo.MRP_PlanName b ON a.PlanName=b.ID 
LEFT JOIN (SELECT a.PlanVersion,MAX(a.EndTime)EndTime,MAX(a.RN)RN FROM dbo.Auctus_MRP_DSInfo a GROUP BY a.PlanVersion) c ON a.ID=c.PlanVersion
WHERE b.Org=@Org
AND ISNULL(a.EndTime,c.EndTime)<>ISNULL(c.EndTime,GETDATE())
SELECT @n=COUNT(*) FROM @BackUpVersion
IF @n=0 --没有跑新的MRP需求
RETURN;
-----------
--跑了新的MRP需求
--备份新的MRP供需数据


--将异常数据插入到异常数据填报表
;
WITH DSInfo AS
(
SELECT  o1.Name Company,p2.PlanCode,p1.Version,a1.Item,item.Code,item.Name,item.SPECS,a1.DocNo
,(select code from UBF_Sys_ExtEnumValue where  ExtEnumType=1001101157664810  and  EValue=a1.DemandCode) DemandCode
,dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.DSCodeEnum',a1.DSType,'zh-cn') DSType
,dbo.F_GetEnumName('UFIDA.U9.MRP.Enums.DSInfoDocTypeEnum',a1.DocType,'zh-cn') DocType,a1.DemandDate
,(case a1.DSType when 0 then  a1.NetQty*-1 else  a1.NetQty end) NetQty 
,a1.TradeBaseQty,b.EndTime,b.RN+1 RN
  from MRP_DSInfo  a1   ---0  需求  1 供应    
INNER  JOIN   MRP_PlanVersion p1 on  a1.PlanVersion=p1.id
INNER  JOIN   MRP_PlanName    p2 on  p1.PlanName =p2.id  
INNER  JOIN   CBO_ItemMaster  item on item.id=a1.item
INNER JOIN @BackUpVersion b ON a1.PlanVersion=b.PID
INNER JOIN dbo.Base_Organization o ON a1.Org=o.ID INNER JOIN dbo.Base_Organization_Trl o1 ON o.ID=o1.ID
where  --p2.PlanCode='00-MPS-6' and  
p2.org=1001708020135665
AND a1.DemandDate<DATEADD(DAY,56,GETDATE())
--and  item.code='202010633' 
--and  item.code='202010350' 
--AND a1.NetQty>0
AND a1.NetQty<>0
AND o1.SysMLFlag='zh-cn'
),
Result AS
(
SELECT a.Code,a.Item,a.PlanCode,SUM(a.NetQty)-MIN(c.SafetyStockQty)余量,MIN(c.SafetyStockQty)安全库存
FROM DSInfo a LEFT JOIN dbo.CBO_ItemMaster b ON a.Item=b.ID LEFT JOIN dbo.CBO_InventoryInfo c ON b.ID=c.ItemMaster
GROUP BY a.Item,a.Code,a.PlanCode
HAVING SUM(a.NetQty)-MIN(c.SafetyStockQty)>0--取供应>需求的
),
ResultInfo AS
(
SELECT b.* FROM Result a INNER JOIN DSInfo b ON a.item=b.Item AND a.PlanCode=b.PlanCode AND a.Code=b.Code
)
SELECT a.*,c.SafetyStockQty FROM ResultInfo a LEFT JOIN dbo.CBO_ItemMaster b ON a.Item=b.ID LEFT JOIN dbo.CBO_InventoryInfo c ON b.ID=c.ItemMaster ORDER BY a.NetQty
--SELECT a.PlanCode,b.Code,b.Name,a.余量 FROM Result a LEFT JOIN dbo.CBO_ItemMaster b ON a.Item=b.ID


