package com.hostinger.todoapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Todo Service - Spring Boot Application
 *
 * See on Java Spring Boot mikroteenuse rakenduse peaklass,
 * mis pakub RESTful API teenust todo märkmete haldamiseks.
 *
 * Rakendus kasutab:
 * - Spring Boot 3.2
 * - PostgreSQL andmebaasi
 * - JWT autentimist
 * - Spring Security'd
 *
 * @author DevOps Training
 * @version 1.0.0
 */
@SpringBootApplication
public class TodoApplication {

	public static void main(String[] args) {
		SpringApplication.run(TodoApplication.class, args);
		System.out.println("==============================================");
		System.out.println("Todo Service käivitus edukalt!");
		System.out.println("API: http://localhost:8081/api/todos");
		System.out.println("Health: http://localhost:8081/health");
		System.out.println("Swagger: http://localhost:8081/swagger-ui.html");
		System.out.println("==============================================");
	}

}
