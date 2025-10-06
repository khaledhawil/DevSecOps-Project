package com.devsecops.analytics.controller;

import com.devsecops.analytics.dto.ApiResponse;
import com.devsecops.analytics.model.DailyStatistics;
import com.devsecops.analytics.model.UserStatistics;
import com.devsecops.analytics.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

/**
 * REST controller for statistics
 */
@RestController
@RequestMapping("/api/v1/statistics")
@RequiredArgsConstructor
@Slf4j
public class StatisticsController {

    private final StatisticsService statisticsService;

    /**
     * Get user statistics
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<UserStatistics>> getUserStatistics(@PathVariable String userId) {
        try {
            UserStatistics stats = statisticsService.getUserStatistics(userId);
            return ResponseEntity.ok(ApiResponse.success(stats));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("NOT_FOUND", e.getMessage()));
        } catch (Exception e) {
            log.error("Failed to get user statistics", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("INTERNAL_ERROR", "Failed to retrieve statistics"));
        }
    }

    /**
     * Get daily statistics
     */
    @GetMapping("/daily")
    public ResponseEntity<ApiResponse<DailyStatistics>> getDailyStatistics(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(defaultValue = "general") String type) {
        try {
            DailyStatistics stats = statisticsService.getDailyStatistics(date, type);
            return ResponseEntity.ok(ApiResponse.success(stats));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("NOT_FOUND", e.getMessage()));
        } catch (Exception e) {
            log.error("Failed to get daily statistics", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("INTERNAL_ERROR", "Failed to retrieve statistics"));
        }
    }

    /**
     * Get summary statistics
     */
    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSummaryStatistics() {
        try {
            Map<String, Object> summary = statisticsService.getSummaryStatistics();
            return ResponseEntity.ok(ApiResponse.success(summary));
        } catch (Exception e) {
            log.error("Failed to get summary statistics", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("INTERNAL_ERROR", "Failed to retrieve statistics"));
        }
    }
}
