select  DocNo,(select Name from  PM_PODocType_trl  where id=DocumentType)  DocTypeName
,(select Name from  CBO_Operators_trl where  id=a1.PurOper) OperatorName,a1.CreatedBy
 ,a1.CreatedOn,BusinessDate,Supplier_ShortName,a1.ApprovedOn,Title,a2.ModifiedOn ,DATEDIFF(day,a1.CreatedOn,a2.ModifiedOn)  diffday 
 ,(case  IsBizClosed when  1  then  'ҵ��ر�' else  'δ�ر�' end) IsBizClosed
 ,(case  Status when 0 then '����' when 0 then '����' when 2 then '�����' when 1 then '�����' when 3 then '��Ȼ�ر�' when 5 then '����ر�' when 4 then '��ȱ�ر�' end) Status
 from  PM_PurchaseOrder a1
 left join  Base_Attachment a2 on a1.ID=a2.EntityID
 WHERE ISNULL(a2.Title,'')='' AND (select Name from  PM_PODocType_trl  where id=DocumentType)<>'�ڲ��ɹ�' AND a1.Status=2
 AND a1.Org=(SELECT id FROM dbo.Base_Organization WHERE code='300')
 AND (select Name from  PM_PODocType_trl  where id=DocumentType) IN ('�����������ϲɹ�','ȫ��ί�ⶩ��','ģ�߲ɹ�','��ֵ�׺�Ʒ�ɹ�') 
 AND DATEPART(YEAR,a1.CreatedOn)=DATEPART(YEAR,GETDATE())
 AND a1.ApprovedOn<DATEADD(DAY,-2,GETDATE())
 ORDER BY a1.CreatedOn desc