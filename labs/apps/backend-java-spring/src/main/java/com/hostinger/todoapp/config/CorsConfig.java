package com.hostinger.todoapp.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.Arrays;

/**
 * CORS Configuration
 *
 * Võimaldab cross-origin päringuid frontend'ilt
 */
@Configuration
public class CorsConfig {

	@Bean
	public CorsFilter corsFilter() {
		CorsConfiguration config = new CorsConfiguration();

		// Allow credentials (cookies, authorization headers)
		config.setAllowCredentials(true);

		// Allowed origins
		config.setAllowedOrigins(Arrays.asList(
				"http://localhost:8080",           // Local frontend
				"http://93.127.213.242:8080",      // VPS IP
				"http://kirjakast:8080"            // VPS hostname
		));

		// Allowed headers
		config.setAllowedHeaders(Arrays.asList("*"));

		// Allowed methods
		config.setAllowedMethods(Arrays.asList(
				"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"
		));

		// Max age for preflight requests
		config.setMaxAge(3600L);

		// Register CORS configuration for all endpoints
		UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
		source.registerCorsConfiguration("/**", config);

		return new CorsFilter(source);
	}
}
