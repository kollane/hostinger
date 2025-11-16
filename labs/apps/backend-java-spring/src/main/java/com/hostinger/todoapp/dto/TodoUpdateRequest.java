package com.hostinger.todoapp.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Todo Update Request DTO
 *
 * Kasutatakse olemasoleva todo märkme uuendamiseks (PUT /api/todos/{id})
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoUpdateRequest {

	private String title;

	private String description;

	private Boolean completed;

	@Pattern(regexp = "low|medium|high", message = "Prioriteet peab olema 'low', 'medium' või 'high'")
	private String priority;

	@JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
	private LocalDateTime dueDate;
}
