/*
产品中心入库记录扫码
*/
ALTER PROC [dbo].[sp_TP_PCRcvScan]
(
@pageIndex INT,
@pageSize INT,
@SNCode VARCHAR(100),
@RcvID INT,
@DocType VARCHAR(10),
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
	--IF @DocType=0--入库
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
	
	--判断SN码是否已经在本单扫描过
	IF EXISTS(SELECT 1 FROM dbo.TP_PCRcvDetail a WHERE a.RcvID=@RcvID AND a.SNCode=ISNULL(@SNCode,''))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
		RETURN;
	END 
	--判断SN码是否被其他单据扫描过
	IF EXISTS(SELECT 1 FROM dbo.TP_PCRcvDetail a WHERE a.RcvID<>@RcvID AND a.SNCode=ISNULL(@SNCode,''))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT a.DocNo FROM dbo.TP_PCRcv a WHERE a.ID=@RcvID)+'单内扫描过！'Msg	
		RETURN;
	END 
	--根据码查出内控码
	DECLARE @BSN VARCHAR(100)
	SELECT @BSN=a.InternalCode FROM dbo.baInternalAndSNCode a WHERE a.SNCode=@SNCode OR a.InternalCode=@SNCode

	IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.InternalCode=ISNULL(@BSN,''))
	BEGIN
		SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
		INSERT INTO dbo.TP_PCRcvDetail
		        ( CreateBy ,
		          CreateDate ,
		          RcvID ,
		          SNCode ,
		          MaterialID ,
		          MaterialCode ,
		          MaterialName ,
		          Status ,
		          Progress ,
				  SoftUpdateDate,
		          Remark
		        )			
		SELECT @CreateBy,GETDATE(),@RcvID,@SNCode,b.MaterialID,c.MaterialCode,c.MaterialName,@Status,@Progress,@SoftUpdateDate,@Remark 
		FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.mxqh_Material c ON b.MaterialID=c.Id
		WHERE a.InternalCode=@BSN OR a.InternalCode=@SNCode
		
		--返回扫码集合
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,a.Status,a.Progress,a.SoftUpdateDate,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_PCRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_PCRcvDetail a where a.RcvID=@RcvID)RcvCount
	END		

	ELSE
	BEGIN
		SELECT '0'MsgType,'MES中没有SN编码['+@SNCode+']的数据！'Msg
	END 

END 


