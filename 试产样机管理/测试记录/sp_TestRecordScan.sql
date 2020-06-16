/*
测试记录扫码
*/
ALTER PROC [dbo].[sp_TestRecordScan]
(
@pageIndex INT,
@pageSize INT,
@SNCode VARCHAR(100),
@TestRecordID INT,
@IsPass int,
@Remark NVARCHAR(2000),
@CreateBy VARCHAR(100)
)
AS
BEGIN

	--DECLARE @SNCode VARCHAR(100)='123',@TestRecordID INT=3
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	--判断输入的是SN编码还是研发出库单
	IF EXISTS(SELECT 1 FROM dbo.TP_RDShip WHERE DocNo=@SNCode)--研发出库单号
	BEGIN
		IF EXISTS(
		SELECT 1 FROM dbo.TP_RDShipDetail a INNER JOIN dbo.TP_RDShip b ON a.ShipID=b.ID
		INNER JOIN dbo.TP_TestDetail c ON c.TestRecordID=@TestRecordID AND c.SNCode=a.SNCode
		WHERE b.DocNo=@SNCode
		)
		BEGIN
			SELECT '0'MsgType,'编码：'+
			(SELECT c.SNCode+',' FROM dbo.TP_RDShipDetail a INNER JOIN dbo.TP_RDShip b ON a.ShipID=b.ID
			INNER JOIN dbo.TP_TestDetail c ON c.TestRecordID=@TestRecordID AND c.SNCode=a.SNCode
			WHERE b.DocNo=@SNCode FOR XML PATH(''))+'已经在本订单扫描过！' Msg
			RETURN;
		END 
		ELSE
        BEGIN
			--整单插入
			INSERT INTO dbo.TP_TestDetail
			        ( CreateBy ,CreateDate ,TestRecordID ,SNCode, MaterialID ,MaterialCode ,MaterialName ,IsPass ,Remark
			        )
				SELECT @CreateBy,GETDATE(),@TestRecordID,a.SNCode,a.MaterialID,c.MaterialCode,c.MaterialName,@IsPass,@Remark FROM dbo.TP_RDShipDetail a INNER JOIN dbo.TP_RDShip b ON a.ShipID=b.ID				
				LEFT JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
				WHERE b.DocNo=@SNCode
			SELECT '1'MsgType,'扫码成功！'Msg
			--返回扫码集合
			SELECT * 		
			FROM (
			SELECT a.ID,a.SNCode,b.MaterialCode,b.MaterialName,a.IsPass,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
			FROM dbo.TP_TestDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.TestRecordID=@TestRecordID
			) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

			SELECT (SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID)TestCount,(SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID AND a.IsPass=0)UnPassCount
		END 
        
		
	END 
	ELSE
    BEGIN
		--判断SN码是否已经在本单扫描过
		IF EXISTS(SELECT 1 FROM dbo.TP_TestDetail a WHERE a.TestRecordID=@TestRecordID AND a.SNCode=ISNULL(@SNCode,''))
		BEGIN
			SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
			RETURN;
		END 
		--判断SN码是否被其他单据扫描过
		IF EXISTS(SELECT 1 FROM dbo.TP_TestDetail a WHERE a.TestRecordID<>@TestRecordID AND a.SNCode=ISNULL(@SNCode,''))
		BEGIN
			SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT a.DocNo FROM dbo.TP_TestRecord a WHERE a.ID=@TestRecordID)+'内扫描过！'Msg	
			RETURN;
		END 
		--根据码查出内控码
		DECLARE @BSN VARCHAR(100),@SN VARCHAR(100)
		SELECT @BSN=ISNULL(a.InternalCode,''),@SN=ISNULL(a.SNCode,'') FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.SNCode,'')=@SNCode OR ISNULL(a.InternalCode,'')=@SNCode
		
		--校验是否有SN码数据
		IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.InternalCode=ISNULL(@BSN,''))
		BEGIN
			SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
			INSERT INTO dbo.TP_TestDetail
					( CreateBy ,
					  CreateDate ,
					  TestRecordID ,
					  SNCode ,
					  ProduceBy ,
					  MaterialID ,
					  MaterialCode ,
					  MaterialName ,
					  IsPass,
					  Remark
					)
			SELECT @CreateBy,GETDATE(),@TestRecordID,CASE WHEN @SN='' THEN @BSN ELSE @SN END,NULL,a.MaterialID,c.MaterialCode,c.MaterialName,@IsPass,@Remark 
			FROM dbo.TP_RDRcvDetail a
			INNER JOIN dbo.mxqh_Material c ON a.MaterialID=c.Id
			WHERE ISNULL(a.InternalCode,'')=@BSN AND ISNULL(a.SNCode,'')=@SN
			--返回扫码集合
			SELECT * 		
			FROM (
			SELECT a.ID,a.SNCode,b.MaterialCode,b.MaterialName,a.IsPass,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
			FROM dbo.TP_TestDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.TestRecordID=@TestRecordID
			) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

			SELECT (SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID)TestCount,(SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID AND a.IsPass=0)UnPassCount
		END		

		ELSE
		BEGIN
			SELECT '0'MsgType,'没有SN编码['+@SNCode+']的数据！'Msg
		END 
	END 
	

END 
