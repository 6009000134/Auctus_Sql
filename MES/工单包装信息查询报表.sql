/*
工单包装信息查询报表
*/
alter PROC sp_PackReport
(
@WorkOrder VARCHAR(100)
--@UserName varchar(100)
)
AS

BEGIN 

--DECLARE @WorkOrder VARCHAR(100),@UserName VARCHAR(100)
--SET @WorkOrder='3114'
SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
--SET @UserName='%'+ISNULL(@UserName,'')+'%'
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
        ISNULL(f.UserName,a.CreateBY)UserName
		--,f.UserName,a.createby
FROM    opPackageChild AS A
        INNER JOIN opPackageDetail AS B ON A.PackDetailID = B.ID
        INNER JOIN opPackageMain AS C ON C.ID = B.PackMainID
        INNER JOIN mxqh_plAssemblyPlanDetail AS D ON D.ID = C.AssemblyPlanDetailID
        LEFT JOIN dbo.syUser AS f ON f.LoginID = A.createBy
WHERE   PATINDEX(@WorkOrder,D.WorkOrder)>0 --AND PATINDEX(@UserName,ISNULL(f.UserName,''))>0

SELECT a.*,e.InternalCode FROM #tempResult a  INNER JOIN baInternalAndSNCode AS e ON e.SNCode = A.SNCode
ORDER BY a.BoxNumber 
END 

--SELECT * FROM #tempResult a

