/*
����BE\BP\SV\UI�������
*/
CREATE PROC sp_Auctus_BEPlugin_Control
(
@Type NVARCHAR(100),
@IsOpen NVARCHAR(MAX) OUT--1�����ܴ�
)
AS
BEGIN
IF ISNULL(@Type,'')='BtnRecedeReverse'--ȡ�����ϰ�ť����
BEGIN
SET @IsOpen='1';
END 
IF ISNULL(@Type,'')='MiscRcvBtnUnDoApprove'--���յ������ܽ���
BEGIN
SET @IsOpen='1';
END 
IF ISNULL(@Type,'')='MiscShipBtnUnDoApprove'--�ӷ��������ܽ���
BEGIN
SET @IsOpen='1';
END 

END 