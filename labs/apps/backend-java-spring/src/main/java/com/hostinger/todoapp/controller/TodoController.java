package com.hostinger.todoapp.controller;

import com.hostinger.todoapp.dto.*;
import com.hostinger.todoapp.security.UserPrincipal;
import com.hostinger.todoapp.service.TodoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * Todo Controller
 *
 * REST API controller todo märkmete haldamiseks
 */
@RestController
@RequestMapping("/api/todos")
@Tag(name = "Todos", description = "Todo märkmete haldamise API")
@SecurityRequirement(name = "bearer-jwt")
public class TodoController {

	private final TodoService todoService;

	public TodoController(TodoService todoService) {
		this.todoService = todoService;
	}

	/**
	 * POST /api/todos - Loo uus todo
	 */
	@PostMapping
	@Operation(summary = "Loo uus todo", description = "Loob uue todo märkme autenditud kasutajale")
	public ResponseEntity<TodoResponse> createTodo(
			@AuthenticationPrincipal UserPrincipal currentUser,
			@Valid @RequestBody TodoCreateRequest request
	) {
		TodoResponse response = todoService.createTodo(currentUser.getId(), request);
		return ResponseEntity.status(HttpStatus.CREATED).body(response);
	}

	/**
	 * GET /api/todos - Loe kõik todo'd
	 */
	@GetMapping
	@Operation(summary = "Loe kõik todo'd", description = "Tagastab kasutaja kõik todo'd (pagination ja filtreerimine)")
	public ResponseEntity<PageResponse<TodoResponse>> getTodos(
			@AuthenticationPrincipal UserPrincipal currentUser,
			@RequestParam(required = false) Boolean completed,
			@RequestParam(required = false) String priority,
			@RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "10") int size,
			@RequestParam(defaultValue = "createdAt,desc") String[] sort
	) {
		// Parse sort parameters
		Sort.Direction direction = sort.length > 1 && sort[1].equalsIgnoreCase("asc")
				? Sort.Direction.ASC
				: Sort.Direction.DESC;
		String sortField = sort[0];

		Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortField));

		PageResponse<TodoResponse> response = todoService.getTodos(
				currentUser.getId(),
				completed,
				priority,
				pageable
		);

		return ResponseEntity.ok(response);
	}

	/**
	 * GET /api/todos/{id} - Loe üks todo
	 */
	@GetMapping("/{id}")
	@Operation(summary = "Loe üks todo", description = "Tagastab ühe todo märkme ID järgi")
	public ResponseEntity<TodoResponse> getTodoById(
			@AuthenticationPrincipal UserPrincipal currentUser,
			@PathVariable Long id
	) {
		TodoResponse response = todoService.getTodoById(currentUser.getId(), id);
		return ResponseEntity.ok(response);
	}

	/**
	 * PUT /api/todos/{id} - Uuenda todo't
	 */
	@PutMapping("/{id}")
	@Operation(summary = "Uuenda todo't", description = "Uuendab olemasolevat todo märkme")
	public ResponseEntity<TodoResponse> updateTodo(
			@AuthenticationPrincipal UserPrincipal currentUser,
			@PathVariable Long id,
			@Valid @RequestBody TodoUpdateRequest request
	) {
		TodoResponse response = todoService.updateTodo(currentUser.getId(), id, request);
		return ResponseEntity.ok(response);
	}

	/**
	 * DELETE /api/todos/{id} - Kustuta todo
	 */
	@DeleteMapping("/{id}")
	@Operation(summary = "Kustuta todo", description = "Kustutab todo märkme")
	public ResponseEntity<Void> deleteTodo(
			@AuthenticationPrincipal UserPrincipal currentUser,
			@PathVariable Long id
	) {
		todoService.deleteTodo(currentUser.getId(), id);
		return ResponseEntity.noContent().build();
	}

	/**
	 * PATCH /api/todos/{id}/complete - Märgi todo tehtud
	 */
	@PatchMapping("/{id}/complete")
	@Operation(summary = "Märgi todo tehtud", description = "Märgib todo märkme tehtuks")
	public ResponseEntity<TodoResponse> completeTodo(
			@AuthenticationPrincipal UserPrincipal currentUser,
			@PathVariable Long id
	) {
		TodoResponse response = todoService.completeTodo(currentUser.getId(), id);
		return ResponseEntity.ok(response);
	}

	/**
	 * GET /api/todos/stats - Loe statistika
	 */
	@GetMapping("/stats")
	@Operation(summary = "Loe statistika", description = "Tagastab kasutaja todo märkmete statistika")
	public ResponseEntity<TodoStatsResponse> getStats(
			@AuthenticationPrincipal UserPrincipal currentUser
	) {
		TodoStatsResponse response = todoService.getStats(currentUser.getId());
		return ResponseEntity.ok(response);
	}
}
