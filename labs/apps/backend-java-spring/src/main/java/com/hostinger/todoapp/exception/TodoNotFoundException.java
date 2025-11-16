package com.hostinger.todoapp.exception;

/**
 * Todo Not Found Exception
 *
 * Visatakse, kui todo't ei leita andmebaasist
 */
public class TodoNotFoundException extends RuntimeException {

	public TodoNotFoundException(Long id) {
		super("Todo't ei leitud ID-ga: " + id);
	}

	public TodoNotFoundException(String message) {
		super(message);
	}
}
