SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
/*
商务中心入库记录扫码
*/
CREATE PROC [dbo].[sp_TP_BCRcvScan]
(
@pageIndex INT,
@pageSize INT,
@SNCode VARCHAR(100),
@RcvID INT,
@DocType VARCHAR(10),
--@Progress VARCHAR(10),--样机阶段
--@Status VARCHAR(10),--样机状态
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
	IF EXISTS(SELECT 1 FROM dbo.TP_BCRcvDetail a WHERE a.RcvID=@RcvID AND ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,'')))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在本单内扫描过！'Msg	
		RETURN;
	END 
	
	--研发无记录的SN码，找是否是商务自己录入的SN码
	IF ISNULL(@BSN,'')=''AND ISNULL(@SN,'')=''
	BEGIN
    	SELECT @BSN=ISNULL(a.InternalCode,''),@SN=ISNULL(a.SNCode,'') FROM dbo.TP_BCRcvDetail a WHERE ISNULL(a.SNCode,'')=@SNCode 
		OR ISNULL(a.InternalCode,'')=@SNCode
	END 

	--判断当前BSN编码属于是否在库
	IF EXISTS(SELECT 1 FROM (
	SELECT t.*,ROW_NUMBER()OVER(ORDER BY t.CreateDate DESC)RN FROM (
	SELECT a.CreateDate,a.SNCode,1 IsRcv FROM dbo.TP_BCRcvDetail a 
	WHERE ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,''))
	UNION ALL
	SELECT a.CreateDate,a.SNCode,0 IsRcv FROM dbo.TP_BCShipDetail a
	WHERE ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,''))
	) t ) t WHERE t.RN=1 AND t.IsRcv=1
	)
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']已经在'+(SELECT rcv.DocNo FROM (
		SELECT a.RcvID,a.SNCode,ROW_NUMBER()OVER(ORDER BY a.CreateDate desc)RN FROM dbo.TP_BCRcvDetail a WHERE ISNULL(a.SNCode,'')=@SN)
		t INNER JOIN dbo.TP_BCRcv rcv ON t.RcvID=rcv.ID WHERE t.RN=1)+'内扫描过！'Msg	
		RETURN;
	END 

	IF EXISTS(SELECT 1 FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.InternalCode,'')=ISNULL(@BSN,'') AND ISNULL( a.SNCode,'')=@SN)
	BEGIN
		SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
		INSERT INTO dbo.TP_BCRcvDetail
		        ( CreateBy ,
		          CreateDate ,
		          RcvID ,
		          SNCode ,
		          MaterialID ,
		          MaterialCode ,
		          MaterialName ,
		          TypeID,
				  TypeCode,
				  TypeName,
		          Remark
		        )			
		SELECT  TOP 1 @CreateBy,GETDATE(),@RcvID,@SNCode,a.MaterialID,a.MaterialCode,a.MaterialName,@TypeID,@TypeCode,@TypeName,@Remark 
		FROM dbo.TP_RDRcvDetail a 
		WHERE ISNULL(a.InternalCode,'')=ISNULL(@BSN,'') AND ISNULL(a.SNCode,'')=@SN
		
		--返回扫码集合
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,a.TypeName,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_BCRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_BCRcvDetail a where a.RcvID=@RcvID)RcvCount
	END		
	ELSE IF EXISTS(SELECT 1 FROM dbo.TP_BCRcvDetail a WHERE ISNULL(a.InternalCode,'')=ISNULL(@BSN,'') AND ISNULL( a.SNCode,'')=@SN)
	BEGIN
				SELECT '1'MsgType,'['+@SNCode+']扫码成功！'Msg
		INSERT INTO dbo.TP_BCRcvDetail
		        ( CreateBy ,
		          CreateDate ,
		          RcvID ,
		          SNCode ,
		          MaterialID ,
		          MaterialCode ,
		          MaterialName ,
		          TypeID,
				  TypeCode,
				  TypeName,
		          Remark
		        )			
		SELECT  TOP 1 @CreateBy,GETDATE(),@RcvID,@SNCode,a.MaterialID,a.MaterialCode,a.MaterialName,@TypeID,@TypeCode,@TypeName,@Remark 
		FROM dbo.TP_BCRcvDetail a 
		WHERE ISNULL(a.InternalCode,'')=ISNULL(@BSN,'') AND ISNULL(a.SNCode,'')=@SN
		
		--返回扫码集合
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,a.TypeName,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_BCRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_BCRcvDetail a where a.RcvID=@RcvID)RcvCount
	END 
	ELSE
	BEGIN
		SELECT '0'MsgType,'没有SN编码['+@SNCode+']的数据！'Msg
	END 

END 



GO