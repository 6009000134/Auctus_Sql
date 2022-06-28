SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_TP_RDShipScan]
(
@pageIndex INT,
@pageSize INT,
@SNCode VARCHAR(100),
@ShipID INT,
@DocType VARCHAR(100),
@Progress VARCHAR(10),--样机阶段
@Status VARCHAR(10),--样机状态
@Remark NVARCHAR(2000),
@CreateBy VARCHAR(100)
)
AS
BEGIN
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1	

	--根据码查出内控码\SN编码
	DECLARE @BSN VARCHAR(100),@SN VARCHAR(100)
	SELECT @BSN=a.InternalCode,@SN=a.SNCode FROM dbo.TP_RDRcvDetail a WHERE a.SNCode=@SNCode OR a.InternalCode=@SNCode
	
	IF ISNULL(@BSN,'')='' AND  ISNULL(@SN,'')=''
	BEGIN
			SELECT '0'MsgType,'['+@SNCode+']没有库存！'Msg				
	END 
	ELSE
	BEGIN
		DECLARE @canAdd int=0
		IF ISNULL(@BSN,'')!=''
		BEGIN
			--判断SN码是否已经在本单扫描过
			IF EXISTS(SELECT 1 FROM dbo.TP_RDShipDetail a WHERE a.ShipID=@ShipID AND a.InternalCode=ISNULL(@BSN,''))
			BEGIN
				SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
				RETURN;
			END	
			--判断当前BSN编码属于是否在库
			IF EXISTS(SELECT 1 FROM (
			SELECT t.*,ROW_NUMBER()OVER(ORDER BY t.CreateDate DESC)RN FROM (
			SELECT a.CreateDate,a.SNCode,1 IsRcv FROM dbo.TP_RDRcvDetail a 
			WHERE a.InternalCode=@BSN
			UNION ALL
			SELECT a.CreateDate,a.SNCode,0 IsRcv FROM dbo.TP_RDShipDetail a
			WHERE a.InternalCode=@BSN
			) t ) t WHERE t.RN=1 AND t.IsRcv=0
			)
			BEGIN
					SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT ship.DocNo FROM (
					SELECT a.ShipID,a.SNCode,ROW_NUMBER()OVER(ORDER BY a.CreateDate desc)RN FROM dbo.TP_RDShipDetail a WHERE a.InternalCode=@BSN)
					t INNER JOIN dbo.TP_RDShip ship ON t.ShipID=ship.ID WHERE t.RN=1)+'内扫描过！'Msg	
					RETURN;
			END 
			ELSE
			BEGIN
				SET @canAdd=1
			END 		 
		END 
		ELSE
        BEGIN
				--判断SN码是否已经在本单扫描过
			IF EXISTS(SELECT 1 FROM dbo.TP_RDShipDetail a WHERE a.ShipID=@ShipID AND a.SNCode=ISNULL(@SN,''))
			BEGIN
				SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
				RETURN;
			END	
			--判断当前SN编码属于是否在库
			IF EXISTS(SELECT 1 FROM (
			SELECT t.*,ROW_NUMBER()OVER(ORDER BY t.CreateDate DESC)RN FROM (
			SELECT a.CreateDate,a.SNCode,1 IsRcv FROM dbo.TP_RDRcvDetail a 
			WHERE a.SNCode=@SN
			UNION ALL
			SELECT a.CreateDate,a.SNCode,0 IsRcv FROM dbo.TP_RDShipDetail a
			WHERE a.SNCode=@SN
			) t ) t WHERE t.RN=1 AND t.IsRcv=0
			)
			BEGIN
					SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT ship.DocNo FROM (
					SELECT a.ShipID,a.SNCode,ROW_NUMBER()OVER(ORDER BY a.CreateDate desc)RN FROM dbo.TP_RDShipDetail a WHERE a.InternalCode=@BSN)
					t INNER JOIN dbo.TP_RDShip ship ON t.ShipID=ship.ID WHERE t.RN=1)+'内扫描过！'Msg	
					RETURN;
			END 
			ELSE
            BEGIN
				SET @canAdd=1
			END 
		END 
		IF @canAdd=1		
		BEGIN 
			SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
			INSERT INTO dbo.TP_RDShipDetail
					( CreateBy ,
					  CreateDate ,
					  ShipID ,
					  InternalCode,
					  SNCode ,
					  MaterialID ,
					  MaterialCode ,
					  MaterialName ,
					  Status ,
					  Progress ,
					  Remark,
					  HardwareVersion,
					  HardwareStatus,
					  SoftwareVersion,
					  SoftwareStatus,
					  AssemblyDate,
					  PackDate
					)			
			SELECT TOP 1 @CreateBy,GETDATE(),@ShipID,@BSN,@SN,a.MaterialID,c.MaterialCode,c.MaterialName,@Status,@Progress,@Remark 
			,a.HardwareVersion,a.HardwareStatus,a.SoftwareVersion,a.SoftwareStatus,a.AssemblyDate,a.PackDate
			FROM (SELECT t.MaterialID,t.HardwareVersion,t.HardwareStatus,t.SoftwareVersion,t.SoftwareStatus,t.AssemblyDate,t.PackDate,ROW_NUMBER()OVER(ORDER BY t.ID desc)RN FROM dbo.TP_RDRcvDetail t
			WHERE ISNULL(t.InternalCode,'')=ISNULL(@BSN,'') AND  ISNULL(t.SNCode,'')=ISNULL(@SN,'')	) a 
			INNER JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
			WHERE a.rn=1


			--返回扫码集合
			SELECT * 		
			FROM (
			SELECT a.ID,a.SNCode,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
			,a.HardwareVersion,a.HardwareStatus,a.SoftwareVersion,a.SoftwareStatus,a.AssemblyDate,a.PackDate
			FROM dbo.TP_RDShipDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.ShipID=@ShipID
			) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

			SELECT (SELECT COUNT(1) FROM dbo.TP_RDShipDetail a where a.ShipID=@ShipID)ShipCount
		END 
	END 

END
GO