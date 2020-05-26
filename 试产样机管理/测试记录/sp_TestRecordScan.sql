/*
测试记录扫码
*/
ALTER PROC sp_TestRecordScan
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
	--判断SN码是否已经在本单扫描过
	IF EXISTS(SELECT 1 FROM dbo.TP_TestDetail a WHERE a.TestRecordID=@TestRecordID AND a.SNCode=ISNULL(@SNCode,''))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
		RETURN;
	END 
	--判断SN码是否被其他单据扫描过
	IF EXISTS(SELECT 1 FROM dbo.TP_TestDetail a WHERE a.TestRecordID<>@TestRecordID AND a.SNCode=ISNULL(@SNCode,''))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT a.DocNo FROM dbo.TP_TestRecord a WHERE a.ID=@TestRecordID)+'本单内扫描过！'Msg	
		RETURN;
	END 
	--根据码查出内控码
	DECLARE @BSN VARCHAR(100)
	SELECT @BSN=a.InternalCode FROM dbo.baInternalAndSNCode a WHERE a.SNCode=@SNCode
	
	--校验是否有完工数据（弃用）
	--IF EXISTS(SELECT * FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail b ON a.ID=b.PlanExecutMainID
	--	WHERE b.ExtendOne=0 AND b.IsPass=1 AND b.OrderNum=(SELECT MAX(b.OrderNum) FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail b ON a.ID=b.PlanExecutMainID WHERE a.InternalCode=@BSN)
	--	AND a.InternalCode=@BSN)
	
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
		SELECT @CreateBy,GETDATE(),@TestRecordID,@SNCode,NULL,b.MaterialID,c.MaterialCode,c.MaterialName,@IsPass,@Remark FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.mxqh_Material c ON b.MaterialID=c.Id
		WHERE a.InternalCode=@BSN OR a.InternalCode=@SNCode
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
		SELECT '0'MsgType,'MES中没有SN编码['+@SNCode+']的数据！'Msg
	END 

END 




/*
--后焊、包装完工数据查询
	ELSE IF EXISTS(SELECT * FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.opPlanExecutDetailHH b ON a.ID=b.PlanExecutMainID
		WHERE b.ExtendOne=0 AND b.IsPass=1 AND b.OrderNum=(SELECT MAX(b.OrderNum) FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.opPlanExecutDetailHH b ON a.ID=b.PlanExecutMainID WHERE a.InternalCode=@BSN)
		AND a.InternalCode=@BSN)
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
		SELECT @CreateBy,GETDATE(),@TestRecordID,@SNCode,NULL,b.MaterialID,c.MaterialCode,c.MaterialName,@IsPass,@Remark  FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.mxqh_Material c ON b.MaterialID=c.Id
		WHERE a.InternalCode=@BSN OR a.InternalCode=@SNCode
		--返回扫码集合
		SELECT * FROM (
		SELECT a.ID,a.SNCode,b.MaterialCode,b.MaterialName,a.IsPass,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_TestDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.TestRecordID=@TestRecordID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID)TestCount,(SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID AND a.IsPass=0)UnPassCount
	END 
	ELSE IF EXISTS(SELECT * FROM dbo.opPlanExecutMainPK a INNER JOIN dbo.opPlanExecutDetailPK b ON a.ID=b.PlanExecutMainID
		WHERE b.ExtendOne=0 AND b.IsPass=1 AND b.OrderNum=(SELECT MAX(b.OrderNum) FROM dbo.opPlanExecutMainPK a INNER JOIN dbo.opPlanExecutDetailPK b ON a.ID=b.PlanExecutMainID WHERE a.InternalCode=@SNCode)
		AND a.InternalCode=@SNCode)
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
		SELECT @CreateBy,GETDATE(),@TestRecordID,@SNCode,NULL,b.MaterialID,c.MaterialCode,c.MaterialName,@IsPass,@Remark FROM dbo.opPlanExecutMainPK a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.mxqh_Material c ON b.MaterialID=c.Id
		WHERE a.InternalCode=@BSN OR a.InternalCode=@SNCode
		--返回扫码集合
		SELECT * FROM (
		SELECT a.ID,a.SNCode,b.MaterialCode,b.MaterialName,a.IsPass,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_TestDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.TestRecordID=@TestRecordID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
		SELECT (SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID)TestCount,(SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID AND a.IsPass=0)UnPassCount
	END 
*/