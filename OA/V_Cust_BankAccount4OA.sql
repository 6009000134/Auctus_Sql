/*
“¯––’À∫≈
*/
alter VIEW V_Cust_BankAccount4OA AS
SELECT a.ID,a.Code,a1.Name,a.Org,a2.Code as OrgCode,a3.Code as BankCode,a4.Name as BankName FROM dbo.CBO_BankAccount AS a
INNER JOIN dbo.CBO_BankAccount_Trl AS a1 ON a.id=a1.ID
					AND a1.SysMLFlag='zh-cn'
INNER JOIN dbo.Base_Organization AS a2 ON a.Org=a2.ID	
INNER JOIN dbo.CBO_Bank AS a3 ON a.Bank=a3.ID		
INNER JOIN dbo.CBO_Bank_Trl AS a4 ON a3.id=a4.ID			
WHERE a.Effective_IsEffective = 1
AND a.Effective_EffectiveDate <=GETDATE()
AND a.Effective_DisableDate>=GETDATE();

