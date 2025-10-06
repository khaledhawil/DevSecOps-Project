package com.devsecops.analytics.service;

import com.devsecops.analytics.model.DailyStatistics;
import com.devsecops.analytics.model.UserStatistics;
import com.devsecops.analytics.repository.DailyStatisticsRepository;
import com.devsecops.analytics.repository.EventRepository;
import com.devsecops.analytics.repository.UserStatisticsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Service for statistics operations
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StatisticsService {

    private final UserStatisticsRepository userStatisticsRepository;
    private final DailyStatisticsRepository dailyStatisticsRepository;
    private final EventRepository eventRepository;

    /**
     * Get user statistics
     */
    public UserStatistics getUserStatistics(String userId) {
        return userStatisticsRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Statistics not found for user: " + userId));
    }

    /**
     * Get daily statistics
     */
    public DailyStatistics getDailyStatistics(LocalDate date, String statType) {
        return dailyStatisticsRepository.findByStatDateAndStatType(date, statType)
                .orElseThrow(() -> new RuntimeException("Statistics not found for date: " + date));
    }

    /**
     * Get summary statistics
     */
    public Map<String, Object> getSummaryStatistics() {
        Map<String, Object> summary = new HashMap<>();

        long totalUsers = userStatisticsRepository.count();
        long totalEvents = eventRepository.count();

        LocalDateTime today = LocalDateTime.now().withHour(0).withMinute(0).withSecond(0);
        LocalDateTime tomorrow = today.plusDays(1);

        long todayEvents = eventRepository.findEventsInDateRange(today, tomorrow).size();
        long activeUsers = eventRepository.countUniqueUsers(today, tomorrow);

        summary.put("total_users", totalUsers);
        summary.put("total_events", totalEvents);
        summary.put("today_events", todayEvents);
        summary.put("active_users_today", activeUsers);

        log.info("Generated summary statistics");

        return summary;
    }

    /**
     * Get statistics for date range
     */
    public List<DailyStatistics> getStatisticsForDateRange(LocalDate startDate, LocalDate endDate) {
        return dailyStatisticsRepository.findByStatDateBetweenOrderByStatDateDesc(startDate, endDate);
    }
}
