/*
���Լ�¼ɨ��
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
	--�ж�SN���Ƿ��Ѿ��ڱ���ɨ���
	IF EXISTS(SELECT 1 FROM dbo.TP_TestDetail a WHERE a.TestRecordID=@TestRecordID AND a.SNCode=ISNULL(@SNCode,''))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']�Ѿ��ڱ�����ɨ�����'Msg	
		RETURN;
	END 
	--�ж�SN���Ƿ���������ɨ���
	IF EXISTS(SELECT 1 FROM dbo.TP_TestDetail a WHERE a.TestRecordID<>@TestRecordID AND a.SNCode=ISNULL(@SNCode,''))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']�Ѿ���'+(SELECT a.DocNo FROM dbo.TP_TestRecord a WHERE a.ID=@TestRecordID)+'������ɨ�����'Msg	
		RETURN;
	END 
	--���������ڿ���
	DECLARE @BSN VARCHAR(100)
	SELECT @BSN=a.InternalCode FROM dbo.baInternalAndSNCode a WHERE a.SNCode=@SNCode
	
	--У���Ƿ����깤���ݣ����ã�
	--IF EXISTS(SELECT * FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail b ON a.ID=b.PlanExecutMainID
	--	WHERE b.ExtendOne=0 AND b.IsPass=1 AND b.OrderNum=(SELECT MAX(b.OrderNum) FROM dbo.opPlanExecutMain a INNER JOIN dbo.opPlanExecutDetail b ON a.ID=b.PlanExecutMainID WHERE a.InternalCode=@BSN)
	--	AND a.InternalCode=@BSN)
	
	--У���Ƿ���SN������
	IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.InternalCode=ISNULL(@BSN,''))
	BEGIN
		SELECT '1'MsgType,'['+@SNCode+']ɨ��ɹ���'Msg
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
			--����ɨ�뼯��
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,b.MaterialCode,b.MaterialName,a.IsPass,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_TestDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.TestRecordID=@TestRecordID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID)TestCount,(SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID AND a.IsPass=0)UnPassCount
	END		

	ELSE
	BEGIN
		SELECT '0'MsgType,'MES��û��SN����['+@SNCode+']�����ݣ�'Msg
	END 

END 




/*
--�󺸡���װ�깤���ݲ�ѯ
	ELSE IF EXISTS(SELECT * FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.opPlanExecutDetailHH b ON a.ID=b.PlanExecutMainID
		WHERE b.ExtendOne=0 AND b.IsPass=1 AND b.OrderNum=(SELECT MAX(b.OrderNum) FROM dbo.opPlanExecutMainHH a INNER JOIN dbo.opPlanExecutDetailHH b ON a.ID=b.PlanExecutMainID WHERE a.InternalCode=@BSN)
		AND a.InternalCode=@BSN)
	BEGIN
		SELECT '1'MsgType,'['+@SNCode+']ɨ��ɹ���'Msg
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
		--����ɨ�뼯��
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
		SELECT '1'MsgType,'['+@SNCode+']ɨ��ɹ���'Msg
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
		--����ɨ�뼯��
		SELECT * FROM (
		SELECT a.ID,a.SNCode,b.MaterialCode,b.MaterialName,a.IsPass,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_TestDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.TestRecordID=@TestRecordID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
		SELECT (SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID)TestCount,(SELECT COUNT(1) FROM dbo.TP_TestDetail a where a.TestRecordID=@TestRecordID AND a.IsPass=0)UnPassCount
	END 
*/