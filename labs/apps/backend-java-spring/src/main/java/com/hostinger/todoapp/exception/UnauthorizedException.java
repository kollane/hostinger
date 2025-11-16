package com.hostinger.todoapp.exception;

/**
 * Unauthorized Exception
 *
 * Visatakse, kui kasutaja proovib pääseda juurde ressursile,
 * mis ei kuulu talle või ei ole autentinud
 */
public class UnauthorizedException extends RuntimeException {

	public UnauthorizedException(String message) {
		super(message);
	}

	public UnauthorizedException() {
		super("Autentimata juurdepääs");
	}
}
