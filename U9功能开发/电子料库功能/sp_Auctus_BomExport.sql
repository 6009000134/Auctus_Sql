/*
BOM导出功能
*/
ALTER PROC [dbo].[sp_Auctus_BomExport]
AS
BEGIN
;
--SELECT a.line,b.DocLineNo,ISNULL(c.code,a.code)Code,ISNULL(c.SPEC,a.SPEC)Spec,a.name,Num,Version,Cost,Weight,BOMUom,BaseNum,Waste,Position,Remark 
--FROM auctus_BOM a LEFT JOIN auctus_itemmaster b ON a.code=b.code
--LEFT JOIN auctus_itemmaster c ON b.DocLineNo=c.DocLineNo
--WHERE a.No=(SELECT MAX(no) FROM auctus_BOM)
--ORDER BY a.id,b.DocLineNo

;
SELECT dbo.sp_Auctus_ExchangeLineNo(t1.rr,t1.Line)Line,t1.Code,t1.Spec,t1.name,Num,Version,Cost,Weight,BOMUom,BaseNum,Waste,Position,Remark 
FROM 
(
SELECT ROW_NUMBER()OVER(PARTITION BY t.Line ORDER BY  t.sort) rr,* FROM (
SELECT 
--ROW_NUMBER() OVER(  ORDER BY a.id,b.DocLineNo)rn,
CASE WHEN a.Code=c.Code THEN 0 ELSE 1 END sort,a.ID,
a.line,b.DocLineNo,ISNULL(c.code,a.code)Code,ISNULL(c.SPEC,a.SPEC)Spec,a.name,Num,Version,Cost,Weight,BOMUom,BaseNum,Waste,Position,Remark 

FROM auctus_BOM a LEFT JOIN auctus_itemmaster b ON a.code=b.code
LEFT JOIN auctus_itemmaster c ON b.DocLineNo=c.DocLineNo
WHERE a.No=(SELECT MAX(no) FROM auctus_BOM)
) t 

) t1 
ORDER BY  t1.ID,t1.rr
END 
