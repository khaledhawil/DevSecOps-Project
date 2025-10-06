package com.devsecops.analytics.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.GenericGenerator;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * User statistics entity for aggregated user data
 */
@Entity
@Table(name = "user_statistics", indexes = {
    @Index(name = "idx_user_stats_user_id", columnList = "user_id")
})
@EntityListeners(AuditingEntityListener.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserStatistics {

    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "id", updatable = false, nullable = false)
    private String id;

    @Column(name = "user_id", unique = true, nullable = false)
    private String userId;

    @Column(name = "total_events", nullable = false)
    private Long totalEvents = 0L;

    @Column(name = "total_page_views", nullable = false)
    private Long totalPageViews = 0L;

    @Column(name = "total_sessions", nullable = false)
    private Long totalSessions = 0L;

    @Column(name = "last_active_at")
    private LocalDateTime lastActiveAt;

    @Column(name = "first_seen_at")
    private LocalDateTime firstSeenAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
