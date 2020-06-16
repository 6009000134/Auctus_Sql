/*
商务中心出库记录扫码
*/
ALTER PROC [dbo].[sp_TP_BCShipScan]
(
@pageIndex INT,
@pageSize INT,
@SNCode VARCHAR(100),
@ShipID INT,
@DocType VARCHAR(100),
@TypeID INT,
@TypeCode VARCHAR(20),
@TypeName VARCHAR(20),
@Remark NVARCHAR(2000),
@CreateBy VARCHAR(100)
)
AS
BEGIN

	--DECLARE @SNCode VARCHAR(100)='123',@TestRecordID INT=3
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1	
	--根据码查出内控码
	DECLARE @BSN VARCHAR(100),@SN VARCHAR(100)
	SELECT @BSN=ISNULL(a.InternalCode,''),@SN=ISNULL(a.SNCode,'') FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.SNCode,'')=@SNCode OR ISNULL(a.InternalCode,'')=@SNCode
	--判断SN码是否已经在本单扫描过
	IF EXISTS(SELECT 1 FROM dbo.TP_BCShipDetail a WHERE a.ShipID=@ShipID AND ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,'')))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
		RETURN;
	END 
	--判断SN码是否被其他单据扫描过
	IF EXISTS(SELECT 1 FROM dbo.TP_BCShipDetail a WHERE a.ShipID<>@ShipID AND ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,'')))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT a.DocNo FROM dbo.TP_BCShip a WHERE a.ID=@ShipID)+'单内扫描过！'Msg	
		RETURN;
	END 
	

	IF EXISTS(SELECT 1 FROM dbo.TP_BCRcvDetail a 
	WHERE ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,''))
	OR a.SNCode=@SNCode--商务自己录入的旧料，在研发无记录
	)
	BEGIN
		SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
		INSERT INTO dbo.TP_BCShipDetail
		        ( CreateBy ,
		          CreateDate ,
		          ShipID ,
		          SNCode ,
		          MaterialID ,
		          MaterialCode ,
		          MaterialName ,
		          TypeID,
				  TypeCode,
				  TypeName,
		          Remark
		        )			
			SELECT TOP 1 @CreateBy,GETDATE(),@ShipID,@SNCode,a.MaterialID,a.MaterialCode,a.MaterialName,@TypeID,@TypeCode,@TypeName,@Remark 
		FROM dbo.TP_RDRcvDetail a
		INNER JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
		WHERE ISNULL(a.InternalCode,'')=@BSN AND  ISNULL(a.SNCode,'')=@SN
		
		--返回扫码集合
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,a.TypeName,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_BCShipDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.ShipID=@ShipID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_BCShipDetail a where a.ShipID=@ShipID)RcvCount
	END		

	ELSE
	BEGIN
		SELECT '0'MsgType,'没有SN编码['+@SNCode+']的数据！'Msg
	END 
END 


