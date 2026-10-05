package br.com.dimdim;

import static br.com.dimdim.Models.*;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Repository
public class DimdimRepository {
    private final JdbcTemplate jdbc;
    public DimdimRepository(JdbcTemplate jdbc) { this.jdbc = jdbc; }
    private static final RowMapper<Cliente> CLIENTE = (r, n) -> new Cliente(r.getLong("id"),
        r.getString("nome"), r.getString("email"), r.getTimestamp("criado_em").toLocalDateTime());
    private static final RowMapper<Conta> CONTA = (r, n) -> new Conta(r.getLong("id"),
        r.getLong("cliente_id"), r.getString("cliente_nome"), r.getString("numero"),
        r.getBigDecimal("saldo"), r.getTimestamp("criado_em").toLocalDateTime());
    private static final String CONTAS = "SELECT c.*, p.nome AS cliente_nome FROM dbo.Contas c JOIN dbo.Clientes p ON p.id=c.cliente_id";
    private static ResponseStatusException missing() { return new ResponseStatusException(HttpStatus.NOT_FOUND, "Registro não encontrado."); }
    public List<Cliente> clientes() { return jdbc.query("SELECT * FROM dbo.Clientes ORDER BY id", CLIENTE); }
    public Cliente cliente(long id) {
        return jdbc.query("SELECT * FROM dbo.Clientes WHERE id=?", CLIENTE, id).stream().findFirst().orElseThrow(DimdimRepository::missing);
    }
    @Transactional
    public Cliente criarCliente(ClienteInput input) {
        Long id = jdbc.queryForObject("INSERT INTO dbo.Clientes(nome,email) OUTPUT INSERTED.id VALUES (?,?)",
            Long.class, input.nome().strip(), input.email().strip());
        return cliente(id);
    }
    @Transactional
    public Cliente atualizarCliente(long id, ClienteInput input) {
        if (jdbc.update("UPDATE dbo.Clientes SET nome=?,email=? WHERE id=?", input.nome().strip(), input.email().strip(), id)==0) throw missing();
        return cliente(id);
    }
    @Transactional
    public void excluirCliente(long id) {
        if (jdbc.update("DELETE FROM dbo.Clientes WHERE id=?", id)==0) throw missing();
    }
    public List<Conta> contas() { return jdbc.query(CONTAS + " ORDER BY c.id", CONTA); }
    public Conta conta(long id) {
        return jdbc.query(CONTAS + " WHERE c.id=?", CONTA, id).stream().findFirst().orElseThrow(DimdimRepository::missing);
    }
    @Transactional
    public Conta criarConta(ContaInput input) {
        cliente(input.clienteId());
        Long id = jdbc.queryForObject("INSERT INTO dbo.Contas(cliente_id,numero,saldo) OUTPUT INSERTED.id VALUES (?,?,?)",
            Long.class, input.clienteId(), input.numero().strip(), input.saldo());
        return conta(id);
    }
    @Transactional
    public Conta atualizarConta(long id, ContaInput input) {
        cliente(input.clienteId());
        if (jdbc.update("UPDATE dbo.Contas SET cliente_id=?,numero=?,saldo=? WHERE id=?",
            input.clienteId(), input.numero().strip(), input.saldo(), id)==0) throw missing();
        return conta(id);
    }
    @Transactional
    public void excluirConta(long id) {
        if (jdbc.update("DELETE FROM dbo.Contas WHERE id=?", id)==0) throw missing();
    }
}
