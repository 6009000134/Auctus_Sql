/*
工单包装信息查询报表
*/
alter PROC sp_PackReport
(
@WorkOrder VARCHAR(100)
)
AS

BEGIN 

--DECLARE @WorkOrder VARCHAR(100)
--SET @WorkOrder='3114'
SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
IF object_id('tempdb.dbo.#tempResult') is NULL
BEGIN
	CREATE TABLE #tempResult(CreateDate NVARCHAR(40),SNCode VARCHAR(100),PalletCode VARCHAR(50),BoxNumber INT,WorkOrder VARCHAR(100),UserName NVARCHAR(10)	)
END 
ELSE
BEGIN
	TRUNCATE TABLE #tempResult
END
INSERT INTO #tempResult
SELECT  A.CreateDate,A.SNCode,
        B.PalletCode ,
        B.BoxNumber ,
        D.WorkOrder ,
        f.UserName
FROM    opPackageChild AS A
        INNER JOIN opPackageDetail AS B ON A.PackDetailID = B.ID
        INNER JOIN opPackageMain AS C ON C.ID = B.PackMainID
        INNER JOIN mxqh_plAssemblyPlanDetail AS D ON D.ID = C.AssemblyPlanDetailID
        INNER JOIN syUser AS f ON f.ID = A.OperatorID
WHERE   PATINDEX(@WorkOrder,D.WorkOrder)>0

SELECT a.*,e.InternalCode FROM #tempResult a  INNER JOIN baInternalAndSNCode AS e ON e.SNCode = A.SNCode
ORDER BY a.BoxNumber 
END 