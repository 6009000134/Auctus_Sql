/*
控制BE\BP\SV\UI插件开关
*/
CREATE PROC sp_Auctus_BEPlugin_Control
(
@Type NVARCHAR(100),
@IsOpen NVARCHAR(MAX) OUT--1代表功能打开
)
AS
BEGIN
IF ISNULL(@Type,'')='BtnRecedeReverse'--取消退料按钮禁用
BEGIN
SET @IsOpen='1';
END 
IF ISNULL(@Type,'')='MiscRcvBtnUnDoApprove'--杂收单弃审功能禁用
BEGIN
SET @IsOpen='1';
END 
IF ISNULL(@Type,'')='MiscShipBtnUnDoApprove'--杂发单弃审功能禁用
BEGIN
SET @IsOpen='1';
END 

END 