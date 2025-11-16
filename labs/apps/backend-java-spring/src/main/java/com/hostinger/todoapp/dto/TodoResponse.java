package com.hostinger.todoapp.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.hostinger.todoapp.model.Todo;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Todo Response DTO
 *
 * Kasutatakse todo märkme tagastamiseks API vastuses
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoResponse {

	private Long id;
	private Long userId;
	private String title;
	private String description;
	private Boolean completed;
	private String priority;

	@JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
	private LocalDateTime dueDate;

	@JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
	private LocalDateTime createdAt;

	@JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
	private LocalDateTime updatedAt;

	private Boolean overdue;

	/**
	 * Konverteeri Todo entity TodoResponse DTO-ks
	 */
	public static TodoResponse fromEntity(Todo todo) {
		TodoResponse response = new TodoResponse();
		response.setId(todo.getId());
		response.setUserId(todo.getUserId());
		response.setTitle(todo.getTitle());
		response.setDescription(todo.getDescription());
		response.setCompleted(todo.getCompleted());
		response.setPriority(todo.getPriority());
		response.setDueDate(todo.getDueDate());
		response.setCreatedAt(todo.getCreatedAt());
		response.setUpdatedAt(todo.getUpdatedAt());
		response.setOverdue(todo.isOverdue());
		return response;
	}
}
