package com.hostinger.todoapp.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Global Exception Handler
 *
 * Käsitleb kõiki rakenduses tekkivaid erandeid ja tagastab
 * ühtse JSON vastuse formaadis
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

	/**
	 * Käsitle TodoNotFoundException
	 */
	@ExceptionHandler(TodoNotFoundException.class)
	public ResponseEntity<ErrorResponse> handleTodoNotFound(TodoNotFoundException ex) {
		ErrorResponse error = new ErrorResponse(
				HttpStatus.NOT_FOUND.value(),
				ex.getMessage(),
				LocalDateTime.now()
		);
		return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
	}

	/**
	 * Käsitle UnauthorizedException
	 */
	@ExceptionHandler(UnauthorizedException.class)
	public ResponseEntity<ErrorResponse> handleUnauthorized(UnauthorizedException ex) {
		ErrorResponse error = new ErrorResponse(
				HttpStatus.UNAUTHORIZED.value(),
				ex.getMessage(),
				LocalDateTime.now()
		);
		return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
	}

	/**
	 * Käsitle valideerimise vigu (DTO validation)
	 */
	@ExceptionHandler(MethodArgumentNotValidException.class)
	public ResponseEntity<Map<String, Object>> handleValidationErrors(
			MethodArgumentNotValidException ex) {
		Map<String, String> errors = new HashMap<>();
		ex.getBindingResult().getAllErrors().forEach((error) -> {
			String fieldName = ((FieldError) error).getField();
			String errorMessage = error.getDefaultMessage();
			errors.put(fieldName, errorMessage);
		});

		Map<String, Object> response = new HashMap<>();
		response.put("status", HttpStatus.BAD_REQUEST.value());
		response.put("message", "Valideerimise vead");
		response.put("errors", errors);
		response.put("timestamp", LocalDateTime.now());

		return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
	}

	/**
	 * Käsitle üldised vead
	 */
	@ExceptionHandler(Exception.class)
	public ResponseEntity<ErrorResponse> handleGeneralError(Exception ex) {
		ErrorResponse error = new ErrorResponse(
				HttpStatus.INTERNAL_SERVER_ERROR.value(),
				"Serveri viga: " + ex.getMessage(),
				LocalDateTime.now()
		);
		return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
	}

	/**
	 * Error Response DTO
	 */
	public record ErrorResponse(
			int status,
			String message,
			LocalDateTime timestamp
	) {}
}
