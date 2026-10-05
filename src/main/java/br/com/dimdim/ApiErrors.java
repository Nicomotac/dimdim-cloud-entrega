package br.com.dimdim;

import java.util.Map;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class ApiErrors {
    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<?> conflict() {
        return ResponseEntity.status(409).body(Map.of("message",
            "Conflito: e-mail/número já cadastrado, cliente com contas vinculadas ou dados incompatíveis com as regras do banco."));
    }
    @ExceptionHandler({MethodArgumentNotValidException.class, HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class})
    ResponseEntity<?> invalid() {
        return ResponseEntity.badRequest().body(Map.of("message","Confira os campos: nome, e-mail, cliente, número e saldo não negativo com até duas casas decimais."));
    }
    @ExceptionHandler(ResponseStatusException.class)
    ResponseEntity<?> notFound(ResponseStatusException ex) {
        return ResponseEntity.status(ex.getStatusCode()).body(Map.of("message", "Registro não encontrado."));
    }
}
