package com.hostinger.todoapp.repository;

import com.hostinger.todoapp.model.Todo;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Todo Repository Interface
 *
 * Spring Data JPA repository todo märkmete andmebaasi päringute jaoks.
 * Spring genereerib automaatselt implementatsiooni.
 */
@Repository
public interface TodoRepository extends JpaRepository<Todo, Long> {

	/**
	 * Leia kõik kasutaja todo'd (pagination)
	 */
	Page<Todo> findByUserId(Long userId, Pageable pageable);

	/**
	 * Leia üks todo kasutaja ID ja todo ID järgi
	 */
	Optional<Todo> findByIdAndUserId(Long id, Long userId);

	/**
	 * Leia kasutaja todo'd staatuse järgi
	 */
	Page<Todo> findByUserIdAndCompleted(Long userId, Boolean completed, Pageable pageable);

	/**
	 * Leia kasutaja todo'd prioriteedi järgi
	 */
	Page<Todo> findByUserIdAndPriority(Long userId, String priority, Pageable pageable);

	/**
	 * Leia kasutaja todo'd staatuse ja prioriteedi järgi
	 */
	Page<Todo> findByUserIdAndCompletedAndPriority(
			Long userId,
			Boolean completed,
			String priority,
			Pageable pageable
	);

	/**
	 * Leia hilinenud todo'd (due_date on möödas ja completed = false)
	 */
	@Query("SELECT t FROM Todo t WHERE t.userId = :userId " +
			"AND t.completed = false " +
			"AND t.dueDate IS NOT NULL " +
			"AND t.dueDate < :currentDate")
	List<Todo> findOverdueTodos(
			@Param("userId") Long userId,
			@Param("currentDate") LocalDateTime currentDate
	);

	/**
	 * Loenda kasutaja todo'sid
	 */
	long countByUserId(Long userId);

	/**
	 * Loenda kasutaja tehtud todo'sid
	 */
	long countByUserIdAndCompleted(Long userId, Boolean completed);

	/**
	 * Loenda kasutaja todo'sid prioriteedi järgi
	 */
	long countByUserIdAndPriority(Long userId, String priority);

	/**
	 * Kustuta kõik kasutaja todo'd
	 */
	void deleteByUserId(Long userId);
}
