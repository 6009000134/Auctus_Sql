/*
QC校验登记
*/
ALTER PROC sp_QCIsExistSN
(
@PalletCode VARCHAR(40),
@SNCode varchar(30)
)
AS
BEGIN

IF EXISTS(SELECT 1 FROM dbo.opPackageDetail a INNER JOIN dbo.opPackageChild b ON a.ID=b.PackDetailID
WHERE a.PalletCode=@PalletCode AND b.SNCode=@SNCode)--首先确认栈板号和SN码关系是否正确
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.qlCheckPar WHERE SNCode=@SNCode)
	BEGIN
		SELECT '1' MsgType,'SN码已经检测过' Msg
		SELECT a.ID ,
		a.SNCode ,
		a.InternalCode ,
		a.ProductCode ,
		a.ProductName ,
		a.IsCheckOk ,
		a.Remark
		FROM   qlCheckPar a
		WHERE  a.SNCode = @SNCode;
	END 
	ELSE
    BEGIN
		SELECT '1'MsgType,'SN码未检测过'Msg
		
		SELECT -1 ID ,
		a.SNCode ,
		d.InternalCode ,
		c.ProductCode ,
		c.ProductName ,
		'1' IsCheckOk ,
		'' Remark
		FROM   opPackageChild a
		INNER JOIN opPackageDetail b ON b.ID = a.PackDetailID
		INNER JOIN opPackageMain c ON c.ID = b.PackMainID
		INNER JOIN baInternalAndSNCode d ON d.SNCode = a.SNCode
		WHERE  a.SNCode = @SNCode;
	END 
END 
ELSE
BEGIN
	SELECT '0' MsgType,'SN码不存在或不属于此栈板号' Msg
END 
 --SELECT a.*
 --FROM   opPackageChild AS a
 --       INNER JOIN opPackageDetail AS b ON a.PackDetailID = b.ID
 --WHERE  a.SNCode = '175HRT7850'
 --       AND b.PalletCode = '150918042';

	--	SELECT * FROM dbo.opPackageDetail a

 --SELECT -1 ID ,
 --       GETDATE() TS ,
 --       -1 MainID ,
 --       a.SNCode ,
 --       d.InternalCode ,
 --       c.ProductCode ,
 --       c.ProductName ,
 --       1 IsCheckOk ,
 --       '' Remark
 --FROM   opPackageChild a
 --       INNER JOIN opPackageDetail b ON b.ID = a.PackDetailID
 --       INNER JOIN opPackageMain c ON c.ID = b.PackMainID
 --       INNER JOIN baInternalAndSNCode d ON d.SNCode = a.SNCode
 --WHERE  a.SNCode = '175HRT7850';
 --175HRT7850

 END