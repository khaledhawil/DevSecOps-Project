package com.devsecops.analytics.repository;

import com.devsecops.analytics.model.DailyStatistics;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Repository for DailyStatistics entity
 */
@Repository
public interface DailyStatisticsRepository extends JpaRepository<DailyStatistics, String> {

    /**
     * Find statistics by date and type
     */
    Optional<DailyStatistics> findByStatDateAndStatType(LocalDate statDate, String statType);

    /**
     * Find statistics by date range
     */
    List<DailyStatistics> findByStatDateBetweenOrderByStatDateDesc(LocalDate startDate, LocalDate endDate);
}
