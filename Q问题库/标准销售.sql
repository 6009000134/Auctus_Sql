/*
标准销售
*/
DECLARE @DocNo VARCHAR(30)='SO30201709058'
SELECT 
a.ID,a.DocNo,b.DocLineNo,c.DocSubLineNo,c.DemandType
FROM dbo.SM_SO a INNER JOIN dbo.SM_SOLine b ON a.ID=b.SO INNER JOIN dbo.SM_SOShipline c ON b.ID=c.SOLine
WHERE 1=1 
AND a.DocNo=@DocNo

/*
标准出货
*/
SELECT 
a.ID,a.DocNo,b.DocLineNo
FROM dbo.SM_Ship a INNER JOIN dbo.SM_ShipLine b ON a.ID=b.Ship 
WHERE 1=1
AND a.DocNo='xxxxxxxxx'




