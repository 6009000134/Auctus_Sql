SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
/*
������������¼ɨ��
*/
CREATE PROC [dbo].[sp_TP_BCRcvScan]
(
@pageIndex INT,
@pageSize INT,
@SNCode VARCHAR(100),
@RcvID INT,
@DocType VARCHAR(10),
--@Progress VARCHAR(10),--�����׶�
--@Status VARCHAR(10),--����״̬
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

	--���������ڿ���
	DECLARE @BSN VARCHAR(100),@SN VARCHAR(100)
	SELECT @BSN=ISNULL(a.InternalCode,''),@SN=ISNULL(a.SNCode,'') FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.SNCode,'')=@SNCode OR ISNULL(a.InternalCode,'')=@SNCode

	--�ж�SN���Ƿ��Ѿ��ڱ���ɨ���
	IF EXISTS(SELECT 1 FROM dbo.TP_BCRcvDetail a WHERE a.RcvID=@RcvID AND ISNULL(a.SNCode,'')=ISNULL(@SN,ISNULL(@BSN,'')))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']�Ѿ��ڱ�����ɨ�����'Msg	
		RETURN;
	END 
	
	--�з��޼�¼��SN�룬���Ƿ��������Լ�¼���SN��
	IF ISNULL(@BSN,'')=''AND ISNULL(@SN,'')=''
	BEGIN
    	SELECT @BSN=ISNULL(a.InternalCode,''),@SN=ISNULL(a.SNCode,'') FROM dbo.TP_BCRcvDetail a WHERE ISNULL(a.SNCode,'')=@SNCode 
		OR ISNULL(a.InternalCode,'')=@SNCode
	END 

	--�жϵ�ǰBSN���������Ƿ��ڿ�
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
		SELECT '0'MsgType,'['+@SNCode+']�Ѿ���'+(SELECT rcv.DocNo FROM (
		SELECT a.RcvID,a.SNCode,ROW_NUMBER()OVER(ORDER BY a.CreateDate desc)RN FROM dbo.TP_BCRcvDetail a WHERE ISNULL(a.SNCode,'')=@SN)
		t INNER JOIN dbo.TP_BCRcv rcv ON t.RcvID=rcv.ID WHERE t.RN=1)+'��ɨ�����'Msg	
		RETURN;
	END 

	IF EXISTS(SELECT 1 FROM dbo.TP_RDRcvDetail a WHERE ISNULL(a.InternalCode,'')=ISNULL(@BSN,'') AND ISNULL( a.SNCode,'')=@SN)
	BEGIN
		SELECT '1'MsgType,'['+@SNCode+']ɨ��ɹ���'Msg
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
		
		--����ɨ�뼯��
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,a.TypeName,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_BCRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_BCRcvDetail a where a.RcvID=@RcvID)RcvCount
	END		
	ELSE IF EXISTS(SELECT 1 FROM dbo.TP_BCRcvDetail a WHERE ISNULL(a.InternalCode,'')=ISNULL(@BSN,'') AND ISNULL( a.SNCode,'')=@SN)
	BEGIN
				SELECT '1'MsgType,'['+@SNCode+']ɨ��ɹ���'Msg
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
		
		--����ɨ�뼯��
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,a.TypeName,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_BCRcvDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.RcvID=@RcvID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_BCRcvDetail a where a.RcvID=@RcvID)RcvCount
	END 
	ELSE
	BEGIN
		SELECT '0'MsgType,'û��SN����['+@SNCode+']�����ݣ�'Msg
	END 

END 



GO