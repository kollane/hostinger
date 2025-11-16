package com.hostinger.todoapp.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * Todo Entity Class
 *
 * Andmebaasi tabel: todos
 *
 * JPA entity klass, mis esindab todo märkust andmebaasis.
 */
@Entity
@Table(name = "todos", indexes = {
		@Index(name = "idx_todos_user_id", columnList = "user_id"),
		@Index(name = "idx_todos_completed", columnList = "completed"),
		@Index(name = "idx_todos_priority", columnList = "priority"),
		@Index(name = "idx_todos_due_date", columnList = "due_date"),
		@Index(name = "idx_todos_created_at", columnList = "created_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Todo {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@NotNull(message = "User ID ei tohi olla tühi")
	@Column(name = "user_id", nullable = false)
	private Long userId;

	@NotBlank(message = "Pealkiri ei tohi olla tühi")
	@Column(name = "title", nullable = false, length = 255)
	private String title;

	@Column(name = "description", columnDefinition = "TEXT")
	private String description;

	@Column(name = "completed", nullable = false)
	private Boolean completed = false;

	@Pattern(regexp = "low|medium|high", message = "Prioriteet peab olema 'low', 'medium' või 'high'")
	@Column(name = "priority", length = 20)
	private String priority = "medium";

	@Column(name = "due_date")
	private LocalDateTime dueDate;

	@CreationTimestamp
	@Column(name = "created_at", nullable = false, updatable = false)
	private LocalDateTime createdAt;

	@UpdateTimestamp
	@Column(name = "updated_at", nullable = false)
	private LocalDateTime updatedAt;

	/**
	 * Märgi todo tehtud
	 */
	public void markAsCompleted() {
		this.completed = true;
	}

	/**
	 * Märgi todo tegemata
	 */
	public void markAsIncomplete() {
		this.completed = false;
	}

	/**
	 * Kontrolli, kas todo on hilinenud
	 */
	public boolean isOverdue() {
		if (dueDate == null || completed) {
			return false;
		}
		return LocalDateTime.now().isAfter(dueDate);
	}
}
