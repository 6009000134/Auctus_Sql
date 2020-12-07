SELECT c1.Code ParentCode,c2.Code ChildCode,a.Radix,a.ChildCount �Ӽ�����,c3.Code SubCode,b.Radix,b.ChildCount ���������
FROM dbo.MAT_MaterialRelation a 
INNER JOIN dbo.MAT_Substitute b ON a.ChildVerId=b.SourceVerId AND a.ParentVerId=b.ParentVerId
INNER JOIN dbo.MAT_MaterialVersion c1 ON a.ParentVerId=c1.MaterialVerId
INNER JOIN dbo.MAT_MaterialVersion c2 ON a.ChildVerId=c2.MaterialVerId
INNER JOIN dbo.MAT_MaterialVersion c3 ON b.TargetVerId=c3.MaterialVerId
WHERE (a.ChildCount<>b.ChildCount or a.Radix<>b.Radix) AND c1.IsFrozen=0 AND c1.IsEffect=1







--SELECT * FROM dbo.ImportNewBom WHERE  �Ϻ� IN ('307040026','307040020','335190044','335190034')
