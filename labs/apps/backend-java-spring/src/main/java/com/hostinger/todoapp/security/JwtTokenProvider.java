package com.hostinger.todoapp.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

/**
 * JWT Token Provider
 *
 * Valideerib JWT tokeneid, mis on genereeritud User Service'i poolt.
 *
 * TÄHTIS: jwt.secret peab olema SAMA nagu User Service'il!
 */
@Component
public class JwtTokenProvider {

	private static final Logger logger = LoggerFactory.getLogger(JwtTokenProvider.class);

	private final SecretKey key;

	public JwtTokenProvider(@Value("${jwt.secret}") String secret) {
		// Sama secret key nagu User Service'il
		this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
		logger.info("JWT Token Provider initialized");
	}

	/**
	 * Ekstrakti kasutaja ID tokenist
	 */
	public Long getUserIdFromToken(String token) {
		Claims claims = parseToken(token);
		Object idObj = claims.get("id");

		if (idObj instanceof Integer) {
			return ((Integer) idObj).longValue();
		} else if (idObj instanceof Long) {
			return (Long) idObj;
		} else if (idObj instanceof String) {
			return Long.parseLong((String) idObj);
		}

		throw new IllegalArgumentException("Token ei sisalda kehtivat kasutaja ID'd");
	}

	/**
	 * Ekstrakti email tokenist
	 */
	public String getEmailFromToken(String token) {
		Claims claims = parseToken(token);
		return claims.get("email", String.class);
	}

	/**
	 * Ekstrakti role tokenist
	 */
	public String getRoleFromToken(String token) {
		Claims claims = parseToken(token);
		return claims.get("role", String.class);
	}

	/**
	 * Valideeri tokenit
	 */
	public boolean validateToken(String token) {
		try {
			parseToken(token);
			return true;
		} catch (JwtException | IllegalArgumentException e) {
			logger.error("JWT token valideerimise viga: {}", e.getMessage());
			return false;
		}
	}

	/**
	 * Parsi token ja tagasta Claims
	 */
	private Claims parseToken(String token) {
		return Jwts.parser()
				.verifyWith(key)
				.build()
				.parseSignedClaims(token)
				.getPayload();
	}
}
