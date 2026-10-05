# Validação do pacote

## Executado neste ambiente

- Compilação e empacotamento com Java 17.0.20 e Maven 3.9.11: `mvn verify` concluído com **BUILD SUCCESS**.
- **8 testes MVC aprovados**, zero falhas/erros: autenticação, CSRF, entrada inválida, saldo negativo, criação/leitura, conflito e alteração/exclusão.

- Verificada a presença do front-end e do DDL dentro do JAR executável. O DDL empacotado é idêntico a `scripts/ddl.sql`.
- Sintaxe dos scripts Bash, Python, JavaScript e workflow YAML verificada.

- Diagrama de arquitetura renderizado e inspecionado.

