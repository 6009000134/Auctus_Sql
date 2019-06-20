ALTER FUNCTION sp_Auctus_ExchangeLineNo
(@RN int ,@Line varchar(50))
RETURNS varchar(50)
AS 
BEGIN
SELECT @Line=
CASE @RN 
WHEN 1 THEN @Line
WHEN 2 THEN @Line+'.'+'A'
WHEN 3 THEN @Line+'.'+'B'
WHEN 4 THEN @Line+'.'+'C'
WHEN 5 THEN @Line+'.'+'D'
WHEN 6 THEN @lINE+'.'+'E'
WHEN 7 THEN @lINE+'.'+'F'
WHEN 8 THEN @lINE+'.'+'G'
WHEN 9 THEN @lINE+'.'+'H'
WHEN 10 THEN @lINE+'.'+'I'
WHEN 11 THEN @lINE+'.'+'J'
ELSE '' END 

RETURN @Line
END 