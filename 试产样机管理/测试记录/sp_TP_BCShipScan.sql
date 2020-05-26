/*
�������ĳ����¼ɨ��
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
	--IF @DocType='���'--���
	--BEGIN
	--	--�ж��Ƿ���Թ�
	--	IF NOT EXISTS(SELECT 1 FROM dbo.TP_TestDetail a WHERE a.SNCode=@SNCode)
	--	BEGIN
	--		SELECT '0'MsgType,'�������з����Լ�¼��'Msg
	--		RETURN;
	--	END 
	--END 
	--ELSE--�黹
 --   BEGIN
	--	--�ж��Ƿ��Ѿ��黹��
	--	PRINT ''
	--END 
	
	--�ж�SN���Ƿ��Ѿ��ڱ���ɨ���
	IF EXISTS(SELECT 1 FROM dbo.TP_BCShipDetail a WHERE a.ShipID=@ShipID AND a.SNCode=ISNULL(@SNCode,''))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']�Ѿ��ڱ�����ɨ�����'Msg	
		RETURN;
	END 
	--�ж�SN���Ƿ���������ɨ���
	IF EXISTS(SELECT 1 FROM dbo.TP_BCShipDetail a WHERE a.ShipID<>@ShipID AND a.SNCode=ISNULL(@SNCode,''))
	BEGIN
		SELECT '0'MsgType,'['+@SNCode+']�Ѿ���'+(SELECT a.DocNo FROM dbo.TP_BCShip a WHERE a.ID=@ShipID)+'����ɨ�����'Msg	
		RETURN;
	END 
	--���������ڿ���
	DECLARE @BSN VARCHAR(100)
	SELECT @BSN=a.InternalCode FROM dbo.baInternalAndSNCode a WHERE a.SNCode=@SNCode OR a.InternalCode=@SNCode

	IF EXISTS(SELECT 1 FROM dbo.opPlanExecutMain a WHERE a.InternalCode=ISNULL(@BSN,''))
	BEGIN
		SELECT '1'MsgType,'['+@SNCode+']ɨ��ɹ���'Msg
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
		SELECT @CreateBy,GETDATE(),@ShipID,@SNCode,b.MaterialID,c.MaterialCode,c.MaterialName,@TypeID,@TypeCode,@TypeName,@Remark FROM dbo.opPlanExecutMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID=b.ID
		INNER JOIN dbo.mxqh_Material c ON b.MaterialID=c.Id
		WHERE a.InternalCode=@BSN OR a.InternalCode=@SNCode
		
		--����ɨ�뼯��
		SELECT * 		
		FROM (
		SELECT a.ID,a.SNCode,a.TypeName,a.Status,a.Progress,b.MaterialCode,b.MaterialName,a.Remark,ROW_NUMBER()OVER(ORDER BY a.CreateDate DESC)RN
		FROM dbo.TP_BCShipDetail a INNER JOIN dbo.mxqh_Material b ON a.MaterialID=b.Id WHERE a.ShipID=@ShipID
		) t WHERE t.RN>@beginIndex AND t.RN<@endIndex

		SELECT (SELECT COUNT(1) FROM dbo.TP_BCShipDetail a where a.ShipID=@ShipID)RcvCount
	END		

	ELSE
	BEGIN
		SELECT '0'MsgType,'MES��û��SN����['+@SNCode+']�����ݣ�'Msg
	END 
END 


