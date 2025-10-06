package com.devsecops.analytics.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.Map;

/**
 * DTO for tracking events
 */
@Data
public class EventDTO {

    @NotBlank(message = "User ID is required")
    private String userId;

    @NotBlank(message = "Event type is required")
    private String eventType;

    @NotBlank(message = "Event name is required")
    private String eventName;

    private Map<String, Object> properties;

    private String sessionId;

    private String ipAddress;

    private String userAgent;
}
