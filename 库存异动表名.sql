--InvTrans_InvTotalSelects 
--InvTrans_MonthClose 库存月结表
--InvTrans_AccountPeriodLine 会计期间异动数量档
--InvTrans_AccountPeriodLineBin 会计期间异动库位档




--InvTrans_TransLine 库存异动明细数量档
--InvTrans_TransLineBin 库存异动明细库位表
--InvTrans_TransLineCost 	库存异动明细档成本表
--InvTrans_AccountPeriodLineCost 会计期间异动成本档


--SELECT * FROM InvTrans_TransLine
SELECT b.Code,b.Name FROM dbo.InvTrans_TransLine a LEFT JOIN dbo.CBO_ItemMaster b ON a.Product=b.ID

SELECT * FROM dbo.InvTrans_Trans WHERE BizType

