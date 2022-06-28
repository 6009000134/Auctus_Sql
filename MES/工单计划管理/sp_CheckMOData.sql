/*
检测出货地和线别，若存在则直接同步，不存在则出货地新增，线别不做新增操作
*/
ALTER PROCEDURE [dbo].[sp_CheckMOData]
(
@Line VARCHAR(20)
,@SendPlace NVARCHAR(20)='德国'
,@SendPlaceCode VARCHAR(50)='C01'
)
AS
BEGIN
--SELECT * FROM dbo.baAssemblyLine
--SELECT * FROM dbo.baSendPlace
--DECLARE @Line NVARCHAR(100)='生产一线'
--,@SendPlace NVARCHAR(20)='德国',@SendPlaceCode VARCHAR(50)='C01'

--SELECT @SendPlace,@SendPlaceCode,@Line
IF EXISTS(SELECT 1 FROM dbo.baSendPlace a WHERE a.Name=@SendPlace)
BEGIN
	SELECT a.ID SendPlaceID FROM dbo.baSendPlace a WHERE a.Name=@SendPlace
END 
ELSE
BEGIN
	IF ISNULL(@SendPlace,'')=''
	BEGIN
		SELECT NULL SendPlaceID 
	END
	ELSE
	BEGIN
		INSERT INTO dbo.baSendPlace
				( --ID,
				 TS, Code, Name, IsDefault, Remark )
		VALUES  ( --(SELECT MAX(ID)+1 FROM dbo.baSendPlace), -- ID - int
				  GETDATE(), -- TS - datetime
				  @SendPlaceCode, -- Code - nvarchar(20)
				  @SendPlace, -- Name - nvarchar(50)
				  1, -- IsDefault - bit
				  0  -- Remark - nvarchar(50)
				  )
		SELECT a.ID SendPlaceID FROM dbo.baSendPlace a WHERE a.Name=@SendPlace
	END  
END 

IF EXISTS(SELECT 1 FROM dbo.baAssemblyLine a WHERE a.ID=@Line)
BEGIN
	SELECT '1' MsgType,'' Msg
	SELECT a.ID LineID,a.Name LineName FROM dbo.baAssemblyLine a WHERE a.ID=@Line
END 
ELSE
BEGIN
	SELECT '0' MsgType,'生产线不存在' Msg
END 








END
