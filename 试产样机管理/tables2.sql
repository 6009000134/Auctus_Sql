--drop TABLE TP_SampleApplication

CREATE TABLE TP_SampleApplication
    (
      ID INT PRIMARY KEY
             IDENTITY(1, 1) ,
      CreateBy VARCHAR(30) ,
      CreateDate DATETIME DEFAULT ( GETDATE() ) ,
      ModifyBy VARCHAR(30) ,
      ModifyDate DATETIME ,
      Applicant VARCHAR(30) ,
      CustomerCode VARCHAR(30) ,
      CustomerName NVARCHAR(300) ,
      ItemCode VARCHAR(30) ,
      BatchProductStatus varchar(10) ,
      ProjectCode VARCHAR(50) ,
      ProjectName NVARCHAR(300) ,
      ProjectManager VARCHAR(100) ,
      ProductName NVARCHAR(300) ,
      Quantity INT ,
      ShipmentQty INT ,
      ReturnQuantity INT ,
      ItemType VARCHAR(30),
	  CerRequirement NVARCHAR(MAX),
	  Version VARCHAR(20),
	  ProductPower DECIMAL(18,2),
	  SoundCode VARCHAR(30),
	  Frequency NVARCHAR(50),
	  ReqUse NVARCHAR(300),
	  RequireDate DATE,
	  DeliveryDate DATE,
	  Remark NVARCHAR(max),
	  OAFlowID VARCHAR(20)
    );
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'Applicant', @ColumnName = '������'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'CustomerCode', @ColumnName = '�ͻ�����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'CustomerName', @ColumnName = '�ͻ�����'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ItemCode', @ColumnName = '�Ϻ�'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'BatchProductStatus', @ColumnName = '����״̬��0-����ǰ��1-������'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ProjectCode', @ColumnName = '��Ŀ����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ProjectName', @ColumnName = '��Ŀ����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ProjectManager', @ColumnName = '��Ŀ����'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ProductName', @ColumnName = '��Ʒ����';
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'Quantity', @ColumnName = '����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ShipmentQty', @ColumnName = '��������'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ReturnQuantity', @ColumnName = '�黹����'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ItemType', @ColumnName = '��������'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'CerRequirement', @ColumnName = '��֤����'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'Version', @ColumnName = '�汾'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ProductPower', @ColumnName = '����';
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'SoundCode', @ColumnName = '����';
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'Frequency', @ColumnName = 'Ƶ��'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'ReqUse', @ColumnName = '������;'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'RequireDate', @ColumnName = '����ʱ��'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'DeliveryDate', @ColumnName = '�ɽ���ʱ��'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'Remark', @ColumnName = '��ע'; 
		EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '���������',
    @Column = N'OAFlowID', @ColumnName = 'OA����ID'; 




--PRINT 28-4-2+1.5-1.5+7.9-1-0.5-1-0.5

/*ͬʱ����ᷢ�֣����ڻ��۸��µ���һ��ƽ̨���㲻̫�Ҳ����ˣ�����ԭ����ʵ�Ǵ�ʱ�������\�µ����жϸ����½��ˣ����۸�Ƚϸߵ�ʱ��
����ڿ��յ�����Ϊ��֪�����ǵĸ������С���������ʤ���Ѿ����������ˡ�ͬ�����۸�ϵ͵�ʱ������ڿ��൥����Ϊ��֪���µ�����С�ˡ�
�ܽ��£���ʵʤ�ʲ�������Ҫ�Ĳ������أ���ʤ����Դ������ڻ������������жϡ�

̸�¸��˶�Ŀǰͭ�۵ĸ���
1��ͭ���Ѵ�5��10�ŵ���ߵ�10747��Ԫ�������ڵ�9468���������11.9%,����1279��Ԫ�����8300�����
2��ͭ��ǰ�����ǵ����ԭ�����й������������ã����ȸ����������й��������ͭ����Ҫ������ң���ͭ�����������ˣ�������������ԭ����ͭ�Ĺ�������
�½�������ͭ��������
3���ﵽ�ߵ�󣬻���ȫ������õ��������ƣ�ͭ��Ӧ�����ˣ������ڼ����鷴����ͭ��չ����¼�Ӱ���˹���������ͭ��ʱ�з���
4������������QE����Ԫ��ֵ���´�����Ʒ�Ǽۣ���������Ƴ��������񾭼þٴ룬��ʼtaperԤ�ڣ���Ԫ������Ҳ����ͭ�۸��ŷ�����
5�����ҷ�չίԱ��Ͷ��ͭ��δ��Ԥ�ڣ�Ҳһ�����ͭ�۲���

��������ܽ�
����ͭ�۷�������Ԫ��������Ԫָ����ʹﵽ91.8������ԭ���������1����˵��Ԫ����ѹ�����ԣ�2���������¹�����ũ��ҵ���ݲ��ã�taperԤ����գ�
��Ԫ�������ɣ�������Ԫ�ߵ�;3������������CPI��Ȼ�ߣ����Ǻ���cpi�ߵͣ�ͨ�ͷŻ�����Ԫ����������3��ԭ�򽻲��ص�����Ԫ����

*/











/*
1�����̰�Сʱ������
2���۸�ͻ�ư�Сʱ��߼�����  ˵���෽ǿ��
3���۸�ͻ�ư�Сʱ��ͼ�����  ˵���շ�ǿ��
4���۸����ո߿�������        ���ո߿���������Ҳ������Ҫ����
5���۸����յͿ�������		 ���յͿ���������Ҳ������Ҫ���� 
6���۸����ո߿�������������߼�����
7���۸����յͿ���ͻ��������ͼ�����
8�����۳ɰܣ������˽�
*/



