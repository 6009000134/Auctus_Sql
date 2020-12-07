/*
�������ͷ��Ϣ
*/
;
WITH ModifyReason AS
(
 SELECT  A.[ID] as [ID], A.[Code] as [Code], A1.[Name] as [Name]
 , ROW_NUMBER() OVER(ORDER BY A.[Code] asc, (A.[ID] + 17) asc ) AS rownum  FROM  Base_DefineValue as A  left join Base_Language as A2 on (A2.Code = 'zh-CN')
  and (A2.Effective_IsEffective = 1)  left join [Base_DefineValue_Trl] as A1 on (A1.SysMlFlag = 'zh-CN') and (A1.SysMlFlag = A2.Code) and (A.[ID] = A1.[ID])
   WHERE  (((((((A.[ValueSetDef] = (SELECT ID FROM Base_ValueSetDef WHERE code='ZDY_BGYY') ) and (A.[Effective_IsEffective] = 1)) and (A.[Effective_EffectiveDate] <= GETDATE())) 
   AND (A.[Effective_DisableDate] >= GETDATE())) and (1 = 1)) and (1 = 1)) and (1 = 1))
)
SELECT b1.Name,a.DocNo,a.MODocNo,mo.DocNo
,a.Status,dbo.F_GetEnumName('UFIDA.U9.MO.MOModify.MOModifyStatusEnum',a.status,'zh-cn')StatusTxt
,a1.Memo,a1.ModifyReason
,bgyy.Code BGCode,bgyy.Name BGReason--,memo1.*
FROM dbo.MO_MOModify a  INNER JOIN dbo.MO_MOModify_Trl a1 ON a.ID=a1.ID AND ISNULL(a1.SysMLFlag,'zh-cn')='zh-cn'
INNER JOIN dbo.MO_MOModifyDocType b ON a.MOModifyDocType=b.ID 
INNER JOIN dbo.MO_MOModifyDocType_Trl b1 ON b.ID=b1.ID AND b1.SysMLFlag='zh-cn'
LEFT JOIN  ModifyReason bgyy ON a.DescFlexField_PrivateDescSeg1=bgyy.Code
INNER JOIN dbo.MO_MO mo ON a.MOID=mo.ID
WHERE 1=1
AND a.DocNo='MM200915333'
ORDER BY BGCode

/*
�������Ϣ
������ע���:
	1���������б�עʱ����ע�����ϢȡMO_MOModifyLine
	2���������ޱ�עʱ������������ע����ҪȡMO_MOModifyMOMemo��Ϣ
���ϵ������
	1����������ɾ�����ϵ���ʱ��ȡMO_MOModifyMOPickList
	2�����޸ı��ϵ���ʱ��ȡMO_MOModifyLine

*/
;

--SELECT 
--a.ID,a.DocNo,dbo.F_GetEnumName('UFIDA.U9.MO.MOModify.MOModifyTypeEnum',b.MOModifyType,'zh-cn')ModifyType
--,b.ModifyDataItemName,b.OldValue,b.NewValue,''DocLineNo,''Code
--FROM dbo.MO_MOModify a INNER JOIN dbo.MO_MOModifyLine b ON a.ID=b.MOModify
--WHERE 1=1
----AND a.DocNo='MM200915333'
--AND a.DocNo='MM200915333'--��ע���
SELECT 
a.ID,a.DocNo,dbo.F_GetEnumName('UFIDA.U9.MO.MOModify.MOModifyTypeEnum',b.MOModifyType,'zh-cn') '�������'
,b.ModifyDataItemName '�޸�����',b.OldValue '�޸�ǰ',b.NewValue '�޸ĺ�',''DocLineNo,''Code 
,''Name,''BOMReqQty,''STDReqQty,''ActualReqQty,''IssuedQty,''IssueNotDeliverQty
,''PlanReqDate,''ActualReqDate,''ActualIssueDate,''IssueStyle,''IsCoupleIssue
FROM dbo.MO_MOModify a INNER JOIN dbo.MO_MOModifyLine b ON a.ID=b.MOModify
WHERE 1=1
--AND a.DocNo='MM200915333'
AND a.DocNo='MM200915333'--��ע���
UNION ALL
SELECT --����������ע����
a.ID,a.DocNo,'����������ע����'ModifyType,'ժҪ����'ModifyDataItemName,''OldValue,b1.Description NewValue,''DocLineNo,''Code
,''Name,''BOMReqQty,''STDReqQty,''ActualReqQty,''IssuedQty,''IssueNotDeliverQty
,''PlanReqDate,''ActualReqDate,''ActualIssueDate,''IssueStyle,''IsCoupleIssue
FROM dbo.MO_MOModify a INNER JOIN dbo.MO_MOModifyMOMemo b ON a.ID=b.MOModify LEFT JOIN dbo.MO_MOModifyMOMemo_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.DocNo='MM200915333'
--WHERE a.DocNo='MM200709331'
UNION ALL--���ϵ�ɾ��
SELECT 
a.ID,a.DocNo,CASE WHEN b.IsDelete=1 THEN '������ɾ��'ELSE '����������' END ModifyType
,CASE WHEN b.IsDelete=1 THEN '������ɾ��'ELSE '����������' END ModifyDataItemName
,'������'+CONVERT(VARCHAR(10),b.DocLineNO) OldValue,'' NewValue
,b.DocLineNO,m.Code,m.Name,CONVERT(INT,b.BOMReqQty)BOMReqQty
,CONVERT(INT,b.STDReqQty)STDReqQty
,CONVERT(INT,b.ActualReqQty)ActualReqQty
,CONVERT(INT,b.IssuedQty)IssuedQty
,CONVERT(INT,b.IssueNotDeliverQty)IssueNotDeliverQty
,FORMAT(b.PlanReqDate,'yyyy-MM-dd')PlanReqDate
,FORMAT(b.ActualReqDate,'yyyy-MM-dd')ActualReqDate
,FORMAT(b.ActualIssueDate,'yyyy-MM-dd')ActualIssueDate
,dbo.F_GetEnumName('UFIDA.U9.CBO.MFG.Enums.IssueStyleEnum',b.IssueStyle,'zh-cn')IssueStyle
,b.IsCoupleIssue
--,b.STDReqQty,b.ActualReqQty,b.IssuedQty,b.IssueNotDeliverQty
--,b.PlanReqDate,b.ActualReqDate,b.ActualIssueDate,b.IssueStyle,b.IsCoupleIssue
FROM dbo.MO_MOModify a INNER JOIN MO_MOModifyMOPickList b ON a.ID=b.MOModify
LEFT JOIN MO_MOModifyMOPickList_Trl b1   ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
LEFT JOIN dbo.CBO_ItemMaster m ON b.ItemMaster=m.ID
WHERE 1=1
--AND b.IsDelete=1
--AND a.DocNo='MM200713333'
AND a.DocNo='MM200915333'





/*
�������

����
����
�������
���ԭ��
����ԭ��
����
��ע

��ϸ��

�������
�޸�����
�޸�ǰ
�޸ĺ�
���ϵ���
�Ϻ�
Ʒ��
BOM��������
��׼����
ʵ����������
�ѷ�������
����δ������
�ƻ�������
ʵ��������
ʵ�ʷ�����
���Ϸ�ʽ
*/