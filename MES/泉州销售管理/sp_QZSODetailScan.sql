/*
泉州销售明细
*/
ALTER  PROC [dbo].[sp_QZSODetailScan]
(
--DECLARE 
@BSN VARCHAR(50),@CreateBy VARCHAR(50),@SOID INT,@size INT,@index INT
,@IsForce BIT
)
AS
BEGIN
DECLARE @beginIndex INT=@size*(@index-1)
DECLARE @endIndex INT=@size*@index+1

DECLARE @status INT=(SELECT status FROM dbo.qz_SO a WHERE a.ID=@SOID)
IF @status=1
BEGIN
	
	SELECT '0' MsgType,'订单已完成，不允许继续录入！'Msg
	RETURN;
END 



--SN列表
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TBSN') AND TYPE='U')
BEGIN
	DROP TABLE #TBSN;
END
SELECT TOP 0 BSN,PackageNO INTO #TBSN FROM dbo.qz_SODetail;


--判断是否为箱号
DECLARE @IsPack INT=0
SELECT @IsPack=ISNULL(COUNT(1),0) FROM dbo.qz_SaleDeliverDtl a WHERE a.PackageNO=@BSN

--获取BSN出货信息
IF	@IsPack>0
BEGIN--扫描的是箱号
	INSERT INTO #TBSN
	        ( BSN, PackageNO )SELECT a.BSN,a.PackageNO FROM dbo.qz_SaleDeliverDtl a WHERE a.PackageNO=@BSN
END 
ELSE
BEGIN--扫描的是BSN
	INSERT INTO #TBSN
	        ( BSN, PackageNO )SELECT a.BSN,a.PackageNO FROM dbo.qz_SaleDeliverDtl a WHERE a.BSN=@BSN
END 

		

--判断BSN是否存在
IF EXISTS(SELECT 1 FROM #TBSN)
BEGIN
	--判断是在本订单扫过
	IF	EXISTS(SELECT 1 FROM #TBSN a INNER JOIN dbo.qz_SODetail b ON a.BSN=b.BSN AND b.SOID=@SOID)
	BEGIN--已在销售单扫码过
		SELECT '0'MsgType,STUFF((SELECT ',['+a.BSN+']已在本订单扫过' FROM #TBSN a INNER JOIN dbo.qz_SODetail b ON a.BSN=b.BSN AND b.SOID=@SOID FOR XML PATH ('')),1,2,'')Msg				
		RETURN;
	END 
	--判断是否已经销售过
	IF	EXISTS(SELECT 1 FROM #TBSN a INNER JOIN dbo.qz_SODetail b ON a.BSN=b.BSN AND b.SOID<>@SOID)
	BEGIN--已在销售单扫码过
		SELECT '0'MsgType,STUFF((SELECT ',['+a.BSN+']在销售订单['+c.DocNo+']已扫过' FROM #TBSN a INNER JOIN dbo.qz_SODetail b ON a.BSN=b.BSN INNER JOIN dbo.qz_SO c ON b.SOID=c.ID FOR XML PATH ('')),1,2,'')Msg				
		RETURN;
	END
	
	 
	--未在销售单扫码过
    BEGIN
		DECLARE @count INT=0--扫码后数量
		DECLARE @quantity INT=0--销售数量
		SELECT @count=COUNT(1) FROM 
		(
		SELECT a.BSN FROM dbo.qz_SODetail a WHERE a.SOID=@SOID 
		UNION
		SELECT a.BSN FROM #TBSN a LEFT JOIN dbo.qz_SODetail b ON a.BSN=b.BSN
		WHERE ISNULL(b.BSN,'')=''
		) t
			
		SELECT @quantity=a.Quantity FROM dbo.qz_SO a WHERE a.ID=@SOID


			
		IF @IsForce=0
		BEGIN	
				IF @count=@quantity
				BEGIN
					SELECT '3'MsgType,'扫描数量等于订单销售数量，是否关闭订单？'Msg					
					--RETURN;
				END 		
				ELSE IF @count>@quantity
				BEGIN
					SELECT '2'MsgType,'扫描数量大于订单销售数量，是否继续扫描并更新销售数量？'Msg					
					RETURN;
				END 
				ELSE
                BEGIN
					SELECT '1'MsgType,'箱号/编码'+'['+@BSN+']'+'扫码成功'Msg					
				END 
		END
		ELSE
        BEGIN
			IF @count>=@quantity
			BEGIN
				SELECT '4'MsgType,'箱号/编码'+'['+@BSN+']'+'扫码成功'Msg            
			END 
			ELSE
			BEGIN
				SELECT '1'MsgType,'箱号/编码'+'['+@BSN+']'+'扫码成功'Msg
			END
		END 
				INSERT INTO dbo.qz_SODetail
		        ( CreateBy ,
		          CreateDate ,
		          SOID ,
		          PackageNO ,
		          BSN 		          
		        )
		SELECT @CreateBy,GETDATE(),@SOID,a.PackageNO,a.BSN FROM #TBSN a		

		

		SELECT *FROM (
		SELECT a.BSN,a.PackageNO,ROW_NUMBER() OVER(ORDER BY a.ID DESC)RN FROM dbo.qz_SODetail a WHERE a.SOID=@SOID
		)t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT COUNT(1)Count,@count HavePackQty,MIN(b.Quantity)Quantity  FROM dbo.qz_SODetail a INNER JOIN dbo.qz_SO b ON a.SOID=b.ID WHERE a.SOID=@SOID
	END 
END
ELSE
BEGIN
	SELECT '0'MsgType,'编码/箱号'+'['+@BSN+']'+'不存在出货记录！' Msg
END  


END 

