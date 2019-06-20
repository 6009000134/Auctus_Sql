--SELECT * FROM dbo.Sys_TableConfig
INSERT INTO dbo.Sys_TableConfig
        ( TbName ,
          ClName ,
          ClSts ,
          ClInf ,
          ClDesc ,
          ClOrder
        )
VALUES  ( 'ComponentType' , -- TbName - varchar(30)
          'ComponentType' , -- ClName - varchar(30)
          'S' , -- ClSts - varchar(1)
          '0' , -- ClInf - varchar(30)
          N'±ê×¼' , -- ClDesc - nvarchar(200)
          0  -- ClOrder - int
        )
		INSERT INTO dbo.Sys_TableConfig
        ( TbName ,
          ClName ,
          ClSts ,
          ClInf ,
          ClDesc ,
          ClOrder
        )
VALUES  ( 'ComponentType' , -- TbName - varchar(30)
          'ComponentType' , -- ClName - varchar(30)
          'S' , -- ClSts - varchar(1)
          '2' , -- ClInf - varchar(30)
          N'Ìæ´ú' , -- ClDesc - nvarchar(200)
          1  -- ClOrder - int
        )