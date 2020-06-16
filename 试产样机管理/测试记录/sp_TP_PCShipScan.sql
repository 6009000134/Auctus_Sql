/*
产品中心出库记录扫码
*/
ALTER  PROC [dbo].[sp_TP_PCShipScan]
(
@pageIndex INT,
@pageSize INT,
@SNCode VARCHAR(100),
@ShipID INT,
@DocType VARCHAR(100),
@SoftUpdateDate DATE,
@Progress VARCHAR(10),--样机阶段
@Status VARCHAR(10),--样机状态
@Remark NVARCHAR(2000),
@CreateBy VARCHAR(100)
)
AS
BEGIN

	--DECLARE @SNCode VARCHAR(100)='123',@TestRecordID INT=3
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1	
	--IF @DocType='入库'--入库
	--BEGIN
	--	--判断是否测试过
	--	IF NOT EXISTS(SELECT 1 FROM dbo.TP_TestDetail a WHERE a.SNCode=@SNCode)
	--	BEGIN
	--		SELECT '0'MsgType,'样机无研发测试记录！'Msg
	--		RETURN;
	--	END 
	--END 
	--ELSE--归还
 --   BEGIN
	--	--判断是否已经归还过
	--	PRINT ''
	--END 
	--根据码查出内控码
	--根据码查出内控码	
	DECLARE @BSN VARCHAR(100),@SN VARCHAR(100)
	SELECT @BSN=ISNULL(a.InternalCode,''),@SN=ISNULL(a.SNCode,'') FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.SNCode,'')=@SNCode OR ISNULL(a.InternalCode,'')=@SNCode

	--判断SN码是否已经在本单扫描过
	IF EXISTS(SELECT 1 FROM dbo.TP_PCShipDetail a WHERE a.ShipID=@ShipID AND ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,'')))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
		RETURN;
	END 
	--TODO:
	--判断SN码当前是在库还是出库状态，出库则可以重新入库	
	IF EXISTS(SELECT 1 FROM dbo.TP_PCShipDetail a WHERE a.ShipID<>@ShipID AND ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,'')))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT a.DocNo FROM dbo.TP_PCShip a WHERE a.ID=@ShipID)+'单内扫描过！'Msg	
		RETURN;
	END 
	
	--判断当前BSN编码属于是否在库
	IF EXISTS(SELECT 1 FROM (
	SELECT t.*,ROW_NUMBER()OVER(ORDER BY t.CreateDate DESC)RN FROM (
	SELECT a.CreateDate,a.SNCode,1 IsRcv FROM dbo.TP_PCRcvDetail a 
	WHERE ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,''))
	UNION ALL
	SELECT a.CreateDate,a.SNCode,0 IsRcv FROM dbo.TP_PCShipDetail a
	WHERE ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,''))
	) t ) t WHERE t.RN=1 AND t.IsRcv=0
	)
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT ship.DocNo FROM (
		SELECT a.ShipID,a.SNCode,ROW_NUMBER()OVER(ORDER BY a.CreateDate desc)RN FROM dbo.TP_PCShipDetail a WHERE ISNULL(a.InternalCode,'')=@BSN AND ISNULL(a.SNCode,'')=@SN)
		t INNER JOIN dbo.TP_PCShip ship ON t.ShipID=ship.ID WHERE t.RN=1)+'内扫描过！'Msg	
		RETURN;
	END 
	
	IF EXISTS(SELECT 1 FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.InternalCode,'')=ISNULL(@BSN,'') AND ISNULL( a.SNCode,'')=@SN)
	BEGIN
		SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
		INSERT INTO dbo.TP_PCShipDetail
		        ( CreateBy ,
		          CreateDate ,
		          ShipID ,
		          SNCode ,
		          MaterialID ,
		          MaterialCode ,
		          MaterialName ,
		          Status ,
		          Progress ,
				  SoftUpdateDate,
		          Remark
		        )			
		SELECT TOP 1 @CreateBy,GETDATE(),@ShipID,@SNCode,a.MaterialID,a.MaterialCode,a.MaterialName,@Status,@Progress,@SoftUpdateDate,@Remark 
		FROM dbo.TP_RDRcvDetail a
		INNER JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
		WHERE ISNULL(a.InternalCode,'')=@BSN AND  ISNULL(a.SNCode,'')=@SN
		
		--返回扫码集合
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,a.Status,a.Progress,a.SoftUpdateDate,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_PCShipDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.ShipID=@ShipID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_PCShipDetail a where a.ShipID=@ShipID)ShipCount
	END		

	ELSE
	BEGIN
		SELECT '0'MsgType,'没有SN编码['+@SNCode+']的数据！'Msg
	END 

END 


