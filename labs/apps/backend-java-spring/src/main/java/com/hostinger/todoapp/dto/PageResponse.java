package com.hostinger.todoapp.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.domain.Page;

import java.util.List;

/**
 * Page Response DTO
 *
 * Wrapper pagination info ja andmete jaoks
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageResponse<T> {

	private List<T> content;
	private PaginationInfo pagination;

	/**
	 * Loo PageResponse Spring Data Page objektist
	 */
	public static <T> PageResponse<T> of(Page<T> page) {
		PaginationInfo pagination = new PaginationInfo(
				page.getNumber(),
				page.getSize(),
				page.getTotalElements(),
				page.getTotalPages(),
				page.isFirst(),
				page.isLast()
		);
		return new PageResponse<>(page.getContent(), pagination);
	}

	@Data
	@NoArgsConstructor
	@AllArgsConstructor
	public static class PaginationInfo {
		private int page;
		private int size;
		private long totalElements;
		private int totalPages;
		private boolean first;
		private boolean last;
	}
}
