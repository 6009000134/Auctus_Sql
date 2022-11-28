SELECT a.Principal,* FROM dbo.PJ_WorkPiece a WHERE a.WorkCode='YJ003'
SELECT * FROM dbo.v_auctus_ProjectDetail WHERE ProjectCode='YJ003'
SELECT * FROM dbo.LT_WorkHourFill WHERE WorkId='D6055E4C-F0EE-4308-AB98-E5ECBC1619CE'
SELECT * FROM dbo.LT_WorkHourFill WHERE WorkId='CC88922B-A73E-423E-88F7-9C2EED6F5BA7'

--DELETE FROM dbo.LT_WorkHourFill WHERE RelationId='357698-3863-4742'
--DELETE FROM dbo.LT_WorkHourFill WHERE RelationId='357540-3826-4698'

SELECT * FROM dbo.SM_Users WHERE UserName='∫Œ”¿øµ'
--357540-3826-4698
SELECT 
a.*,b.WorkCode,b.WorkName
FROM dbo.LT_WorkHourFill  a LEFT JOIN dbo.PJ_WorkPiece b ON a.WorkId=b.WorkId
WHERE CreateUser='8C0E102A-4AE5-4359-9CB3-EBFCDE9BDBAD'
AND FillDate='2022-06-15'
