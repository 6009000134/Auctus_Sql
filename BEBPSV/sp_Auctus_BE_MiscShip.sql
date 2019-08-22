/*
�ӷ���BE���
���������ϵ������������������ϵ�������ȷ�Ϻ���Զ������ӷ��������յ���
�������������յ�ʱ��������������Ҫ��ɾ�������������ɵ����յ���
*/
Alter PROC sp_Auctus_BE_MiscShip
(
@DocNo NVARCHAR(100),
@Result NVARCHAR(MAX) OUT--1�����ܴ�
)
AS
BEGIN
--DECLARE @DocNo NVARCHAR(100)='MR30190419003'
--DECLARE @Result NVARCHAR(MAX)
DECLARE @Org BIGINT=1001708020135665
DECLARE @MoIssueDoc VARCHAR(50)--���ϵ���
DECLARE @MoIssueDocLine VARCHAR(50) --������
DECLARE @MiscRcvDoc VARCHAR(50)--���յ���
DECLARE @MiscRcvDocLine VARCHAR(50)--������
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
LEFT JOIN MiscRcv c ON ISNULL(b.DescFlexSegments_PrivateDescSeg29,'AAA')=ISNULL(c.DescFlexSegments_PrivateDescSeg29,'') AND ISNULL(b.DescFlexSegments_PrivateDescSeg30,'AAA')=ISNULL(c.DescFlexSegments_PrivateDescSeg30,'')--����AAA�Ƿ�ֹ����չ�ֶ�ֵȫ��Ϊ��ʱ������
WHERE a.DocNo=@DocNo
IF ISNULL(@MiscRcvDoc,'')<>''--���յ���Ϊ�գ�����������
BEGIN
SET @Result='�˵���Ϊ���ϵ�'+ISNULL(@MoIssueDoc,'')+'-'+ISNULL(@MoIssueDocLine,'')+'�Զ����ɵ��ݣ�'+'��Ҫ��ɾ�����յ�'+@MiscRcvDoc+'-'+@MiscRcvDocLine
END 
ELSE
BEGIN
SET @Result='1'
END 

END 