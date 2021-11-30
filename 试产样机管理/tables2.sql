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
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'Applicant', @ColumnName = '申请人'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'CustomerCode', @ColumnName = '客户编码'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'CustomerName', @ColumnName = '客户名称'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ItemCode', @ColumnName = '料号'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'BatchProductStatus', @ColumnName = '量产状态，0-量产前，1-量产后'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ProjectCode', @ColumnName = '项目编码'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ProjectName', @ColumnName = '项目名称'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ProjectManager', @ColumnName = '项目经理'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ProductName', @ColumnName = '产品命名';
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'Quantity', @ColumnName = '数量'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ShipmentQty', @ColumnName = '出货数量'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ReturnQuantity', @ColumnName = '归还数量'; 
EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ItemType', @ColumnName = '样机类型'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'CerRequirement', @ColumnName = '认证需求'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'Version', @ColumnName = '版本'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ProductPower', @ColumnName = '功率';
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'SoundCode', @ColumnName = '声码';
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'Frequency', @ColumnName = '频段'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'ReqUse', @ColumnName = '样机用途'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'RequireDate', @ColumnName = '需求时间'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'DeliveryDate', @ColumnName = '可交付时间'; 
	EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'Remark', @ColumnName = '备注'; 
		EXEC dbo.EditTableDesc @TableName = 'TP_SampleApplication', @Desc = '样机申请表',
    @Column = N'OAFlowID', @ColumnName = 'OA流程ID'; 




--PRINT 28-4-2+1.5-1.5+7.9-1-0.5-1-0.5

/*同时，你会发现，当期货价格下跌了一个平台后，你不太敢操作了，深层的原因其实是此时你对上涨\下跌的判断概率下降了，当价格比较高的时候，
你敢于开空单，因为你知道上涨的概率相对小，所以你的胜率已经提升上来了。同理，当价格较低的时候，你敢于开多单，因为你知道下跌概率小了。
总结下，其实胜率才是最终要的操作因素，而胜率来源于你对期货后续的走势判断。

谈下个人对目前铜价的感受
1、铜价已从5月10号的最高点10747美元跌到现在的9468，跌幅大概11.9%,跌了1279美元，大概8300人民币
2、铜价前期上涨到搞点原因是中国控制疫情良好，率先复工复产（中国本身就是铜的主要需求国家），铜的需求上来了，但是由于疫情原因导致铜的供给出现
下降，所以铜价上升。
3、达到高点后，基于全球疫情得到初步控制，铜供应上来了，但是期间疫情反复，铜矿罢工等事件影响了供给，导致铜价时有反复
4、美国无限量QE，美元贬值导致大宗商品涨价，随后美国推出各种提振经济举措，开始taper预期，美元反复震荡也导致铜价跟着反复震荡
5、国家发展委员会投放铜（未达预期）也一度造成铜价波动

近期情况总结
近期铜价反弹，美元波动，美元指数最低达到91.8，波动原因待分析：1、据说美元在做压力测试；2、美国最新公布非农就业数据不好，taper预期落空，
美元继续宽松，所以美元走低;3、美国公布的CPI虽然高，但是核心cpi走低，通胀放缓，美元上升。以上3中原因交叉重叠，美元波动

*/











/*
1、开盘半小时不操作
2、价格突破半小时最高价做多  说明多方强势
3、价格突破半小时最低价做空  说明空方强势
4、价格跳空高开不做多        跳空高开，不做多也不代表要做空
5、价格跳空低开不做空		 跳空低开，不做空也不代表要做多 
6、价格跳空高开，跌破昨日最高价做空
7、价格跳空低开，突破昨日最低价做多
8、无论成败，当日了结
*/



