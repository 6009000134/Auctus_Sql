SELECT * 
FROM dbo.MAT_MaterialVersion a INNER JOIN Temp84 b ON a.Code=b.�Ϻ�
WHERE a.IsEffect=1
--UPDATE dbo.MAT_MaterialVersion SET --Name=a.Ʒ��,
--Spec=a.�����Ĺ������
--FROM dbo.Temp84 a WHERE a.�Ϻ�=dbo.MAT_MaterialVersion.Code
--AND dbo.MAT_MaterialVersion.IsEffect=1

--UPDATE dbo.MAT_MaterialVersion SET Name=a.��������,Spec=a.�������
--,Updater='73F0DDCF-2431-4B95-A4D5-538100DAD868',UpdateDate=FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')
--FROM dbo.TempTest a WHERE a.�Ϻ�=dbo.MAT_MaterialVersion.Code
--AND dbo.MAT_MaterialVersion.IsEffect=1

--73F0DDCF-2431-4B95-A4D5-538100DAD868
--SELECT * FROM dbo.SM_Users WHERE UserName='Ф��'

