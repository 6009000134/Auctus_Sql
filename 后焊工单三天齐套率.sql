--后焊工单的三天齐套率
/*

*/
CREATE PROC sp_Auctus_HMOFullSetRate
(
@Date DATETIME,
@Org BIGINT
)
AS
BEGIN
--DECLARE @Date DATETIME=GETDATE()
--DECLARE @Org BIGINT=(SELECT ID FROM dbo.Base_Organization WHERE code='300')

--齐套分析结果
IF OBJECT_ID(N'tempdb.dbo.#tempLackDoc',N'U') IS NULL
BEGIN 
CREATE TABLE #tempLackDoc
(
DocNo VARCHAR(50),
ActualReqQty DATETIME
)
END 
ELSE
BEGIN 
TRUNCATE TABLE #tempLackDoc
END 
--执行齐套分析的存储过程，抓出目前为止未齐套的料品
--EXEC sp_Auctus_GetLackDoc @Date,@Org
INSERT INTO #tempLackDoc
SELECT  a.DocNo,MAX(a.ActualReqDate)ActualReqDate
FROM dbo.Auctus_SetCheckResult a
WHERE a.LackAmount<0
GROUP BY a.DocNo

DECLARE @result DECIMAL(18,4)

;
WITH MO AS--当月所有的H工单
(
SELECT a.ID,a.StartDate,a.DocNo,a.DocState FROM dbo.MO_MO a WHERE DATEADD(DAY,-3,a.StartDate)<GETDATE()
AND a.Cancel_Canceled=0 --AND a.IsHoldRelease=0
AND a.DocState<>3
AND a.DocNo LIKE 'H%'
--ORDER BY a.StartDate
)
SELECT @result=(SELECT COUNT(*) FROM MO a LEFT JOIN #tempLackDoc b ON a.DocNo=b.DocNo
WHERE b.DocNo IS NULL)/(SELECT CONVERT(DECIMAL(18,2),COUNT(*)) FROM MO)

INSERT INTO Auctus_FullSetRate(CreateON,Rate,Type) VALUES(GETDATE(),@result*100,'HMO')

SELECT CONVERT(VARCHAR(10),@result*100)+'%'


END 
























	 