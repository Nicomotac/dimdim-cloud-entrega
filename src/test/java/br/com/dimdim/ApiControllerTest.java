package br.com.dimdim;

import static br.com.dimdim.Models.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers=ApiController.class, properties={"app.username=test-only", "app.password=test-only-not-deployed"})
@Import(SecurityConfig.class)
class ApiControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean DimdimRepository repository;
    @Test void apiRequiresAuthentication() throws Exception {
        mvc.perform(get("/api/clientes").accept(MediaType.APPLICATION_JSON)).andExpect(status().isUnauthorized());
    }
    @Test void mutationRequiresCsrf() throws Exception {
        mvc.perform(delete("/api/clientes/1").with(user("test"))).andExpect(status().isForbidden());
        verifyNoInteractions(repository);
    }
    @Test void invalidClienteNeverReachesDatabase() throws Exception {
        mvc.perform(post("/api/clientes").with(user("test")).with(csrf()).contentType(MediaType.APPLICATION_JSON)
            .content("{\"nome\":\"\",\"email\":\"invalido\"}")).andExpect(status().isBadRequest());
        verifyNoInteractions(repository);
    }
    @Test void negativeBalanceRejected() throws Exception {
        mvc.perform(post("/api/contas").with(user("test")).with(csrf()).contentType(MediaType.APPLICATION_JSON)
            .content("{\"clienteId\":1,\"numero\":\"CP5\",\"saldo\":-1}")).andExpect(status().isBadRequest());
        verifyNoInteractions(repository);
    }
    @Test void createClienteReturnsLocationAndId() throws Exception {
        when(repository.criarCliente(any())).thenReturn(new Cliente(8,"Ana","ana@example.com",LocalDateTime.now()));
        mvc.perform(post("/api/clientes").with(user("test")).with(csrf()).contentType(MediaType.APPLICATION_JSON)
            .content("{\"nome\":\"Ana\",\"email\":\"ana@example.com\"}"))
            .andExpect(status().isCreated()).andExpect(header().string("Location","/api/clientes/8")).andExpect(jsonPath("$.id").value(8));
    }
    @Test void deleteClienteWithAccountReturnsConflictWithoutSql() throws Exception {
        doThrow(new DataIntegrityViolationException("sensitive SQL detail")).when(repository).excluirCliente(1);
        mvc.perform(delete("/api/clientes/1").with(user("test")).with(csrf()))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.message").exists())
            .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("sensitive"))));
    }
    @Test void readBothTables() throws Exception {
        when(repository.clientes()).thenReturn(List.of(new Cliente(1,"Ana","ana@example.com",LocalDateTime.now())));
        when(repository.contas()).thenReturn(List.of(new Conta(2,1,"Ana","CP5",new BigDecimal("100.00"),LocalDateTime.now())));
        mvc.perform(get("/api/clientes").with(user("test"))).andExpect(status().isOk()).andExpect(jsonPath("$[0].id").value(1));
        mvc.perform(get("/api/contas").with(user("test"))).andExpect(status().isOk()).andExpect(jsonPath("$[0].clienteId").value(1));
    }
    @Test void updateAndDeleteAccount() throws Exception {
        when(repository.atualizarConta(eq(2L),any())).thenReturn(new Conta(2,1,"Ana","CP5",new BigDecimal("250.00"),LocalDateTime.now()));
        mvc.perform(put("/api/contas/2").with(user("test")).with(csrf()).contentType(MediaType.APPLICATION_JSON)
            .content("{\"clienteId\":1,\"numero\":\"CP5\",\"saldo\":250.00}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.saldo").value(250.00));
        mvc.perform(delete("/api/contas/2").with(user("test")).with(csrf())).andExpect(status().isNoContent());
        verify(repository).excluirConta(2L);
    }
}
