/*
新增模具信息
*/
ALTER PROC sp_AddMould
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM #TempTable a,dbo.Mould b WHERE a.Code=b.Code AND b.Deleted=0)
		BEGIN			
			SELECT '0'MsgType,'该料号已存在，不可重复添加！'Msg
		END
		ELSE
        BEGIN
 			INSERT INTO dbo.Mould
					( CreateBy ,CreateDate,Deleted ,Code ,Name ,SPECS ,HoleNum ,TotalNum ,
					  DailyCapacity ,DailyNum ,RemainNum ,Holder ,Manufacturer ,CycleTime ,ProductWeight ,
					  NozzleWeight ,DealDate ,EffectiveDate ,Remark
					)
			SELECT a.CreateBy,GETDATE(),'0',a.Code,a.Name,a.SPECS,a.HoleNum,a.TotalNum,a.DailyCapacity
			,a.DailyNum,a.RemainNum,a.Holder,a.Manufacturer,a.CycleTime,a.ProductWeight,a.NozzleWeight,a.DealDate
			,a.EffectiveDate,a.Remark
			FROM #TempTable a
			SELECT '1'MsgType,'添加成功！'Msg       
		END 

	END
	ELSE
	BEGIN
		SELECT '0'MsgType,'添加失败！'Msg
	END  
END 