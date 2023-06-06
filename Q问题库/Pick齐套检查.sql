--WMO-30221115007
DECLARE @DocNo VARCHAR(20)='AMO-30230321025'
DECLARE @DocLineNo VARCHAR(1000)='80,100'
/*
SELECT a.ID,a.ItemMaster,a.IssueStyle,a.DocLineNO,a.MOStartSetCheck,a.MOCompleteSetCheck 
FROM dbo.MO_MOPickList a WHERE a.MO=1002209160035043
AND a.IssueStyle=0
AND a.DocLineNO IN (SELECT strID from dbo.fun_Cust_StrToTable(@DocLineNo))
*/
--更新开工、完工齐套检查属性
UPDATE MO_MOPickList SET MOStartSetCheck=0,MOCompleteSetCheck=0 WHERE MO=(SELECT id FROM dbo.MO_MO a WHERE a.DocNo=@DocNo) AND IssueStyle=0 AND DocLineNO IN (SELECT strID from dbo.fun_Cust_StrToTable(@DocLineNo))
--UPDATE MO_MOPickList SET MOStartSetCheck=1,MOCompleteSetCheck=1 WHERE MO=(SELECT id FROM dbo.MO_MO a WHERE a.DocNo=@DocNo) AND IssueStyle=0 AND DocLineNO IN (SELECT strID from dbo.fun_Cust_StrToTable(@DocLineNo))

