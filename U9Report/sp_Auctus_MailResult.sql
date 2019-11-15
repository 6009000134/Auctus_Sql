/*
��ѯ�ʼ����ͽ��
*/
ALTER PROC sp_Auctus_MailResult
(
@pageSize INT,
@pageIndex INT,
@Date VARCHAR(20)
)
AS
BEGIN
	--DECLARE @pageSize INT=10000,
	--		@pageIndex INT=1,
	--		--@Date VARCHAR(20)='2019-09-05'
	--		@Date VARCHAR(20)=''
	DECLARE @beginIndex INT=@pageSize*(@pageIndex-1)
	DECLARE @endIndex INT=@pageSize*@pageIndex+1
	SET @Date='%'+ISNULL(@Date,'')+'%'	
	SELECT * FROM (
	SELECT a.Subject,a.[FROM],a.[To],a.CC,FORMAT(sent_date,'yyyy-MM-dd HH:mm:ss')Sent_Date
	,CASE WHEN sent_status=1 THEN '�ɹ�' WHEN sent_status=0 THEN 'ʧ��' END Sent_Status,ROW_NUMBER()OVER(ORDER BY sent_date DESC )RN
	FROM Auctus_MailLog a  
	  WHERE PATINDEX(@Date,FORMAT(sent_date,'yyyy-MM-dd'))>0 
	  AND 	  a.Subject='��Ӧ�����󽻻��ƻ�'
	  )t WHERE t.RN>@beginIndex AND t.RN<@endIndex
	
	SELECT COUNT(1)Count
	FROM Auctus_MailLog a 
	  WHERE PATINDEX(@Date,FORMAT(sent_date,'yyyy-MM-dd'))>0 AND 
	  a.subject='��Ӧ�����󽻻��ƻ�'
END 

