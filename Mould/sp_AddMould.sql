/*
新增模具信息
*/
ALTER PROC [dbo].[sp_AddMould]
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM #TempTable a,dbo.Mould b WHERE (a.Code=b.Code OR a.Name=b.Name) AND b.Deleted=0)
		BEGIN			
			SELECT '0'MsgType,'该料号/名称已存在，不可重复添加！'Msg
		END		
		ELSE
        BEGIN
			--SELECT * FROM #TempTable
 			INSERT INTO dbo.Mould
					( CreateBy ,CreateDate,Deleted ,Code ,Name ,SPECS ,HoleNum ,TotalNum , DailyCapacity 
					,DailyNum ,RemainNum ,Holder ,Manufacturer ,CycleTime ,ProductWeight
					  , NozzleWeight,MachineWeight ,DealDate ,EffectiveDate ,Remark,ProductCode,ModelType,DesignTimes
					)
			SELECT a.CreateBy,GETDATE() ,'0' ,a.Code,a.Name,a.SPECS,a.HoleNum,a.TotalNum,a.DailyCapacity
			,a.DailyNum,a.RemainNum,a.Holder,a.Manufacturer
			,CASE WHEN a.CycleTime='' THEN 0 ELSE a.CycleTime END
			,CASE WHEN a.ProductWeight='' THEN 0 ELSE a.ProductWeight END
			,CASE WHEN a.NozzleWeight='' THEN 0 ELSE a.NozzleWeight END
			,CASE WHEN a.MachineWeight='' THEN 0 ELSE a.MachineWeight END
			,a.DealDate,a.EffectiveDate,a.Remark,ProductCode,ModelType,a.DesignTimes
			FROM #TempTable a
			SELECT '1'MsgType,'添加成功！'Msg       
		END 

	END
	ELSE
	BEGIN
		SELECT '0'MsgType,'添加失败！'Msg
	END  
END 

SELECT * FROM dbo.Mould