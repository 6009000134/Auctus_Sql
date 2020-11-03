
ALTER PROCEDURE [dbo].[sp_GetPlanDetailList]
(
@PageSize INT,
@PageIndex INT,
@DocNo VARCHAR(50),
@MaterialID INT,
@LineID INT,
@AssemblyDate VARCHAR(10),
@Status INT,
@CustomerOrder VARCHAR(100),
@ERPSo VARCHAR(100),
@IsCanceled BIT
)
AS
BEGIN
	--DECLARE @PageSize INT=100,@PageIndex INT=1,@DocNo VARCHAR(50),@LineID INT
	--,@AssemblyDate VARCHAR(10)='',@CustomerOrder varchar(100),@ERPSo varchar(100)
	--,@MaterialID VARCHAR(100),@Status INT
	DECLARE @beginIndex INT=(@PageIndex-1)*@PageSize
	DECLARE @endIndex INT=@PageIndex*@PageSize+1
	--设置DocNo进行模糊匹配
	SET @DocNo='%'+ISNULL(@DocNo,'')+'%'	
	SET @CustomerOrder='%'+ISNULL(@CustomerOrder,'')+'%'	
	SET @ERPSo='%'+ISNULL(@ERPSo,'')+'%'	
	
	DECLARE @sql NVARCHAR(MAX)
	SET @sql='
	SELECT * FROM (
	SELECT   a.ID,a.CreateBy,a.CreateDate,a.ModifyBy,a.ModifyDate,a.AssemblyPlanID,a.ListNo,a.WorkOrder,a.MaterialID,d.MaterialCode,d.MaterialName
,a.Quantity,a.OnlineTime,a.OfflineTime,a.CustomerOrder,a.DeliveryDate,a.CustomerID,a.CustomerCode,a.CustomerName,a.SendPlaceID,a.SendPlaceCode,a.SendPlaceName,a.Ispublish
,a.IsLock,a.Status,a.CompleteDate,a.ERPSO,a.ERPMO,a.ERPQuantity,a.ERPOrderNo,a.ERPOrderQty,a.IsUpload,a.boRoutingID,a.TbName,a.ClName,a.Remark,a.MinWeight,a.MaxWeight,a.TotalStartQty,a.U9_TotalCompleteQty,
a.CompleteType,a.CustomerItemName,a.IsCanceled,
        format(b.AssemblyDate,''yyyy-MM-dd'') AssemblyDate,
		b.AssemblyLineID,
        l.Name AssemblyLineName,
		c1.RouteName RoutingName ,
		d.ClName MaterialClName,
		d.CompleteType Mat_CompleteType,
        cc.OnLineQty,cc.CompleteQty,
				(SELECT COUNT(1) FROM dbo.baProductTemplate pt INNER JOIN dbo.baBarcodeType bt ON pt.TypeID=bt.ID
WHERE bt.TypeCode in (''SNCODE'',''COTTONCODE'') AND pt.ProductId=a.MaterialID AND pt.CustomAddr=a.SendPlaceID)TemplateCount,
		(SELECT 1 FROM dbo.opPackageMain WHERE AssemblyPlanDetailID=a.ID)IsPack'
		IF @IsCanceled='true'
	SET @sql=@sql+' ,ROW_NUMBER() OVER(ORDER BY a.ModifyDate Desc,b.AssemblyDate DESC,convert(bigint,a.ListNo) desc)RN'
	ELSE
	SET @sql=@sql+' ,ROW_NUMBER() OVER(ORDER BY a.IsCanceled desc,b.AssemblyDate DESC,convert(bigint,a.ListNo) desc)RN'
	
		
	SET @sql=@sql+' FROM    mxqh_plAssemblyPlanDetail AS a
        INNER JOIN mxqh_plAssemblyPlan AS b ON a.AssemblyPlanID = b.ID 
		LEFT join boRouteMate c on a.boRoutingID=c.ID LEFT JOIN dbo.boRoute c1 ON c.RouteId=c1.ID  LEFT JOIN dbo.baAssemblyLine l ON b.AssemblyLineID=l.ID
		INNER JOIN mxqh_Material d on a.MaterialID=d.ID
		left join (SELECT a.AssemblyPlanDetailID,SUM(ISNULL(a.InSum,a.HHInSum))OnLineQty,SUM(a.FinishSum)CompleteQty FROM dbo.mx_PlanExBackNumMain a
GROUP BY a.AssemblyPlanDetailID) cc on a.ID=cc.AssemblyPlanDetailID
	WHERE  1=1 '
	IF ISNULL(@LineID,0)<>0	
	SET @sql=@sql +'AND b.AssemblyLineID = @LineID '

	IF ISNULL(@MaterialID,0)<>0
	SET @sql=@sql+' AND a.MaterialID=@MaterialID'
	
	IF ISNULL(@DocNo,'')<>''
	SET @sql=@sql +' AND PATINDEX(@DocNo,a.WorkOrder)>0 '

	IF ISNULL(@AssemblyDate,'')<>''
	SET @sql=@sql +' AND PATINDEX(format(@AssemblyDate,''yyyy-MM-dd''),format(b.AssemblyDate,''yyyy-MM-dd''))>0 '        
	IF @IsCanceled='false'
	BEGIN 
		IF ISNULL(@Status,0)=4
		BEGIN
			SET @sql=@sql +' and a.status=@Status'
		END 
		ELSE
		BEGIN
			SET @sql=@sql+' and a.status<>4'
		END 
	END 
	IF ISNULL(@CustomerOrder,'')<>''
	SET @sql=@sql +' AND PATINDEX(@CustomerOrder,a.CustomerOrder)>0 '

	IF ISNULL(@ERPSo,'')<>''
	SET @sql=@sql +' AND PATINDEX(@ERPSo,a.ERPSo)>0 '

	IF @IsCanceled='true'
	SET @sql=@sql+' and isnull(a.IsCanceled,''0'')=''true'''
	ELSE
    SET @sql=@sql+' and isnull(a.IsCanceled,''0'')=''false'''
		
	SET @sql=@sql+' ) t WHERE t.RN>@beginIndex AND t.RN<@endIndex order by t.rn'
	
	EXEC sp_executesql  @sql,N'@LineID int,@DocNo varchar(50),@MaterialID int,@AssemblyDate date,@Status int,@CustomerOrder varchar(100),@ERPSo varchar(100),@beginIndex int,@endIndex int' ,@LineID,@DocNo,@MaterialID,@AssemblyDate,@Status,@CustomerOrder,@ERPSo,@beginIndex,@endIndex


	DECLARE @sqlTotal NVARCHAR(MAX)
	SET @sqlTotal='
	SELECT  count(1) TotalCount	
	FROM    mxqh_plAssemblyPlanDetail AS a
        INNER JOIN mxqh_plAssemblyPlan AS b ON a.AssemblyPlanID = b.ID
	WHERE  1=1 '
	IF ISNULL(@LineID,0)<>0	
	SET @sqlTotal=@sqlTotal +'AND b.AssemblyLineID = @LineID '

	IF ISNULL(@DocNo,'')<>''
	SET @sqlTotal=@sqlTotal +' AND PATINDEX(@DocNo,a.WorkOrder)>0 '

	IF ISNULL(@MaterialID,0)<>0
	SET @sqlTotal=@sqlTotal+' AND a.MaterialID=@MaterialID'

	IF ISNULL(@AssemblyDate,'')<>''
	SET @sqlTotal=@sqlTotal +' AND PATINDEX(format(@AssemblyDate,''yyyy-MM-dd''),format(b.AssemblyDate,''yyyy-MM-dd''))>0 '        		
	
	
	IF ISNULL(@IsCanceled,'false')='false'
	BEGIN    
		IF ISNULL(@Status,0)=4
		BEGIN
			SET @sqlTotal=@sqlTotal +' and a.status=@Status'
		END 
		ELSE
		BEGIN
			SET @sqlTotal=@sqlTotal+' and a.status<>4'
		END 
	END 

	IF ISNULL(@CustomerOrder,'')<>''
	SET @sqlTotal=@sqlTotal +' AND PATINDEX(@CustomerOrder,a.CustomerOrder)>0 '

	IF ISNULL(@ERPSo,'')<>''
	SET @sqlTotal=@sqlTotal +' AND PATINDEX(@ERPSo,a.ERPSo)>0 '
	
	IF @IsCanceled='true'
	SET @sqlTotal=@sqlTotal+' and isnull(a.IsCanceled,''0'')=''true'''
	ELSE
    SET @sqlTotal=@sqlTotal+' and isnull(a.IsCanceled,''0'')=''false'''
		
	EXEC sp_executesql  @sqlTotal,N'@LineID int,@DocNo varchar(50),@MaterialID int,@AssemblyDate date,@Status int,@CustomerOrder varchar(100),@ERPSo varchar(100)' ,@LineID,@DocNo,@MaterialID,@AssemblyDate,@Status,@CustomerOrder,@ERPSo
	PRINT @sqlTotal
	SELECT @LineID,@DocNo,@AssemblyDate

END