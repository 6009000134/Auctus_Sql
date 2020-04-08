/*
导入模具信息
*/
ALTER PROC sp_ImportMould
(
@CreateBy VARCHAR(50)
)
AS
BEGIN
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		DECLARE @IsValid INT
		SELECT @Isvalid=COUNT(1) FROM #TempTable a WHERE ISNULL(a.Name,'')   ='' OR ISNULL(a.ModelType,'')='' OR ISNULL(a.Holder,'')=''
		IF	ISNULL(@IsValid,0)=0
		BEGIN
			INSERT INTO dbo.Mould
			        ( CreateBy ,
			          CreateDate ,
			          ModifyBy ,
			          ModifyDate ,
			          Deleted ,
			          Code ,
			          Name ,
			          SPECS ,
			          HoleNum ,
			          TotalNum ,
			          DailyCapacity ,
			          DailyNum ,
			          RemainNum ,
			          Holder ,
			          Manufacturer ,
			          CycleTime ,
			          ProductWeight ,
			          NozzleWeight ,
			          DealDate ,
			          IsEffective ,
			          EffectiveDate ,
			          Remark ,
			          MachineWeight ,
			          ProductCode ,
			          ModelType
			        )
			SELECT    @CreateBy , -- CreateBy - varchar(20)
			          GETDATE() , -- CreateDate - datetime
			          @CreateBy , -- ModifyBy - varchar(20)
			          GETDATE() , -- ModifyDate - datetime
			          0 , -- Deleted - char(2)					  
			          a.Code , -- Code - varchar(50)
			          a.Name , -- Name - nvarchar(300)
			          a.SPECS , -- SPECS - nvarchar(600)
			          CONVERT(INT,a.HoleNum) , -- HoleNum - int
			          CONVERT(INT,a.TotalNum) , -- TotalNum - int
			          CONVERT(INT,a.DailyCapacity) , -- DailyCapacity - int
			          CONVERT(INT,a.DailyNum ), -- DailyNum - int
			          CONVERT(DECIMAL(18,4),a.RemainNum) , -- RemainNum - decimal(18, 4)
			          a.Holder , -- Holder - nvarchar(50)
			          a.Manufacturer , -- Manufacturer - nvarchar(50)
			          CONVERT(DECIMAL(18,4),a.CycleTime) , -- CycleTime - decimal(18, 4)
			          CONVERT(DECIMAL(18,4),a.ProductWeight) , -- ProductWeight - decimal(18, 4)
			          CONVERT(DECIMAL(18,4),a.NozzleWeight) , -- NozzleWeight - decimal(18, 4)
			          a.DealDate , -- DealDate - datetime
			          NULL , -- IsEffective - bit
			          a.EffectiveDate , -- EffectiveDate - datetime
			          a.Remark , -- Remark - nvarchar(800)
			          CONVERT(DECIMAL(18,4),a.MachineWeight) , -- MachineWeight - decimal(18, 4)
			          NULL , -- ProductCode - varchar(600)
			          a.ModelType  -- ModelType - varchar(300)
			        FROM #TempTable a
					
					SELECT '1' MsgType,'导入成功！！！' Msg

		END 
		ELSE
        BEGIN
					SELECT '0' MsgType,'模具名称/使用厂商/使用机型不能为空！！！' Msg
		END 
	END 
END 