/*
��ȡ���������
*/
ALTER PROC sp_GetMouldModifyDetail
(
@ID INT
)
AS
BEGIN
	
	--DECLARE @ID INT=10
	--�������Ϣ
	SELECT a.MouldID,a.DocNo,a.Code,a.Name,a.SPECS
	FROM dbo.MouldModify a 
	WHERE a.ID=@ID
	--������ݺ�ԭ����
	SELECT a.ID,b.CreateBy ,FORMAT(b.CreateDate,'yyyy-MM-dd HH:mm:ss')CreateDate ,a.HoleNum ,a.Code ,a.Name ,a.SPECS ,a.TotalNum  ,a.DailyCapacity ,a.DailyNum ,a.RemainNum ,a.Holder ,a.Manufacturer 
	,a.CycleTime ,FORMAT(a.DealDate,'yyyy-MM-dd')DealDate,a.ProductWeight ,a.NozzleWeight ,FORMAT(a.EffectiveDate,'yyyy-MM-dd') EffectiveDate,a.Remark 
	FROM  dbo.MouldModify a INNER JOIN dbo.Mould b ON a.MouldID=b.ID
	WHERE a.ID=@ID	
	UNION  ALL
	SELECT a.ID,b.CreateBy ,FORMAT(b.CreateDate,'yyyy-MM-dd HH:mm:ss')CreateDate ,a.HoleNum ,a.Code ,a.Name ,a.SPECS ,a.TotalNum  ,a.DailyCapacity ,a.DailyNum ,a.RemainNum ,a.Holder ,a.Manufacturer 
	,a.CycleTime ,FORMAT(a.DealDate,'yyyy-MM-dd')DealDate,a.ProductWeight ,a.NozzleWeight ,FORMAT(a.EffectiveDate,'yyyy-MM-dd') EffectiveDate,a.Remark 
	FROM  dbo.MouldModify a INNER JOIN dbo.Mould b ON a.MouldID=b.ID
	WHERE a.ID=@ID	
	--����ֶμ���
	SELECT * FROM dbo.MouldModifySeg a WHERE a.ModifyID=@ID
END 

