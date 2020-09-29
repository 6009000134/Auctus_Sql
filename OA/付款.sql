--付款
--付款单表头
SELECT TOP 200
a.ID,a.DocNo,a.BizOrg--业务组织
,a.Money_OCMoney,a.TotalMoney_OCMoney,a.TotalBalance_OCMoney
,c.PayACTotalBalance
--,a.ActType,a.IsMainBill,a.ReverseType,a.EntrustOrg,a.VoucherType,a.VoucherID,a.VoucherNum
,a.SettlementFee_OCMoney
,c.ACTotalMoney,c.Money_OCMoney,c.PayACTotalBalance,c.SettlementFee_OCMoney,c.TotalMoney_OCMoney
,a.ac,a.FC,a.PC,a.ERType,a.PCToACExRate,a.PCToFCExRate,b.PCToFCExRate,b.PCToPayBACExRate
,b.PayBAC,b.PayBk,b.PayBkAcc
,b.SettlementMethod,b.SettlementFee_OCMoney,b.SettlementMethodClass
,a.SettleOrg--结算组织
,a.AAIStatus,a.IsNeedGenAAI--分录
,a.FC,a.BusinessType,a.DocumentType,a.IsTaxPrice--价格含税
,a.PayBatch--付款批
,a.IsFIClose--财务关闭
,a.PayDate--付款日期
,a.SOB,a.PostPeriod--记账期间
,a.CCObjSite,a.Cust_Customer
,a.CustSite_CustomerSite
,a.Dept,a.Emp--部门、员工
,a.PayObjType--付款对象
,a.Supp_Supplier,a.SuppSite_SupplierSite--供应商
,a.Transactor
,b.SettlementMethod
,b.Money_OCMoney,b.TotalMoney_OCMoney,b.TotalMoney_FCMoney
,b.PayBk,b.PayBkSite,b.PayBkAcc,bank.Code,bank1.Name,bankacc.Code,bankacc.ID
,c.PayProperty,'',c.*
FROM AP_PayBillHead a  INNER JOIN dbo.AP_PayBillLine b ON a.ID=b.PayBillHead
LEFT JOIN AP_PayBillUseLine c ON a.ID=c.PayBillHead
LEFT JOIN AP_PayDetail d ON a.ID=d.PayBillHead
LEFT JOIN CBO_Bank bank ON b.PayBk=bank.ID LEFT JOIN dbo.CBO_Bank_Trl bank1 ON bank.ID=bank1.ID
LEFT JOIN CBO_BankAccount bankacc ON b.PayBkAcc=bankacc.ID
LEFT JOIN dbo.AP_PayBillHead_Trl a1 ON a.ID=a1.ID
WHERE 1=1
AND a.DocNo='Pay-302020060003'
--AND a.SettlementFee_OCMoney>0
--AND Fc<>a.PC

--and a.DocNo='Pay-302019120166'
--AND a.ID=1001709140047312
--应付单
--SELECT a.DocNo,a.DocStatus,a.PaySupp_Supplier,c.code,c.ShortName FROM AP_APBillHead a
--LEFT JOIN dbo.AP_APBillLine b ON a.ID=b.APBillHead
--LEFT JOIN dbo.CBO_Supplier c ON a.PaySupp_Supplier=c.ID 
--WHERE 1=1
--AND a.DocStatus=2
--AND a.org=1001708020135665




