/*
PLM未同步到U9料号邮件推送出来
需求：2019-11-2号后建立的料品的“相关过程”页签中没有“料号手动同步U9系统”流程的料品列表
*/
CREATE PROC sp_Auctus_NotSyncMaterials
AS
BEGIN

DECLARE @html NVARCHAR(MAX)=''

;
WITH data1 AS
(
SELECT a.MaterialVerId,a.BaseId,a.CreateDate,a.Code,a.Name,a.Spec FROM dbo.MAT_MaterialVersion a  WHERE a.IsEffect=1 AND a.IsFrozen=0 AND PATINDEX('3%',a.Code)>0 AND a.CreateDate>'2019-11-1'
),
SyncData AS
(
Select BaseId,UserId,VerId,BaseCode [流程编码],BaseName [流程名称],UserName [创建人]
,CreateDate [创建时间],BaseState [状态] from v_DocDetail_CorrelateWorkflow where --VerId = 'ee859026-05e8-488e-84f6-488f16feb7e3'
VerId IN (SELECT materialVerid FROM data1)
And  LanguageId = 0 AND BaseName='料号手动同步U9系统'
)
SELECT @html=@html+N'<H2 bgcolor="#7CFC00">PLM未同步到U9的料品</H2>'
+N'<table border="1">'
+N'<tr bgcolor="#cae7fc"><th nowrap="nowrap">创建日期</th><th nowrap="nowrap">料号</th><th nowrap="nowrap">品名</th><th nowrap="nowrap">规格</th><th nowrap="nowrap">业务类型</th></tr>'
+ISNULL(CONVERT(NVARCHAR(MAX),
(SELECT td=a.CreateDate,'',td=a.Code,'',td=a.Name,'',td=ISNULL(a.Spec,''),'',td=d.CategoryName,''--,b.流程名称 
FROM data1 a LEFT JOIN SyncData b ON a.MaterialVerId=b.VerId
LEFT JOIN dbo.MAT_MaterialBase c ON a.BaseId=c.BaseId LEFT JOIN dbo.PS_BusinessCategory d ON c.CategoryId=d.CategoryId
WHERE ISNULL(b.BaseId,'')='' ORDER BY d.CategoryName,a.Code
FOR XML PATH('tr'))
),'')+'</table></br>'

declare @strbody varchar(800)
declare @style Varchar(200)
SET @style=	'<style>table,table tr th, table tr td { border:2px solid #cecece; } table {text-align: center; border-collapse: collapse; padding:2px;}</style>'
set @strbody=@style+N'<H2>Dear All,</H2><H2></br>&nbsp;&nbsp;以下是PLM未同步到U9的料品信息（仅限3打头料品），请相关人员知悉。谢谢！</H2>'
set @html=@strbody+@html+N'</br><H2>以上由系统发出无需回复!</H2>'
 --发送邮件
 EXEC msdb.dbo.sp_send_dbmail 
	@profile_name=PLM自动发邮件, 
	--@recipients='liufei@auctus.com;', 
	@recipients=' sourcing@auctus.cn;', 
	@copy_recipients='perla_yu@auctus.cn;xiaoli@auctus.cn;huangxh@auctus.cn',
	--@blind_copy_recipients='liufei@auctus.com',
	@subject ='PLM未同步到U9料品',
	@body = @html,
	@body_format = 'HTML'; 

END 