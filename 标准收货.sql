--��׼�ջ���⵽��sql
/*
BizType��ҵ�����ͣ���316,321,322, 328   ��׼�ɹ�,VMI���󲹻�,VMI�ɹ�����,���ɷ���
��֤���ֱ���˾Ӧ��û����321��322��328
ReceivementType(�ջ�������):0\1\2 �ɹ��ջ���\�ɹ��˻���\�����˻��ջ���
IsInitEvaluation �ڳ��ݹ�
*/
SELECT * FROM ( SELECT  A.[ID] as [ID], A.[DocNo] as [DocNo], A2.[Name] as [RcvDocType_Name], A.[BusinessDate] as [BusinessDate]
, A.[Supplier_ShortName] as [Supplier_ShortName], A.[CreatedBy] as [CreatedBy], A.[BizType] as [BizType], A.[Status] as [Status]
, A.[SysVersion] as [SysVersion], A.[ID] as [MainID], A3.[Code] as SysMlFlag , ROW_NUMBER() OVER(ORDER BY A.[BusinessDate] DESC
, A.[DocNo] desc, (A.[ID] + 17) asc ) AS rownum  
FROM  PM_Receivement as A  
LEFT join [PM_RcvDocType] as A1 on (A.[RcvDocType] = A1.[ID])  
LEFT join Base_Language as A3 on (A3.Code = 'zh-CN') and (A3.Effective_IsEffective = 1)  
LEFT join [PM_RcvDocType_Trl] as A2 on (A2.SysMlFlag = 'zh-CN') and (A2.SysMlFlag = A3.Code) and (A1.[ID] = A2.[ID]) 
WHERE  (((((((A.[Org] = 1001708020135665) and (A.[ReceivementType] = 0)) 
AND A.[BizType] in (316, 322, 328, 321)) and (A.[IsInitEvaluation] = 0))
 and (1 = 1)) and (1 = 1)) and (1 = 1))) T WHERE T.rownum>  0 and T.rownum<= 13