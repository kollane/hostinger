package com.hostinger.todoapp.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Health Controller
 *
 * Tervisekontrolli endpoint (health check)
 */
@RestController
@Tag(name = "Health", description = "Tervisekontrolli API")
public class HealthController {

	/**
	 * GET /health - Tervisekontroll
	 */
	@GetMapping("/health")
	@Operation(summary = "Tervisekontroll", description = "Kontrollib, kas teenus on kättesaadav")
	public ResponseEntity<Map<String, Object>> health() {
		Map<String, Object> response = new HashMap<>();
		response.put("status", "UP");
		response.put("service", "todo-service");
		response.put("version", "1.0.0");
		response.put("timestamp", LocalDateTime.now());
		return ResponseEntity.ok(response);
	}
}
