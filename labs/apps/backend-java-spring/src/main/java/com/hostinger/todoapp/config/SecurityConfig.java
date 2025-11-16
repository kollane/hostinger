package com.hostinger.todoapp.config;

import com.hostinger.todoapp.security.JwtAuthenticationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Security Configuration
 *
 * Spring Security konfiguratsioon:
 * - JWT autentimine
 * - CORS
 * - CSRF keelatud (REST API jaoks)
 * - Stateless sessions
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

	private final JwtAuthenticationFilter jwtAuthenticationFilter;

	public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
		this.jwtAuthenticationFilter = jwtAuthenticationFilter;
	}

	@Bean
	public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
		http
				// Disable CSRF (REST API ei vaja)
				.csrf(AbstractHttpConfigurer::disable)

				// Session management: stateless (JWT-based)
				.sessionManagement(session ->
						session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
				)

				// Authorization rules
				.authorizeHttpRequests(auth -> auth
						// Public endpoints
						.requestMatchers("/health", "/actuator/health").permitAll()
						.requestMatchers("/swagger-ui/**", "/api-docs/**").permitAll()
						.requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

						// Protected endpoints (require authentication)
						.requestMatchers("/api/todos/**").authenticated()

						// All other requests require authentication
						.anyRequest().authenticated()
				)

				// Add JWT filter
				.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

		return http.build();
	}
}
