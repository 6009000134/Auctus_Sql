SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sp_GetRDRcvList]
(
@DocNo VARCHAR(50),@SD DATETIME,@ED DATETIME,@Project VARCHAR(100)
,@pageSize INT,@pageIndex int
)
AS
BEGIN

	--DECLARE @DocNo VARCHAR(50),@SD DATETIME,@ED DATETIME,@Project VARCHAR(100)
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	SET @DocNo='%'+ISNULL(@DocNo,'')+'%'
	SET @Project='%'+ISNULL(@Project,'')+'%'
	IF ISNULL(@SD,'')=''
	SET @SD='2000-01-01'
	IF ISNULL(@ED,'')=''
	SET @ED='9999-01-01'
	SELECT * FROM (
	SELECT a.ID,a.DocNo,a.DocType,a.Operator,FORMAT(a.RcvDate,'yyyy-MM-dd')RcvDate,a.ProjectID,a.ProjectCode,a.ProjectName
	,STUFF((SELECT DISTINCT '||'+t.MaterialCode FROM dbo.TP_RDRcvDetail t WHERE t.RcvID=a.ID FOR XML PATH('')),1,2,'')MaterialCode
	,STUFF((SELECT DISTINCT '||'+t.MaterialName FROM dbo.TP_RDRcvDetail t WHERE t.RcvID=a.ID FOR XML PATH('')),1,2,'')MaterialName
	,STUFF((SELECT DISTINCT '||'+ISNULL(t.Progress,'') FROM dbo.TP_RDRcvDetail t WHERE t.RcvID=a.ID FOR XML PATH('')),1,2,'')Progress
	,a.ReturnDeptID,a.DeptCode,a.DeptName,a.Borrower,a.CustomerID,a.CustomerCode,a.CustomerName,a.Remark,a.Status,a.OAFlowID,a.ApplicantID
	,(SELECT COUNT(1) FROM dbo.TP_RDRcvDetail b WHERE b.RcvID=a.ID)Count
	,ROW_NUMBER()OVER(ORDER BY a.DocNo DESC)RN
	FROM dbo.TP_RDRcv a 
	WHERE 1=1
	AND PATINDEX (@DocNo,a.DocNo)>0
	AND PATINDEX (@Project,a.ProjectName+'|'+a.ProjectCode)>0
	AND a.RcvDate>=@SD AND a.RcvDate<@ED
	)t WHERE t.RN>@beginIndex AND t.RN<@endIndex
	
	SELECT COUNT(1)Count
	FROM dbo.TP_RDRcv a 
	WHERE 1=1
	AND PATINDEX (@DocNo,a.DocNo)>0
	AND PATINDEX (@Project,a.ProjectName+'|'+a.ProjectCode)>0
	AND a.RcvDate>=@SD AND a.RcvDate<@ED
END
GO