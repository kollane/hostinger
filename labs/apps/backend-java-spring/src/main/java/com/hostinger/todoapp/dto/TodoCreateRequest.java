package com.hostinger.todoapp.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Todo Create Request DTO
 *
 * Kasutatakse uue todo märkme loomiseks (POST /api/todos)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoCreateRequest {

	@NotBlank(message = "Pealkiri ei tohi olla tühi")
	private String title;

	private String description;

	@Pattern(regexp = "low|medium|high", message = "Prioriteet peab olema 'low', 'medium' või 'high'")
	private String priority = "medium";

	@JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
	private LocalDateTime dueDate;
}
