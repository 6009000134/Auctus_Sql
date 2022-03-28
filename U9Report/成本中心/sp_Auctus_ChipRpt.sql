/*
功能：芯片耗损报表
创建人：刘飞
创建时间：2022-03-28
需求人：徐芳
详细需求：
1、按导入每日供应商excel数据批次号汇总
2、K列到最后一列汇总
3、A27芯片排除G列中非D开头的数据
4、报表汇总每日同一批次的数据，然后按列展示每日原始数据，后一天减前一天
*/

ALTER PROC sp_Auctus_ChipRpt
(
@pageSize INT,
@pageIndex INT,
@LotID VARCHAR(100),
@Device VARCHAR(100),
@SD DATE,
@ED DATE
)
AS
BEGIN

--DECLARE @pageSize INT=10,@pageIndex INT=1
--DECLARE @SD DATE='2021-07-07' ,@ED DATE='2021-07-19'
IF ISNULL(@SD,'')=''
SET @SD='2000-01-01'
IF ISNULL(@ED,'')=''
SET @ED='2000-01-04'
DECLARE @Dates VARCHAR(MAX)='',@index INT=0
DECLARE @pivotCols VARCHAR(MAX)=''
DECLARE @queryCols VARCHAR(MAX)=''
DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
DECLARE @endIndex INT=@pageSize*@pageIndex+1
DECLARE @cols TABLE(col VARCHAR(20))

WHILE DATEADD(DAY,@index,@SD)<=@ED
BEGIN
	SET @Dates=@Dates+CONVERT(VARCHAR(10),DATEADD(DAY,@index,@SD))+','
	SET @pivotCols=@pivotCols+'['+CONVERT(VARCHAR(10),DATEADD(DAY,@index,@SD))+'],'
			 INSERT INTO @cols
	        ( col )
	VALUES  ( CONVERT(VARCHAR(10),DATEADD(DAY,@index,@SD)) -- col - varchar(20)
	          )
	IF @index!=0
	BEGIN
		SET @queryCols=@queryCols+'['+CONVERT(VARCHAR(10),DATEADD(DAY,@index,@SD))+'],'+'IsNull(['+CONVERT(VARCHAR(10),DATEADD(DAY,@index,@SD))+'],0)-'+'Isnull(['+CONVERT(VARCHAR(10),DATEADD(DAY,@index-1,@SD))+'],0) Diff'+CONVERT(VARCHAR(10),@index)+','	
		INSERT INTO @cols
	    ( col )
VALUES  ( 'Diff'+CONVERT(VARCHAR(10),@index) -- col - varchar(20)
	        )
	END
    ELSE
    BEGIN
		SET @queryCols=@queryCols+'['+CONVERT(VARCHAR(10),DATEADD(DAY,@index,@SD))+'],'		
	END 
	
	SET @index=@index+1
END
SET @Dates=LEFT(@Dates,LEN(@Dates)-1)
SET @pivotCols=LEFT(@pivotCols,LEN(@pivotCols)-1)
SET @queryCols=LEFT(@queryCols,LEN(@queryCols)-1)
IF object_id('tempdb.dbo.#TempTable1',N'U') is NOT NULL
BEGIN
	DROP TABLE #TempTable1
END 
IF object_id('tempdb.dbo.#TempTable',N'U') is NULL
BEGIN
CREATE TABLE #TempTable
(	 
LotID VARCHAR(50),--委外单
Device VARCHAR(100),
Date VARCHAR(50),	
TotalQty INT
)
END
ELSE 
BEGIN
TRUNCATE TABLE #TempTable
END

;
WITH 
datas AS
(
SELECT b.*,a.* FROM dbo.Auctus_Chip a RIGHT JOIN 
(SELECT b.*,a.LOTID LotNo,a.device DeviceName FROM (SELECT DISTINCT lotid,device FROM dbo.Auctus_Chip) a,
(SELECT * FROM dbo.fun_Cust_StrToTable2(@Dates,',')) b 
WHERE PATINDEX('%'+ISNULL(@LotID,'')+'%',a.LOTID)>0 AND  PATINDEX('%'+ISNULL(@Device,'')+'%',a.Device)>0
)
b ON a.LOTID=b.LotNo AND a.Date=b.strID
),
data1 AS
(
SELECT
a.LotNo LotID,a.DeviceName Device,a.strid Date
,SUM(ISNULL(a.Unissue,0)+ISNULL(a.Tape,0)+ISNULL(a.GrindingSawing,0)+ISNULL(a.DieAttach,0)+
ISNULL(a.WireBond,0)+ISNULL(a.Molding,0)+ISNULL(a.Deflash,0)+ISNULL(a.Marking,0)+
ISNULL(a.Plating,0)+ISNULL(a.Singulation,0)+ISNULL(a.ISSUEFT,0)+ISNULL(a.FBAKING,0)+
ISNULL(a.BBT,0)+ISNULL(a.FT,0)+ISNULL(a.QA,0)+ISNULL(a.BAKING,0)+
ISNULL(a.LS,0)+ISNULL(a.Packing,0)+ISNULL(a.CloseQty,0))CloseQty
FROM datas a
GROUP BY a.LotNo,a.strid,a.DeviceName
)
INSERT INTO #TempTable
        ( LotID,Device, Date, TotalQty )
SELECT * FROM data1 

DECLARE @sql NVARCHAR(MAX)=''
SET @sql='With Result AS
(
SELECT * FROM #TempTable a 
PIVOT (
SUM(TotalQty) FOR Date IN ('+@pivotCols+')
)s
)
SELECT a.LOTID,a.Device,'+@queryCols+' into #TempTable1
FROM Result a ; 
SELECT * FROM (SELECT a.*,ROW_NUMBER()OVER(ORDER BY a.LotID)RN FROM #TempTable1 a) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
SELECT Count(1)TotalCount FROM #TempTable1
'



EXEC sp_executesql @sql,N'@beginIndex int,@endIndex int',@beginIndex,@endIndex

SELECT * FROM @cols

END 