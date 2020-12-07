--查询设备信息
ALTER PROCEDURE [dbo].[sp_GetEquipmentList]
(
@PageSize INT,
@PageIndex INT,
@Code VARCHAR(300),
@Name NVARCHAR(300)
)
AS
BEGIN
	DECLARE @beginIndex INT=(@PageIndex-1)*@PageSize
	DECLARE @endIndex INT=@PageIndex*@PageSize+1
	SET @Code='%'+ISNULL(@Code,'')+'%'
	SET @Name='%'+ISNULL(@Name,'')+'%'
	SELECT * FROM (
	SELECT a.CreateBy,a.CreateDate,a.ModifyBy,a.ModifyDate,a.ID,a.Code,a.Name,a.TypeID,b.Code TypeCode,b.Name TypeName,a.CheckUOM,c.Code CheckUOMCode,c.Name CheckUOMName,a.UpperLimit,a.LowerLimit,a.Remark ,a.Type
	,CONVERT(char(1),a.IsActive)IsActive
	,ROW_NUMBER() OVER(ORDER BY a.CreateDate DESC)RN
	FROM dbo.mxqh_Equipment a LEFT JOIN dbo.mxqh_Base_Dic b ON a.TypeID=b.ID
	LEFT JOIN dbo.mxqh_Base_Dic c ON a.CheckUOM=c.ID
	WHERE PATINDEX(@Code,a.Code)>0 OR PATINDEX(@Name,a.Name)>0
	) t WHERE t.RN>@beginIndex AND t.RN<@endIndex
	
	SELECT COUNT(1)Count
	FROM dbo.mxqh_Equipment a LEFT JOIN dbo.mxqh_Base_Dic b ON a.TypeID=b.ID
	LEFT JOIN dbo.mxqh_Base_Dic c ON a.CheckUOM=c.ID
	WHERE PATINDEX(@Code,a.Code)>0 OR PATINDEX(@Name,a.Name)>0

END