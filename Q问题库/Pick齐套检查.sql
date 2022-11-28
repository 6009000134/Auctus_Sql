--WMO-30221115007
SELECT * FROM dbo.MO_MO a WHERE a.DocNo='AMO-30220916003'

SELECT a.ID,a.ItemMaster,a.IssueStyle,a.DocLineNO,a.MOStartSetCheck,a.MOCompleteSetCheck FROM dbo.MO_MOPickList a WHERE a.MO=1002209163727093
AND a.IssueStyle=0

UPDATE MO_MOPickList SET MOStartSetCheck=1,MOCompleteSetCheck=1 WHERE MO=1002209163727093 AND IssueStyle=0 AND DocLineNO IN (0)

