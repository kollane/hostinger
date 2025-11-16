package com.hostinger.todoapp.service;

import com.hostinger.todoapp.dto.*;
import org.springframework.data.domain.Pageable;

/**
 * Todo Service Interface
 *
 * Äriloogika interface todo märkmete haldamiseks
 */
public interface TodoService {

	/**
	 * Loo uus todo
	 */
	TodoResponse createTodo(Long userId, TodoCreateRequest request);

	/**
	 * Leia kõik kasutaja todo'd
	 */
	PageResponse<TodoResponse> getTodos(Long userId, Boolean completed, String priority, Pageable pageable);

	/**
	 * Leia üks todo
	 */
	TodoResponse getTodoById(Long userId, Long todoId);

	/**
	 * Uuenda todo't
	 */
	TodoResponse updateTodo(Long userId, Long todoId, TodoUpdateRequest request);

	/**
	 * Kustuta todo
	 */
	void deleteTodo(Long userId, Long todoId);

	/**
	 * Märgi todo tehtud
	 */
	TodoResponse completeTodo(Long userId, Long todoId);

	/**
	 * Loe kasutaja statistika
	 */
	TodoStatsResponse getStats(Long userId);
}
