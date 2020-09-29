/*
同步U9工单
*/
ALTER PROCEDURE [dbo].[sp_GetU9MO]
(
@pageSize INT,
@pageIndex INT,
@DocNo VARCHAR(50),
@ERPSo VARCHAR(50)
)
AS
BEGIN
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
SET @DocNo='%'+ISNULL(@DocNo,'')+'%'
SET @ERPSo='%'+ISNULL(@ERPSo,'')+'%'
DECLARE @endIndex INT=@pageSize*@pageIndex+1
--获取U9数据
SELECT * FROM (
SELECT *,ROW_NUMBER()OVER(ORDER BY t.IsWorkOrder,t.IsCode DESC ,t.IsERPSO DESC ,t.DocNo desc) RN
FROM (
SELECT a.DocNo,a.MaterialID,a.MaterialCode,a.MaterialName,a.ProductQty,a.ERPSO
,a.ERPQuantity,a.CustomerOrder
,CASE WHEN a.DocNo=ISNULL(b.WorkOrder,'')AND a.ERPSO<>ISNULL(b.ERPSO,'') THEN 1 ELSE 0 END  IsERPSO
,CASE WHEN a.DocNo=ISNULL(b.WorkOrder,'')AND a.CustomerOrder<>ISNULL(b.CustomerOrder,'') THEN 1 ELSE 0 END IsCustomerOrder
,CASE WHEN a.DocNo=ISNULL(b.WorkOrder,'')AND a.ERPQuantity<>ISNULL(b.ERPQuantity,0) THEN 1 ELSE 0 END IsERPQuantity
,CASE WHEN a.DocNo=ISNULL(b.WorkOrder,'')AND a.ProductQty<>ISNULL(b.Quantity,0) THEN 1 ELSE 0 END IsQuantity
,CASE WHEN ISNULL(a.MaterialID,0) =0 THEN 2
WHEN (a.DocNo=ISNULL(b.WorkOrder,'')AND a.MaterialCode<>ISNULL(b.MaterialCode,''))THEN 1 
ELSE 0 END IsCode
,CASE WHEN a.DocNo=ISNULL(b.WorkOrder,'')THEN 1 ELSE 0 END IsWorkOrder
--,ROW_NUMBER() OVER(ORDER BY a.DocNo desc)RN
,ISNULL(a.Address1,'')Address1,ISNULL(a.Country,'') Country
,a.SendPlaceCode,a.SendPlace,a.Department
,a.CustomerItemName
FROM mxqh_U9MO a LEFT JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.DocNo=b.WorkOrder
WHERE  PATINDEX(@DocNo,a.DocNo)>0
AND PATINDEX(@ERPSo,ISNULL(a.ERPSO,''))>0
) t)t WHERE t.RN>@beginIndex AND t.RN<@endIndex


--计算记录总数
SELECT COUNT(1)Count FROM  mxqh_U9MO a
WHERE PATINDEX(@DocNo,a.DocNo)>0
AND PATINDEX(@ERPSo,ISNULL(a.ERPSO,''))>0

END

