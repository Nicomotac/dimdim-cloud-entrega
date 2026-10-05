package br.com.dimdim;

import static br.com.dimdim.Models.*;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class ApiController {
    private final DimdimRepository repository;
    public ApiController(DimdimRepository repository) { this.repository=repository; }
    @GetMapping("/csrf") Map<String,String> csrf(CsrfToken token) {
        return Map.of("headerName",token.getHeaderName(),"token",token.getToken());
    }
    @GetMapping("/clientes") List<Cliente> clientes() { return repository.clientes(); }
    @GetMapping("/clientes/{id}") Cliente cliente(@PathVariable long id) { return repository.cliente(id); }
    @PostMapping("/clientes") ResponseEntity<Cliente> criarCliente(@Valid @RequestBody ClienteInput input) {
        Cliente result=repository.criarCliente(input);
        return ResponseEntity.created(URI.create("/api/clientes/"+result.id())).body(result);
    }
    @PutMapping("/clientes/{id}") Cliente atualizarCliente(@PathVariable long id, @Valid @RequestBody ClienteInput input) {
        return repository.atualizarCliente(id,input);
    }
    @DeleteMapping("/clientes/{id}") ResponseEntity<Void> excluirCliente(@PathVariable long id) {
        repository.excluirCliente(id); return ResponseEntity.noContent().build();
    }
    @GetMapping("/contas") List<Conta> contas() { return repository.contas(); }
    @GetMapping("/contas/{id}") Conta conta(@PathVariable long id) { return repository.conta(id); }
    @PostMapping("/contas") ResponseEntity<Conta> criarConta(@Valid @RequestBody ContaInput input) {
        Conta result=repository.criarConta(input);
        return ResponseEntity.created(URI.create("/api/contas/"+result.id())).body(result);
    }
    @PutMapping("/contas/{id}") Conta atualizarConta(@PathVariable long id, @Valid @RequestBody ContaInput input) {
        return repository.atualizarConta(id,input);
    }
    @DeleteMapping("/contas/{id}") ResponseEntity<Void> excluirConta(@PathVariable long id) {
        repository.excluirConta(id); return ResponseEntity.noContent().build();
    }
}
