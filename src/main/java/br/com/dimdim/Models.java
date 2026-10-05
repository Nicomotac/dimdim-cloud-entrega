package br.com.dimdim;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public final class Models {
    private Models() {}
    public record ClienteInput(@NotBlank @Size(max=100) String nome,
                               @NotBlank @Email @Size(max=150) String email) {}
    public record ContaInput(@NotNull @Positive Long clienteId,
                             @NotBlank @Size(max=20) String numero,
                             @NotNull @DecimalMin("0.00") @Digits(integer=13, fraction=2) BigDecimal saldo) {}
    public record Cliente(long id, String nome, String email, LocalDateTime criadoEm) {}
    public record Conta(long id, long clienteId, String clienteNome, String numero,
                        BigDecimal saldo, LocalDateTime criadoEm) {}
}
