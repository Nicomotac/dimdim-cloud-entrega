-- Execute no banco dimdim do Azure SQL após CADA operação pela interface.
-- Substitua os IDs abaixo pelos IDs reais exibidos no aplicativo.
DECLARE @ClienteId BIGINT = 1;
DECLARE @ContaId BIGINT = 1;

SELECT DB_NAME() AS banco, SYSUTCDATETIME() AS instante_utc;
SELECT id, nome, email, criado_em FROM dbo.Clientes WHERE id = @ClienteId;
SELECT id, cliente_id, numero, saldo, criado_em FROM dbo.Contas WHERE id = @ContaId;
SELECT c.id AS conta_id, c.numero, c.saldo, p.id AS cliente_id, p.nome
FROM dbo.Contas c JOIN dbo.Clientes p ON p.id=c.cliente_id
WHERE p.id=@ClienteId;

