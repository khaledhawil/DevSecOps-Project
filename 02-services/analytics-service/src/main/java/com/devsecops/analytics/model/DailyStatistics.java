package com.devsecops.analytics.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.GenericGenerator;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Daily statistics entity for aggregated daily data
 */
@Entity
@Table(name = "daily_statistics", indexes = {
    @Index(name = "idx_daily_stats_date", columnList = "stat_date"),
    @Index(name = "idx_daily_stats_type", columnList = "stat_type")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailyStatistics {

    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "id", updatable = false, nullable = false)
    private String id;

    @Column(name = "stat_date", nullable = false)
    private LocalDate statDate;

    @Column(name = "stat_type", nullable = false, length = 50)
    private String statType;

    @Column(name = "total_events", nullable = false)
    private Long totalEvents = 0L;

    @Column(name = "unique_users", nullable = false)
    private Long uniqueUsers = 0L;

    @Column(name = "total_sessions", nullable = false)
    private Long totalSessions = 0L;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
