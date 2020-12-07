
--  =============================================
--功能簡述：MES 功放包装验证
-- 拟写：liufei
-- 日期：2019/11/19
-- ============================================= 
ALTER  PROCEDURE [dbo].[sp_CheckGongfangSnAblePack]
(
	@Sn					NVARCHAR(30),		--SN code
	@PackDetailID		INT = 884602,
	@CreateBy			NVARCHAR(30)
)
AS

--DECLARE	@Sn					NVARCHAR(30) =	'HJ42978'	--SN code
--DECLARE @PackDetailID		INT = 1007303;

BEGIN
	DECLARE @UserId INT = ISNULL((SELECT TOP 1 ID FROM dbo.syUser WHERE LoginID = @CreateBy), -1);
	--SELECT * FROM dbo.mxqh_SnCodeWeigth WHERE PackMainID = 3064 AND BoxNumber = 165
	DECLARE @ItemCodePlan NVARCHAR(30)	--组装料号
	DECLARE @ItemCodePack NVARCHAR(30)	--包装料号
	DECLARE @MateIdPlan INT				--组装料ID
	DECLARE @MateIdPack NVARCHAR(30)	--包装料ID
	DECLARE @PackMainID BIGINT 
	DECLARE @IsHasPrint BIT;
	DECLARE @IsPass INT--是否走完所有工艺流程
	--验证产品是否走完所有工艺流程
	SELECT @IsPass=ISNULL(a.IsPass,0) FROM dbo.opPlanExecutDetail a INNER JOIN dbo.opPlanExecutMain b ON a.PlanExecutMainID=b.ID
	WHERE b.InternalCode=@SN AND ISNULL(a.ExtendOne,'')='0'
	AND a.OrderNum=(SELECT MAX(a.OrderNum) FROM dbo.opPlanExecutDetail a INNER JOIN dbo.opPlanExecutMain b ON a.PlanExecutMainID=b.ID
	WHERE b.InternalCode=@SN AND ISNULL(a.ExtendOne,'')='0')
	--	SELECT TOP 10 * FROM dbo.opPlanExecutDetail a INNER JOIN dbo.opPlanExecutMain b ON a.PlanExecutMainID=b.ID
	--WHERE b.InternalCode=@Sn
	IF @IsPass=0
	BEGIN
		SELECT 'Error' MsgType, '工单未走完所有工艺流程！' MsgText;
		RETURN;
	END

	--获取箱号信息
	SELECT @PackMainID = PackMainID, @IsHasPrint = IsHasPrint
	FROM  dbo.opPackageDetail WHERE ID = @PackDetailID;
	IF @PackMainID IS NULL 
	BEGIN
		SELECT 'Error' MsgType, '箱号不存在' MsgText;
		RETURN;
	END
	IF @IsHasPrint = 1
	BEGIN
		SELECT 'Error' MsgType, '该箱已经包完，不可再包装' MsgText;
		RETURN;
	END

	DECLARE @SnCode NVARCHAR(30), @SnCode1 NVARCHAR(30), @BSN NVARCHAR(30);
	SELECT @SnCode = InternalCode, @BSN = InternalCode FROM dbo.opPlanExecutMain WHERE InternalCode = @Sn

	IF ISNULL(@SnCode,'')=''
	begin
		SELECT 'Error' MsgType, 'SN['+@Sn+']不存在， 不可包装' MsgText;
		RETURN;
	end
	----SN是否称重
	--IF NOT EXISTS(SELECT 1 FROM dbo.mxqh_SnCodeWeigth WHERE SNCode = @SnCode) AND  NOT EXISTS(SELECT 1 FROM dbo.opProductWeight WHERE SNCode = @SnCode)
	--BEGIN
	--	SELECT 'Error' MsgType, 'SN['+@Sn+']还未称重或不存在， 不可包装' MsgText;
	--	RETURN;
	--END

	IF EXISTS (SELECT 1 FROM dbo.opPackageChild WHERE PackDetailID != @PackDetailID AND SNCode = @SnCode)
	BEGIN
		SELECT 'Error' MsgType, 'SN['+@SnCode+']已包装在其他包装箱，不可再包装' MsgText;
		RETURN;
	END

	--获取SN信息
	SELECT @ItemCodePlan = c.MaterialCode, @MateIdPlan = c.MaterialID
	FROM dbo.opPlanExecutMain b  INNER JOIN dbo.mxqh_plAssemblyPlanDetail c ON b.AssemblyPlanDetailID = c.ID
	WHERE b.InternalCode = @BSN

	SELECT @ItemCodePack = b.MaterialCode, @MateIdPack = b.MaterialID FROM dbo.opPackageMain a INNER JOIN dbo.mxqh_plAssemblyPlanDetail b ON a.AssemblyPlanDetailID = b.ID WHERE a.ID = @PackMainID

	IF @MateIdPlan IS NULL OR @MateIdPack IS NULL
	BEGIN
		SELECT 'Error' MsgType, 'SN['+@SnCode+']料品信息获取失败' MsgText;
		RETURN;
	END

	--SELECT @ItemCodePack, @ItemCodePlan

	--验证箱号 及SN符合关系
	 IF(@MateIdPlan != @MateIdPack AND NOT EXISTS(SELECT 1 FROM dbo.mxqh_ProductNumber WHERE CID = @MateIdPlan AND PID = @MateIdPack))
	 BEGIN
		SELECT 'Error' MsgType, 'SN['+@SnCode+']对应品号['+ @ItemCodePack +']与包装箱品号不符， 不可混包' MsgText;
		RETURN;
	END

	--箱号还没添入
	IF NOT EXISTS(SELECT 1 FROM dbo.opPackageChild WHERE PackDetailID = @PackDetailID AND SNCode = @SnCode)
	BEGIN
		DECLARE @MaxId BIGINT = (SELECT MAX(ID) FROM dbo.opPackageChild);
		
		INSERT INTO dbo.opPackageChild(ID, SNCode, PackDetailID, OperatorID, CreateDate, CreateBy)
		VALUES(ISNULL(@MaxId, 1) + 1, @SnCode, @PackDetailID, @UserId, CONVERT(VARCHAR(20), GETDATE(), 120), @CreateBy);
	END

	SELECT 'Success' MsgType, 'SN['+@SnCode+']验证通过，已经包在包装箱中' MsgText;

	SELECT SNCode, IsOQCBad FROM dbo.opPackageChild WHERE PackDetailID = @PackDetailID;

END

