IF OBJECT_ID(N'dbo.Clientes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Clientes (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Clientes PRIMARY KEY,
        nome NVARCHAR(100) NOT NULL,
        email NVARCHAR(150) NOT NULL CONSTRAINT UQ_Clientes_Email UNIQUE,
        criado_em DATETIME2 NOT NULL CONSTRAINT DF_Clientes_Criado DEFAULT SYSUTCDATETIME()
    );
END;
GO
IF OBJECT_ID(N'dbo.Contas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Contas (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Contas PRIMARY KEY,
        cliente_id BIGINT NOT NULL,
        numero NVARCHAR(20) NOT NULL CONSTRAINT UQ_Contas_Numero UNIQUE,
        saldo DECIMAL(15,2) NOT NULL CONSTRAINT CK_Contas_Saldo CHECK (saldo >= 0),
        criado_em DATETIME2 NOT NULL CONSTRAINT DF_Contas_Criado DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Contas_Clientes FOREIGN KEY (cliente_id) REFERENCES dbo.Clientes(id)
    );
    CREATE INDEX IX_Contas_Cliente ON dbo.Contas(cliente_id);
END;
GO
