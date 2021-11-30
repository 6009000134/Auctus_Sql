
BEGIN

--������Ʒ-�������� ����չ�ֶ����ݲ�һ�µ�
IF EXISTS (SELECT 1 FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'TEMPDB..#TempTable') AND TYPE='U')
BEGIN
	DROP TABLE #TempTable
END 


;
WITH HasBrand AS--��Ʒ-��������
(
SELECT c.MaterialVerId,c.Code,c.Name
FROM dbo.MAT_MaterialVersion c INNER JOIN temp0926 b ON c.Code=b.�Ϻ�
),
Mat AS
(
SELECT a.MaterialVerId,a.Code,a.Name,a.VerCode 
FROM dbo.MAT_MaterialVersion a WHERE a.IsEffect=1
AND PATINDEX('3%',a.Code)>0
),
ExtendData AS--����չ�ֶε���Ʒ
(
SELECT a.*,b.ExtendName FROM dbo.MAT_Extend a INNER JOIN dbo.PS_ExtendSettings b ON a.SettingsId=b.SettingsId
WHERE b.ExtendName='����ģʽ' 
),
NoneExtendData AS--����Ʒ-�������ݣ�����û����չ�ֶ���Ʒ����
(
SELECT * FROM HasBrand a LEFT JOIN ExtendData b ON a.MaterialVerId=b.ObjectId
WHERE ISNULL(b.ObjectExtendId,'')=''
),
BrandList AS
(
SELECT DISTINCT a.MaterialVerId,a.Code,a.Name
FROM HasBrand a
)
SELECT a.*,b.ObjectExtendId,b.PropertyValue
,CASE WHEN ISNULL(b.ObjectExtendId,'')='' THEN 'Add' ELSE 'Update' END OperateType
INTO #TempTable
FROM BrandList a 
LEFT JOIN ExtendData b ON a.MaterialVerId=b.ObjectId



--IF EXISTS(SELECT 1 FROM #TempTable a WHERE a.OperateType='Update')
--BEGIN
--	UPDATE dbo.MAT_Extend SET PropertyValue=a.BrandList 
--	FROM #TempTable a 
--	WHERE a.OperateType='Update' AND a.ObjectExtendId=dbo.MAT_Extend.ObjectExtendId
--END 



IF EXISTS(SELECT 1 FROM #TempTable a WHERE a.OperateType='Add')
BEGIN
	;
	WITH AddData AS--������չ�ֶ����ݼ���
	(
	SELECT * FROM #TempTable a WHERE a.OperateType='Add'
	)
	INSERT INTO dbo.MAT_Extend
	        ( ObjectExtendId ,
	          SettingsId ,
	          ObjectId ,
	          PropertyValue
	        )
	SELECT NEWID(),e.SettingsId,a.MaterialVerId,m.PropertyValue
	FROM dbo.MAT_MaterialVersion a INNER JOIN AddData m ON a.MaterialVerId=m.MaterialVerId 
	LEFT JOIN dbo.MAT_MaterialBase b ON a.BaseId=b.BaseId
	LEFT JOIN dbo.PS_BusinessCategory c ON b.CategoryId=c.CategoryId 
	LEFT JOIN dbo.PS_ExtendSettings e ON c.CategoryId=e.CategoryId
	WHERE ISNULL(e.ExtendName,'')='����ģʽ' AND a.MaterialVerId!='a914916e-b457-412b-973c-742598968de5'
END 

END 
