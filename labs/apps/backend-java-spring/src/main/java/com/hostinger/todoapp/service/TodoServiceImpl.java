package com.hostinger.todoapp.service;

import com.hostinger.todoapp.dto.*;
import com.hostinger.todoapp.exception.TodoNotFoundException;
import com.hostinger.todoapp.exception.UnauthorizedException;
import com.hostinger.todoapp.model.Todo;
import com.hostinger.todoapp.repository.TodoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

/**
 * Todo Service Implementation
 *
 * Äriloogika implementatsioon todo märkmete haldamiseks
 */
@Service
@Transactional
public class TodoServiceImpl implements TodoService {

	private static final Logger logger = LoggerFactory.getLogger(TodoServiceImpl.class);

	private final TodoRepository todoRepository;

	public TodoServiceImpl(TodoRepository todoRepository) {
		this.todoRepository = todoRepository;
	}

	@Override
	public TodoResponse createTodo(Long userId, TodoCreateRequest request) {
		logger.info("Loon uut todo't kasutajale: {}", userId);

		Todo todo = new Todo();
		todo.setUserId(userId);
		todo.setTitle(request.getTitle());
		todo.setDescription(request.getDescription());
		todo.setPriority(request.getPriority() != null ? request.getPriority() : "medium");
		todo.setDueDate(request.getDueDate());
		todo.setCompleted(false);

		Todo savedTodo = todoRepository.save(todo);
		logger.info("Todo loodud: ID={}", savedTodo.getId());

		return TodoResponse.fromEntity(savedTodo);
	}

	@Override
	@Transactional(readOnly = true)
	public PageResponse<TodoResponse> getTodos(
			Long userId,
			Boolean completed,
			String priority,
			Pageable pageable
	) {
		logger.info("Loen todo'sid kasutajale: {} (completed={}, priority={})",
				userId, completed, priority);

		Page<Todo> todosPage;

		// Apply filters
		if (completed != null && priority != null) {
			todosPage = todoRepository.findByUserIdAndCompletedAndPriority(
					userId, completed, priority, pageable
			);
		} else if (completed != null) {
			todosPage = todoRepository.findByUserIdAndCompleted(userId, completed, pageable);
		} else if (priority != null) {
			todosPage = todoRepository.findByUserIdAndPriority(userId, priority, pageable);
		} else {
			todosPage = todoRepository.findByUserId(userId, pageable);
		}

		Page<TodoResponse> responsePage = todosPage.map(TodoResponse::fromEntity);
		return PageResponse.of(responsePage);
	}

	@Override
	@Transactional(readOnly = true)
	public TodoResponse getTodoById(Long userId, Long todoId) {
		logger.info("Loen todo't: ID={} kasutajale: {}", todoId, userId);

		Todo todo = todoRepository.findByIdAndUserId(todoId, userId)
				.orElseThrow(() -> new TodoNotFoundException(todoId));

		return TodoResponse.fromEntity(todo);
	}

	@Override
	public TodoResponse updateTodo(Long userId, Long todoId, TodoUpdateRequest request) {
		logger.info("Uuendan todo't: ID={} kasutajale: {}", todoId, userId);

		Todo todo = todoRepository.findByIdAndUserId(todoId, userId)
				.orElseThrow(() -> new TodoNotFoundException(todoId));

		// Update only provided fields
		if (request.getTitle() != null) {
			todo.setTitle(request.getTitle());
		}
		if (request.getDescription() != null) {
			todo.setDescription(request.getDescription());
		}
		if (request.getCompleted() != null) {
			todo.setCompleted(request.getCompleted());
		}
		if (request.getPriority() != null) {
			todo.setPriority(request.getPriority());
		}
		if (request.getDueDate() != null) {
			todo.setDueDate(request.getDueDate());
		}

		Todo updatedTodo = todoRepository.save(todo);
		logger.info("Todo uuendatud: ID={}", updatedTodo.getId());

		return TodoResponse.fromEntity(updatedTodo);
	}

	@Override
	public void deleteTodo(Long userId, Long todoId) {
		logger.info("Kustutan todo't: ID={} kasutajale: {}", todoId, userId);

		Todo todo = todoRepository.findByIdAndUserId(todoId, userId)
				.orElseThrow(() -> new TodoNotFoundException(todoId));

		todoRepository.delete(todo);
		logger.info("Todo kustutatud: ID={}", todoId);
	}

	@Override
	public TodoResponse completeTodo(Long userId, Long todoId) {
		logger.info("Märgin todo't tehtuks: ID={} kasutajale: {}", todoId, userId);

		Todo todo = todoRepository.findByIdAndUserId(todoId, userId)
				.orElseThrow(() -> new TodoNotFoundException(todoId));

		todo.markAsCompleted();
		Todo updatedTodo = todoRepository.save(todo);

		logger.info("Todo märgitud tehtuks: ID={}", todoId);
		return TodoResponse.fromEntity(updatedTodo);
	}

	@Override
	@Transactional(readOnly = true)
	public TodoStatsResponse getStats(Long userId) {
		logger.info("Loen statistikat kasutajale: {}", userId);

		long total = todoRepository.countByUserId(userId);
		long completed = todoRepository.countByUserIdAndCompleted(userId, true);
		long pending = todoRepository.countByUserIdAndCompleted(userId, false);

		double completionRate = total > 0 ? (completed * 100.0 / total) : 0.0;

		// Count by priority
		Map<String, Long> byPriority = new HashMap<>();
		byPriority.put("high", todoRepository.countByUserIdAndPriority(userId, "high"));
		byPriority.put("medium", todoRepository.countByUserIdAndPriority(userId, "medium"));
		byPriority.put("low", todoRepository.countByUserIdAndPriority(userId, "low"));

		return new TodoStatsResponse(total, completed, pending, completionRate, byPriority);
	}
}
