SELECT * 
FROM dbo.MAT_MaterialVersion a INNER JOIN Temp84 b ON a.Code=b.料号
WHERE a.IsEffect=1
--UPDATE dbo.MAT_MaterialVersion SET --Name=a.品名,
--Spec=a.变更后的规格描述
--FROM dbo.Temp84 a WHERE a.料号=dbo.MAT_MaterialVersion.Code
--AND dbo.MAT_MaterialVersion.IsEffect=1

--UPDATE dbo.MAT_MaterialVersion SET Name=a.物料名称,Spec=a.规格描述
--,Updater='73F0DDCF-2431-4B95-A4D5-538100DAD868',UpdateDate=FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')
--FROM dbo.TempTest a WHERE a.料号=dbo.MAT_MaterialVersion.Code
--AND dbo.MAT_MaterialVersion.IsEffect=1

--73F0DDCF-2431-4B95-A4D5-538100DAD868
--SELECT * FROM dbo.SM_Users WHERE UserName='肖丽'

