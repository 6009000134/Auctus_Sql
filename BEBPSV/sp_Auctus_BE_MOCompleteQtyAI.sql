/*
U9完工报告AI BE插件，校验mes完工数量>=U9完工数量
*/
ALTER PROC sp_Auctus_BE_MOCompleteQtyAI
(
@DocNo VARCHAR(50),
@CompleteQty INT,
@Result VARCHAR(MAX) OUTPUT
)
AS
BEGIN 

--DECLARE @DocNo VARCHAR(50)='AMO-30190814060'
--DECLARE @CompleteQty INT
DECLARE @U9CompleteQty INT
DECLARE @DocType VARCHAR(30)=''
--MO30105、MO30113、MO30118、MO30119
SELECT @DocType=b.Code FROM dbo.MO_MO a INNER JOIN dbo.MO_MODocType b ON a.MODocType=b.ID INNER JOIN dbo.MO_MODocType_Trl b1 ON b.ID=b1.ID AND ISNULL(b1.SysMLFlag,'zh-cn')='zh-cn'
WHERE a.DocNo=@DocNo

IF @DocType IN ('MO30105','MO30113','MO30118','MO30119')
BEGIN
SET @Result=1;
RETURN 
END 

--IF PATINDEX('AMO%',@DocNo)=0 OR PATINDEX('HMO%',@DocNo)=0 OR PATINDEX('MO%',@DocNo)=0
--BEGIN
--SET @Result=1;
--RETURN 
--END 

--EXEC MESDATA.au_mes.dbo.sp_GetCompleteQty @WorkOrder = @DocNo,@MesCompleteQty=@CompleteQty OUTPUT -- varchar(30)
SELECT @U9CompleteQty=SUM(a.CompleteQty) FROM dbo.MO_CompleteRpt a INNER JOIN dbo.MO_MO b ON a.MO=b.ID
WHERE b.DocNo=@DocNo
--完工数量校验应该在开立还是审核时验证
IF @U9CompleteQty>@CompleteQty
BEGIN
	SET @Result='MES完工数量不足，无法创建完工报告。MES录入完工数量：'+CONVERT(VARCHAR(50),ISNULL(@CompleteQty,0))+',U9录入完工数量：'+CONVERT(VARCHAR(50),@U9CompleteQty)
	RETURN ;
END 
ELSE
BEGIN
	SET @Result=1
END 


END 