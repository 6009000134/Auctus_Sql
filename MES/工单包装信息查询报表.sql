/*
工单包装信息查询报表
*/
ALTER PROCEDURE [dbo].[sp_PackReport]
(
@WorkOrder VARCHAR(100)
--@UserName varchar(100)
)
AS

BEGIN 

--DECLARE @WorkOrder VARCHAR(100),@UserName VARCHAR(100)
--SET @WorkOrder='MO-30190814024'
SET @WorkOrder='%'+ISNULL(@WorkOrder,'')+'%'
--SET @UserName='%'+ISNULL(@UserName,'')+'%'
IF object_id('tempdb.dbo.#tempResult') is NULL
BEGIN
	CREATE TABLE #tempResult(CreateDate NVARCHAR(40),InternalCode VARCHAR(100),SNCode VARCHAR(100),PalletCode VARCHAR(50),BoxNumber INT,WorkOrder VARCHAR(100),UserName NVARCHAR(10)	)
END 
ELSE
BEGIN
	TRUNCATE TABLE #tempResult
END
INSERT INTO #tempResult
SELECT     A.CreateDate,g.InternalCode,A.SNCode,
        B.PalletCode ,
        B.BoxNumber ,
        D.WorkOrder ,
        ISNULL(f.UserName,a.CreateBY)UserName
FROM    opPackageChild AS A
        INNER JOIN opPackageDetail AS B ON A.PackDetailID = B.ID
        INNER JOIN opPackageMain AS C ON C.ID = B.PackMainID
        INNER JOIN mxqh_plAssemblyPlanDetail AS D ON D.ID = C.AssemblyPlanDetailID
		LEFT JOIN dbo.vw_baInternalAndSNCode g ON a.SNCode=g.SNCode
        LEFT JOIN dbo.syUser AS f ON f.LoginID = A.createBy
WHERE   PATINDEX(@WorkOrder,D.WorkOrder)>0 --AND PATINDEX(@UserName,ISNULL(f.UserName,''))>0

;
WITH data1 AS
(
SELECT g.OriInternalCode,g.OriSNCode,a.SNCode,g.InternalCode,0 lv FROM #tempResult a INNER JOIN 
		(
		SELECT InternalCode,SNCode FROM dbo.vw_baInternalAndSNCode 
		UNION ALL 
		SELECT InternalCode,SNCode1 FROM opInternalToSNCode
		) f ON a.SNCode=f.SNCode
		INNER JOIN opProductReworkNewBSN g ON f.InternalCode=g.InternalCode
		UNION ALL
        SELECT b.OriInternalCode,b.OriSNCode,a.SNCode,a.InternalCode,lv+1 FROM data1 a INNER JOIN opProductReworkNewBSN b ON a.OriInternalCode=b.InternalCode
),
oldData AS
(
SELECT *,ROW_NUMBER()OVER(PARTITION BY a.InternalCode ORDER BY lv desc)RN FROM data1 a
)
SELECT a.*,b.OriInternalCode,b.OriSNCode
FROM #tempResult a LEFT JOIN oldData b ON a.SNCode=b.SNCode

END