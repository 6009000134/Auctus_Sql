BEGIN
	
	DECLARE @PageSize INT=10,@PageIndex INT=1,@MaterialID INT,@DocNo VARCHAR(50),@LineID INT,@AssemblyDate VARCHAR(10)='',@Status INT
	DECLARE @beginIndex INT=(@PageIndex-1)*@PageSize
	DECLARE @endIndex INT=@PageIndex*@PageSize+1
	--设置DocNo进行模糊匹配
	SET @DocNo='%'+@DocNo+'%'	
	
	DECLARE @sql NVARCHAR(MAX)
	SET @sql='
	SELECT * FROM (
	SELECT  a.* ,
        format(b.AssemblyDate,''yyyy-MM-dd'') AssemblyDate,
		b.AssemblyLineID,
        l.Name AssemblyLineName,
		c.RoutingName ,
		d.ClName MaterialClName,
        ( SELECT    COUNT(1)
          FROM      opPlanExecutMain
          WHERE     AssemblyPlanDetailID = a.ID
        ) AS OnlineQty ,--投入数量
        ( SELECT    COUNT(1)
          FROM      dbo.opPackageChild AS a1--包装子表
                    INNER JOIN opPackageDetail AS b1 ON a1.PackDetailID = b1.ID--包装详情表
                    INNER JOIN opPackageMain AS c1 ON b1.PackMainID = c1.ID--包装主表
          WHERE     c1.AssemblyPlanDetailID = a.ID
        ) AS FinishQty,--完工数量
		(SELECT COUNT(1) FROM dbo.baProductTemplate pt INNER JOIN dbo.baBarcodeType bt ON pt.TypeID=bt.ID
WHERE bt.TypeCode=''SNCODE'' AND pt.ProductId=a.MaterialID AND pt.CustomAddr=a.SendPlaceID)TemplateCount,
		(SELECT 1 FROM dbo.opPackageMain WHERE AssemblyPlanDetailID=a.ID)IsPack,
		ROW_NUMBER() OVER(ORDER BY b.AssemblyDate DESC,a.ListNo desc)RN
	FROM    mxqh_plAssemblyPlanDetail AS a
        INNER JOIN mxqh_plAssemblyPlan AS b ON a.AssemblyPlanID = b.ID left join boRouting c on a.boRoutingID=c.ID LEFT JOIN dbo.baAssemblyLine l ON b.AssemblyLineID=l.ID
		INNER JOIN mxqh_Material d on a.MaterialID=d.ID
	WHERE  1=1 '
	IF ISNULL(@LineID,0)<>0	
	SET @sql=@sql +'AND b.AssemblyLineID = @LineID '

	IF ISNULL(@MaterialID,0)<>0
	SET @sql=@sql+' AND a.MaterialID=@MaterialID'
	
	IF ISNULL(@DocNo,'')<>''
	SET @sql=@sql +' AND PATINDEX(@DocNo,a.WorkOrder)>0 '

	IF ISNULL(@AssemblyDate,'')<>''
	SET @sql=@sql +' AND PATINDEX(format(@AssemblyDate,''yyyy-MM-dd''),format(b.AssemblyDate,''yyyy-MM-dd''))>0 '        
	
	IF ISNULL(@Status,0)=4
	BEGIN
		SET @sql=@sql +' and a.status=@Status'
	END 
	ELSE
    BEGIN
		SET @sql=@sql+' and a.status<>4'
	END 
	

		
	SET @sql=@sql+' ) t WHERE t.RN>@beginIndex AND t.RN<@endIndex order by t.rn'
	EXEC sp_executesql  @sql,N'@LineID int,@DocNo varchar(50),@MaterialID int,@AssemblyDate date,@Status int,@beginIndex int,@endIndex int' ,@LineID,@DocNo,@MaterialID,@AssemblyDate,@Status,@beginIndex,@endIndex


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
	
	

	IF ISNULL(@Status,0)=4
	BEGIN
		SET @sqlTotal=@sqlTotal +' and a.status=@Status'
	END 
	ELSE
    BEGIN
		SET @sqlTotal=@sqlTotal+' and a.status<>4'
	END 
	
	EXEC sp_executesql  @sqlTotal,N'@LineID int,@DocNo varchar(50),@MaterialID int,@AssemblyDate date,@Status int' ,@LineID,@DocNo,@MaterialID,@AssemblyDate,@Status

	SELECT @LineID,@DocNo,@AssemblyDate

END 



