/*
����ģ����Ʒ��ϵ
*/
ALter PROC sp_SaveMouldRelation
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')  AND  EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable1') AND TYPE='U') 
	BEGIN
		DECLARE @IsEdit INT=0
		SELECT @IsEdit=COUNT(*) FROM #TempTable a,dbo.Mould_ItemRelation b WHERE a.MouldID=b.MouldID
		--ɾ��
		--DELETE FROM dbo.Mould_ItemRelation WHERE ID NOT EXISTS(SELECT ID FROM #TempTable1 a WHERE a.ID=dbo.Mould_ItemRelation.ID)

		UPDATE dbo.Mould_ItemRelation SET Deleted=1,ModifyBy=a.ModifyBy,ModifyDate=GETDATE() 
		FROM #TempTable a WHERE dbo.Mould_ItemRelation.ID NOT IN (SELECT ID FROM #TempTable1 b)

		--��������
		UPDATE dbo.Mould_ItemRelation SET ModifyBy=a.ModifyBy,ModifyDate=GETDATE(),MouldID=a.MouldID,MouldCode=a.MouldCode,MouldName=a.MouldName
		,MouldSPECS=a.MouldSPECS,ItemID=b.ItemID,ItemCode=b.ItemCode,ItemName=b.ItemName,ItemSPECS=b.ItemSPECS,UnitOutput=b.UnitOutput,PoorRate=b.PoorRate
		,EffectiveDate=b.EffectiveDate,DisableDate=b.DisableDate,Remark=b.Remark
		FROM #TempTable a,#TempTable1 b WHERE dbo.Mould_ItemRelation.ID=b.ID

		--��������
		INSERT INTO dbo.Mould_ItemRelation
		        ( CreateBy ,CreateDate,ModifyBy,ModifyDate ,Deleted ,MouldID ,MouldCode ,MouldName ,MouldSPECS 
				,ItemID ,ItemCode ,ItemName ,ItemSPECS ,UnitOutput ,PoorRate ,EffectiveDate ,DisableDate ,Remark
		        )
				SELECT a.CreateBy,GETDATE(),a.ModifyBy,GETDATE(),0,a.MouldID,a.MouldCode,a.MouldName ,a.MouldSPECS 
				,b.ItemID ,b.ItemCode ,b.ItemName ,b.ItemSPECS ,b.UnitOutput ,b.PoorRate ,b.EffectiveDate ,b.DisableDate ,b.Remark FROM #TempTable a,#TempTable1 b WHERE b.ID=-1
		
		SELECT '1' MsgType,'����ɹ���'Msg
		
	END 
	ELSE
    BEGIN
		SELECT '0' MsgType,'����ʧ�ܣ�'Msg
	END 
	
END 