/*
杂发单BE插件
“制损退料单”、“返工制损退料单”退料确认后会自动生成杂发单、杂收单，
当存在下游杂收单时，不允许弃审，需要先删除上述功能生成的杂收单。
*/
Alter PROC sp_Auctus_BE_MiscShip
(
@DocNo NVARCHAR(100),
@Result NVARCHAR(MAX) OUT--1代表功能打开
)
AS
BEGIN
--DECLARE @DocNo NVARCHAR(100)='MR30190419003'
--DECLARE @Result NVARCHAR(MAX)
DECLARE @Org BIGINT=1001708020135665
DECLARE @MoIssueDoc VARCHAR(50)--退料单号
DECLARE @MoIssueDocLine VARCHAR(50) --退料行
DECLARE @MiscRcvDoc VARCHAR(50)--杂收单号
DECLARE @MiscRcvDocLine VARCHAR(50)--杂收行
;
WITH MiscRcv AS
(
SELECT a.DocNo,b.DocLineNo,b.DescFlexSegments_PrivateDescSeg29,b.DescFlexSegments_PrivateDescSeg30 
FROM dbo.InvDoc_MiscRcvTrans a INNER JOIN dbo.InvDoc_MiscRcvTransL b ON a.ID=b.MiscRcvTrans
WHERE a.Org=@Org
)
SELECT @MoIssueDoc=ISNULL(b.DescFlexSegments_PrivateDescSeg29,''),@MoIssueDocLine=ISNULL(b.DescFlexSegments_PrivateDescSeg30 ,'')
,@MiscRcvDoc=ISNULL(c.DocNo,''),@MiscRcvDocLine=ISNULL(b.DocLineNo ,'')
FROM dbo.InvDoc_MiscShip a INNER JOIN dbo.InvDoc_MiscShipL b ON a.ID=b.MiscShip
LEFT JOIN MiscRcv c ON ISNULL(b.DescFlexSegments_PrivateDescSeg29,'AAA')=ISNULL(c.DescFlexSegments_PrivateDescSeg29,'') AND ISNULL(b.DescFlexSegments_PrivateDescSeg30,'AAA')=ISNULL(c.DescFlexSegments_PrivateDescSeg30,'')--设置AAA是防止当扩展字段值全部为空时的问题
WHERE a.DocNo=@DocNo
IF ISNULL(@MiscRcvDoc,'')<>''--杂收单不为空，不允许弃审
BEGIN
SET @Result='此单据为退料单'+ISNULL(@MoIssueDoc,'')+'-'+ISNULL(@MoIssueDocLine,'')+'自动生成单据，'+'需要先删除杂收单'+@MiscRcvDoc+'-'+@MiscRcvDocLine
END 
ELSE
BEGIN
SET @Result='1'
END 

END 