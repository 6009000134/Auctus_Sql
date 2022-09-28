/*
≈˙∫≈ ”Õº4mes
*/
alter VIEW v_cust_Lot4Mes
AS

SELECT 
ID ,
InvalidTime ,
ValidDate ,
a.LotCode,
a.ItemCode
FROM    Lot_LotMaster AS A
WHERE   A.DataOwnerOrg = 1001708020000209                             
        --AND A.ItemCode = N'201010163'                               

		
		--SELECT * FROM v_cust_MOCompleteRpt