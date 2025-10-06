package com.devsecops.analytics.repository;

import com.devsecops.analytics.model.Event;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository for Event entity
 */
@Repository
public interface EventRepository extends JpaRepository<Event, String> {

    /**
     * Find events by user ID with pagination
     */
    Page<Event> findByUserId(String userId, Pageable pageable);

    /**
     * Find events by event type
     */
    Page<Event> findByEventType(String eventType, Pageable pageable);

    /**
     * Count events by user ID
     */
    long countByUserId(String userId);

    /**
     * Find events within date range
     */
    @Query("SELECT e FROM Event e WHERE e.createdAt BETWEEN :startDate AND :endDate ORDER BY e.createdAt DESC")
    List<Event> findEventsInDateRange(@Param("startDate") LocalDateTime startDate, 
                                      @Param("endDate") LocalDateTime endDate);

    /**
     * Count unique users
     */
    @Query("SELECT COUNT(DISTINCT e.userId) FROM Event e WHERE e.createdAt BETWEEN :startDate AND :endDate")
    long countUniqueUsers(@Param("startDate") LocalDateTime startDate, 
                         @Param("endDate") LocalDateTime endDate);
}
