/*
机身标签第一次打印记录
*/
CREATE PROC sp_AddBLLog
(
@SNCode nvarchar(30),
@CreateBy nvarchar(30)
)
AS
BEGIN
INSERT INTO dbo.mxqh_BodyLabelPrintLog
( CreateBy, CreateDate, SNCode )
VALUES  ( @CreateBy, -- CreateBy - varchar(30)
			GETDATE(), -- CreateDate - datetime
			@SNCode-- SNCode - nvarchar(25)
			)
END 