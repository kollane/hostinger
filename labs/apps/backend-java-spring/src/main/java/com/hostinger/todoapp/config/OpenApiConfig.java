package com.hostinger.todoapp.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.Components;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI/Swagger Configuration
 *
 * API dokumentatsiooni konfiguratsioon.
 * Swagger UI: http://localhost:8081/swagger-ui.html
 */
@Configuration
public class OpenApiConfig {

	@Bean
	public OpenAPI customOpenAPI() {
		return new OpenAPI()
				.info(new Info()
						.title("Todo Service API")
						.version("1.0.0")
						.description("RESTful API teenus todo märkmete haldamiseks. " +
								"Osa DevOps koolituse mikroteenuste arhitektuurist.")
						.contact(new Contact()
								.name("DevOps Training")
								.email("devops@hostinger.com")
						)
				)
				.components(new Components()
						.addSecuritySchemes("bearer-jwt", new SecurityScheme()
								.type(SecurityScheme.Type.HTTP)
								.scheme("bearer")
								.bearerFormat("JWT")
								.description("JWT token User Service'ilt (Authorization: Bearer <token>)")
						)
				)
				.addSecurityItem(new SecurityRequirement().addList("bearer-jwt"));
	}
}
