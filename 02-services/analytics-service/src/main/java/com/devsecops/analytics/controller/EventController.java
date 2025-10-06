package com.devsecops.analytics.controller;

import com.devsecops.analytics.dto.ApiResponse;
import com.devsecops.analytics.dto.EventDTO;
import com.devsecops.analytics.model.Event;
import com.devsecops.analytics.service.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * REST controller for event tracking
 */
@RestController
@RequestMapping("/api/v1/events")
@RequiredArgsConstructor
@Slf4j
public class EventController {

    private final EventService eventService;

    /**
     * Track new event
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Event>> trackEvent(@Valid @RequestBody EventDTO eventDTO) {
        try {
            Event event = eventService.trackEvent(eventDTO);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(event, "Event tracked successfully"));
        } catch (Exception e) {
            log.error("Failed to track event", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("INTERNAL_ERROR", "Failed to track event"));
        }
    }

    /**
     * Get event by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Event>> getEvent(@PathVariable String id) {
        try {
            Event event = eventService.getEventById(id);
            return ResponseEntity.ok(ApiResponse.success(event));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("NOT_FOUND", e.getMessage()));
        } catch (Exception e) {
            log.error("Failed to get event", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("INTERNAL_ERROR", "Failed to retrieve event"));
        }
    }

    /**
     * Get events by user ID
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUserEvents(
            @PathVariable String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<Event> events = eventService.getEventsByUserId(userId, pageable);

            Map<String, Object> response = new HashMap<>();
            response.put("events", events.getContent());
            response.put("pagination", Map.of(
                    "page", page,
                    "size", size,
                    "total", events.getTotalElements(),
                    "total_pages", events.getTotalPages()
            ));

            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Failed to get user events", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("INTERNAL_ERROR", "Failed to retrieve events"));
        }
    }

    /**
     * Get all events
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAllEvents(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<Event> events = eventService.getAllEvents(pageable);

            Map<String, Object> response = new HashMap<>();
            response.put("events", events.getContent());
            response.put("pagination", Map.of(
                    "page", page,
                    "size", size,
                    "total", events.getTotalElements(),
                    "total_pages", events.getTotalPages()
            ));

            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Failed to get events", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("INTERNAL_ERROR", "Failed to retrieve events"));
        }
    }
}
