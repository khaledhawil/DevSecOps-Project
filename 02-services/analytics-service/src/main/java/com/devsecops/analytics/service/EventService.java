package com.devsecops.analytics.service;

import com.devsecops.analytics.dto.EventDTO;
import com.devsecops.analytics.model.Event;
import com.devsecops.analytics.model.UserStatistics;
import com.devsecops.analytics.repository.EventRepository;
import com.devsecops.analytics.repository.UserStatisticsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Service for event tracking operations
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EventService {

    private final EventRepository eventRepository;
    private final UserStatisticsRepository userStatisticsRepository;

    /**
     * Track a new event
     */
    @Transactional
    public Event trackEvent(EventDTO eventDTO) {
        log.info("Tracking event: {} for user: {}", eventDTO.getEventName(), eventDTO.getUserId());

        Event event = new Event();
        event.setUserId(eventDTO.getUserId());
        event.setEventType(eventDTO.getEventType());
        event.setEventName(eventDTO.getEventName());
        event.setProperties(eventDTO.getProperties());
        event.setSessionId(eventDTO.getSessionId());
        event.setIpAddress(eventDTO.getIpAddress());
        event.setUserAgent(eventDTO.getUserAgent());
        event.setCreatedAt(LocalDateTime.now());

        Event savedEvent = eventRepository.save(event);

        // Update user statistics asynchronously
        updateUserStatistics(eventDTO.getUserId(), eventDTO.getEventType());

        return savedEvent;
    }

    /**
     * Get event by ID
     */
    public Event getEventById(String id) {
        return eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found with id: " + id));
    }

    /**
     * Get events by user ID with pagination
     */
    public Page<Event> getEventsByUserId(String userId, Pageable pageable) {
        return eventRepository.findByUserId(userId, pageable);
    }

    /**
     * Get all events with pagination
     */
    public Page<Event> getAllEvents(Pageable pageable) {
        return eventRepository.findAll(pageable);
    }

    /**
     * Update user statistics
     */
    private void updateUserStatistics(String userId, String eventType) {
        UserStatistics stats = userStatisticsRepository.findByUserId(userId)
                .orElse(new UserStatistics());

        if (stats.getId() == null) {
            stats.setUserId(userId);
            stats.setFirstSeenAt(LocalDateTime.now());
        }

        stats.setTotalEvents(stats.getTotalEvents() + 1);
        
        if ("page_view".equals(eventType)) {
            stats.setTotalPageViews(stats.getTotalPageViews() + 1);
        }

        stats.setLastActiveAt(LocalDateTime.now());
        stats.setUpdatedAt(LocalDateTime.now());

        userStatisticsRepository.save(stats);
        
        log.debug("Updated statistics for user: {}", userId);
    }
}
