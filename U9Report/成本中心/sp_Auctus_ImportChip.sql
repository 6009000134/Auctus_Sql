
/*
导入芯片数据
*/
ALTER PROC [dbo].[sp_Auctus_ImportChip]
(
@Date DATE,
@CreateBy VARCHAR(100)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
	BEGIN
		--IF EXISTS (SELECT 1 FROM dbo.Auctus_Chip a WHERE a.Date=@Date)
		--BEGIN
		--	DELETE FROM dbo.Auctus_Chip WHERE Date=@Date
		--END 
		INSERT INTO dbo.Auctus_Chip
					( UploadDATE ,
					  UploadBy ,
					  Date ,
					  LOTID ,
					  PO ,
					  CustCode ,
					  Device ,
					  TypeName ,
					  LotStartTime ,
					  WaferLot ,
					  WaferQty ,
					  CommiteTime ,
					  LotQty ,
					  Unissue ,
					  Tape ,
					  GrindingSawing ,
					  DieAttach ,
					  WireBond ,
					  Molding ,
					  Deflash ,
					  Marking ,
					  Plating ,
					  Singulation ,
					  FVI ,
					  ISSUEFT ,
					  FBAKING ,
					  BBT ,
					  FT ,
					  QA ,
					  BAKING ,
					  LS ,
					  Packing ,
					  CloseQty
					)
			SELECT GETDATE()
			,@CreateBy,@Date,a.A,a.B,a.C
			,a.D,a.E
			,a.F,a.G
			,a.H,a.I
			,a.J,a.K
			,a.L,a.M
			,a.N,a.O
			,a.P,a.Q
			,a.R,a.S
			,a.T,a.U
			,a.V,a.W
			,a.X,a.Y
			,a.AA,a.AB
			,a.AC,a.AD
			,a.AE
			FROM #TempTable a WHERE PATINDEX('D%',UPPER(a.G))>0
			SELECT '1' MsgType,'导入成功！'Msg
	END
	ELSE
    BEGIN
		SELECT '0' MsgType,'导入失败！'Msg		
	END 
END 
--SELECT CONVERT(int,1)
--SELECT * FROM auctus_bom

--DELETE FROM dbo.auctus_bom



