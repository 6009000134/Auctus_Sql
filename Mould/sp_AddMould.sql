/*
����ģ����Ϣ
*/
ALTER PROC sp_AddMould
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		IF EXISTS(SELECT 1 FROM #TempTable a,dbo.Mould b WHERE a.Code=b.Code AND b.Deleted=0)
		BEGIN			
			SELECT '0'MsgType,'���Ϻ��Ѵ��ڣ������ظ���ӣ�'Msg
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
			SELECT '1'MsgType,'��ӳɹ���'Msg       
		END 

	END
	ELSE
	BEGIN
		SELECT '0'MsgType,'���ʧ�ܣ�'Msg
	END  
END 