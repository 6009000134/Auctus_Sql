SET NOCOUNT ON 
IF object_id('tempdb.dbo.#tempTable') is NULL
CREATE TABLE #tempTable(ID INT,Code VARCHAR(50),Code2 VARCHAR(50))
ELSE
TRUNCATE TABLE #tempTable

INSERT INTO #tempTable
        ( ID, Code, Code2 )
	SELECT ID,ComCode,rComCode FROM dbo.BOMData

DECLARE @ID VARCHAR(MAX),@AllIDs VARCHAR(MAX)=''

IF object_id('tempdb.dbo.#tempIDs') is NULL
CREATE TABLE #tempIDs(OrderNo INT,IDs VARCHAR(MAX))
ELSE
TRUNCATE TABLE #tempIDs

DECLARE @index INT=1
DECLARE cur CURSOR
FOR
SELECT ID FROM #tempTable
OPEN cur
	FETCH NEXT FROM cur INTO @ID
	WHILE @@FETCH_STATUS=0
	BEGIN
		IF NOT  EXISTS(SELECT 1 FROM dbo.fun_Cust_StrToTable(@AllIDs) WHERE strID=@ID)
		BEGIN
			SET @AllIDs=(SELECT dbo.F_GetIDS(@ID))		
			INSERT INTO #tempIDs
		        ( OrderNo,IDs )
			VALUES  ( @index,@AllIDs  -- IDs - varchar(max)		     
		     )
			 --IF @index=127
			 --BEGIN
				--SELECT @AllIDs
				--SELECT * FROM #tempTable WHERE ID IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@AllIDs)) AND ID<>@ID
			 --END 
			 DELETE FROM #tempTable WHERE ID IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@AllIDs))-- AND ID<>@ID
			 SET @index=@index+1
		END 
		FETCH NEXT FROM cur INTO @ID
	END 
CLOSE cur
DEALLOCATE cur

DECLARE @OrderNo INT,@IDs VARCHAR(MAX) ,@FinalCode VARCHAR(50),@IsFirst INT=0

DECLARE cur2 CURSOR
FOR
SELECT orderNO,ids FROM #tempIDs
OPEN cur2
FETCH NEXT FROM cur2 INTO @OrderNo,@IDs
WHILE @@FETCH_STATUS=0
BEGIN
	SET @IsFirst=0
	DECLARE cur3 CURSOR
	FOR
	SELECT comcode FROM
    (
	SELECT a.ComCode FROM dbo.BOMData a WHERE a.ID IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@IDs))
	UNION
    SELECT a.rComCode FROM dbo.BOMData a WHERE a.ID IN (SELECT strID FROM dbo.fun_Cust_StrToTable(@IDs))
	) t ORDER BY t.ComCode
	OPEN cur3
	FETCH NEXT FROM cur3 INTO @FinalCode
	WHILE @@FETCH_STATUS=0
	BEGIN
		IF @IsFirst=0
		INSERT INTO dbo.FinalData2  ( ID ,Code) VALUES(@OrderNo,@FinalCode)
		IF @IsFirst=1
		UPDATE dbo.FinalData2 SET code1=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=2
		UPDATE dbo.FinalData2 SET code2=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=3
		UPDATE dbo.FinalData2 SET code3=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=4
		UPDATE dbo.FinalData2 SET code4=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=5
		UPDATE dbo.FinalData2 SET code5=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=6
		UPDATE dbo.FinalData2 SET code6=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=7
		UPDATE dbo.FinalData2 SET code7=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=8
		UPDATE dbo.FinalData2 SET code8=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=9
		UPDATE dbo.FinalData2 SET code9=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=10
		UPDATE dbo.FinalData2 SET code10=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=11
		UPDATE dbo.FinalData2 SET code11=@FinalCode WHERE ID=@OrderNo
		IF @IsFirst=12
		UPDATE dbo.FinalData2 SET code12=@FinalCode WHERE ID=@OrderNo
		SET @IsFirst=@IsFirst+1
		FETCH NEXT FROM cur3 INTO @FinalCode
	END 
	CLOSE cur3
	DEALLOCATE cur3
	FETCH NEXT FROM cur2 INTO @OrderNo,@IDs
END 
CLOSE cur2
DEALLOCATE cur2

SELECT * FROM dbo.FinalData2

--DELETE FROM dbo.FinalData2

--SELECT count(*) from tempdb.dbo.syscolumns where id = object_id('tempdb..#temptable')

--SELECT DISTINCT * FROM #tempIDS
--SELECT DISTINCT strID FROM dbo.fun_Cust_StrToTable((SELECT IDs+',' FROM #tempIDS FOR XML PATH('')))

--SELECT DISTINCT * FROM dbo.FinalData2

--SELECT a.ID,a.Code,a.code1,a.code2,b.ID,b.code,b.code1,b.code2 FROM dbo.FinalData2 a LEFT JOIN dbo.FinalData2 b ON (a.Code=b.Code OR a.Code=b.Code1 OR a.Code=b.Code2 OR a.Code=b.Code3 OR a.Code=b.Code4) AND a.ID<>b.ID
--WHERE a.id IN (127,128,225,447)
--ORDER BY a.ID

--SELECT * FROM #tempIDs
--127
--128
--225
--447
--SELECT * FROM #tempIDs WHERE orderno IN (127,128,225,447)

