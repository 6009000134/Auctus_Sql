select  DocNo,(select Name from  PM_PODocType_trl  where id=DocumentType)  DocTypeName
,(select Name from  CBO_Operators_trl where  id=a1.PurOper) OperatorName,a1.CreatedBy
 ,a1.CreatedOn,BusinessDate,Supplier_ShortName,a1.ApprovedOn,Title,a2.ModifiedOn ,DATEDIFF(day,a1.CreatedOn,a2.ModifiedOn)  diffday 
 ,(case  IsBizClosed when  1  then  '业务关闭' else  '未关闭' end) IsBizClosed
 ,(case  Status when 0 then '开立' when 0 then '开立' when 2 then '已审核' when 1 then '审核中' when 3 then '自然关闭' when 5 then '超额关闭' when 4 then '短缺关闭' end) Status
 from  PM_PurchaseOrder a1
 left join  Base_Attachment a2 on a1.ID=a2.EntityID
 WHERE ISNULL(a2.Title,'')='' AND (select Name from  PM_PODocType_trl  where id=DocumentType)<>'内部采购' AND a1.Status=2
 AND a1.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
 AND (select Name from  PM_PODocType_trl  where id=DocumentType) IN ('标生产性主料采购','全程委外订单','模具采购','低值易耗品采购') 
 AND DATEPART(YEAR,a1.CreatedOn)=DATEPART(YEAR,GETDATE())
 AND a1.ApprovedOn<DATEADD(DAY,-2,GETDATE())
 ORDER BY a1.CreatedOn desc