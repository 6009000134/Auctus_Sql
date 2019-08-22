/*
QC�Ǽ���ϸ��Ϣ
*/
Alter PROC sp_GetQCCheckDetail
(
@size INT,
@index INT,
@PalletCode VARCHAR(30)
)
AS
BEGIN
	--DECLARE @@size INT=10,
	--		@pageIndex INT=1,
	--		@CustomOrder VARCHAR(100),
	--		@PalletCode VARCHAR(30),
	--		@WorkOrder VARCHAR(30)
	DECLARE @beginIndex INT=@size*(@index-1)
	DECLARE @endIndex INT=@size*@index+1
	--�ж��Ƿ����ջ���
	IF EXISTS(SELECT 1 FROM dbo.opPackageDetail WHERE PalletCode=@PalletCode)--����
    BEGIN
		--�ж��Ƿ��Ѿ�QC�Ǽ�
		IF EXISTS(SELECT 1 FROM dbo.qlCheckMain WHERE PalletCode=@PalletCode)--�Ѿ��Ǽǹ�
		BEGIN
			SELECT '2' MsgType,'��ջ����Ѿ���������Ƿ��ٴμ��飡'Msg		    	
			--������Ϣ			
			SELECT TOP 1 a.WorkOrder,a.Quantity,a.CustomerOrder FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.opPackageMain b ON a.ID=b.AssemblyPlanDetailID
			INNER JOIN dbo.opPackageDetail c ON b.ID=c.PackMainID
			WHERE c.PalletCode=@PalletCode
			
			SELECT ID,DocNo,PalletCode,CustomOrder,CheckNum,CONVERT(VARCHAR(2),IsOK)IsOK,ProblemType,ProblemInfo,ProblemDesp FROM dbo.qlCheckMain WHERE PalletCode=@PalletCode
		
			--�Ǽ���Ϣ����
			SELECT b.ID,a.DocNo,b.MainID,b.SNCode,b.InternalCode,b.ProductCode,b.ProductName,b.IsCheckOk,b.Remark,b.Item1
			FROM dbo.qlCheckMain a INNER JOIN dbo.qlCheckPar b ON a.ID=b.MainID
			WHERE a.PalletCode=@PalletCode
		END 	
		ELSE--δ�Ǽǹ�
        BEGIN
			SELECT '1' MsgType,'δ�Ǽǹ���'Msg
			--������Ϣ			
			SELECT TOP 1 a.WorkOrder,a.Quantity,a.CustomerOrder FROM dbo.mxqh_plAssemblyPlanDetail a INNER JOIN dbo.opPackageMain b ON a.ID=b.AssemblyPlanDetailID
			INNER JOIN dbo.opPackageDetail c ON b.ID=c.PackMainID
			WHERE c.PalletCode=@PalletCode
		END 
		
	END 
	ELSE--������
    BEGIN
		SELECT '0' MsgType,'ջ��Ų����ڣ�'Msg
	END 
END 