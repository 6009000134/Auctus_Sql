ALTER  VIEW vw_tempCapacity
as
 --�������ڣ��̶���ǰ��+������/����������*�䶯��ǰ��
 with  Items as (
 select a1.Org, Code,Name,SPECS,a2.FixedLT,a2.LTBatch,VarietyLT 
 ,a1.DescFlexField_PrivateDescSeg11 ��׼�ܹ�ʱ
,a1.DescFlexField_PrivateDescSeg18  ����UPPH
  ,ceiling(convert(decimal(18,4),isnull(a1.DescFlexField_PrivateDescSeg18,0))*11
  * (case a1.DescFlexField_PrivateDescSeg22 
   when 'MRP100' then  10
   when 'MRP101' then  11
   when 'MRP107' then  7
   when 'MRP114' then  7
   when 'MRP115' then  3   
   when 'MRP116' then  7
 end))   ����
  ,(case a1.DescFlexField_PrivateDescSeg22 
   when 'MRP100' then  10
   when 'MRP101' then  11
   when 'MRP107' then  7
   when 'MRP114' then  7
   when 'MRP115' then  3   
   when 'MRP116' then  7
 end)   ��Դ����
  ,(case a1.DescFlexField_PrivateDescSeg22 
   when 'MRP100' then  '��װ'
   when 'MRP101' then  '��װ'
   when 'MRP102' then  '����ί��'
   when 'MRP103' then  '�Խ���SMTί��'
   when 'MRP104' then  '����'
   when 'MRP105' then  '����'
   when 'MRP106' then  '�ṹ'
   when 'MRP107' then  'ǰ�ӹ�'
   when 'MRP108' then  '��ֵ�׺�Ʒ'
   when 'MRP109' then  '���'
   when 'MRP111' then  '��������'
   when 'MRP112' then  '�͹���'
   when 'MRP113' then  '���'  
   when 'MRP114' then  'ί�����'  
   when 'MRP115' then  '����'  
   when 'MRP116' then  '��'  
   when 'MRP117' then  '����SMTί��'  
   when 'MRP118' then  '�����¼'  
   when 'MRP119' then  'ǰ�ӹ�ί��'  
 end)   MRP����
 from   cbo_itemMaster a1
LEFT join  CBO_MrpInfo a2 on a1.id=a2.ItemMaster  
where  a1.ItemFormAttribute=10 and a1.Effective_IsEffective=1
and  org=1001708020135665
and  a1.DescFlexField_PrivateDescSeg18 !=''
and   a1.DescFlexField_PrivateDescSeg22  in ('MRP100','MRP101','MRP107','MRP114','MRP115','MRP116')
 )
 select *     from Items a

 
  
 
  