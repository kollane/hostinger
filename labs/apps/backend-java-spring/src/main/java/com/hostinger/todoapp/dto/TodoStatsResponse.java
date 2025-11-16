package com.hostinger.todoapp.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

/**
 * Todo Stats Response DTO
 *
 * Kasutatakse todo märkmete statistika tagastamiseks (GET /api/todos/stats)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TodoStatsResponse {

	private Long total;
	private Long completed;
	private Long pending;
	private Double completionRate;
	private Map<String, Long> byPriority;
}
