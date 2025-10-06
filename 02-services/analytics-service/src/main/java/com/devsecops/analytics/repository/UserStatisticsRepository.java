package com.devsecops.analytics.repository;

import com.devsecops.analytics.model.UserStatistics;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for UserStatistics entity
 */
@Repository
public interface UserStatisticsRepository extends JpaRepository<UserStatistics, String> {

    /**
     * Find statistics by user ID
     */
    Optional<UserStatistics> findByUserId(String userId);
}
