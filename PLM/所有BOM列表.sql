	SELECT  t.code+',' FROM 
	(
	SELECT  DISTINCT a.Code FROM 
	(
		SELECT  MaterialVerId, Code, Name, VerCode, IsFrozen, IsEffect, IsBlankOut,
		 ROW_NUMBER()OVER(PARTITION BY Code ORDER BY VerCode DESC)rowNum FROM dbo.MAT_MaterialVersion 
	) a
	WHERE IsEffect = 1 AND IsBlankOut = 0 AND a.IsFrozen = 0
	AND (code LIKE '1%' OR code LIKE '2%')
	--AND a.Code='103010104'
	) t ORDER BY t.Code --FOR XML PATH('')

	


	SELECT  DISTINCT a.Code+',' FROM 
	(
		SELECT  MaterialVerId, Code, Name, VerCode, IsFrozen, IsEffect, IsBlankOut,
		 ROW_NUMBER()OVER(PARTITION BY Code ORDER BY VerCode DESC)rowNum FROM dbo.MAT_MaterialVersion 
		 WHERE DesignCycle IN (1,2)
	) a
	WHERE IsEffect = 1 AND IsBlankOut = 0 AND a.IsFrozen = 0
	AND (code LIKE '1%' OR code LIKE '1%') 
	 FOR XML PATH ('')

		SELECT  DISTINCT a.Code+',' FROM 
	(
		SELECT  MaterialVerId, Code, Name, VerCode, IsFrozen, IsEffect, IsBlankOut,
		 ROW_NUMBER()OVER(PARTITION BY Code ORDER BY VerCode DESC)rowNum FROM dbo.MAT_MaterialVersion 
		 WHERE DesignCycle IN (3,4)
	) a
	WHERE IsEffect = 1 AND IsBlankOut = 0 AND a.IsFrozen = 0
	AND (code LIKE '1%' OR code LIKE '1%')
	--FOR XML PATH ('')
		 
		 SELECT DISTINCT * FROM finalbom

		 SELECT DISTINCT * FROM dbo.ImportNewBom WHERE 类型='电子'
		 


	