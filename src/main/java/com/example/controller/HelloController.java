package com.example.controller;

import com.example.exception.ApplicationException;
import com.example.response.ApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @Value("${app.message}")
    private String appMessage;

    @Value("${app.version}")
    private String appVersion;

    @Value("${app.environment}")
    private String appEnvironment;

    @Value("${app.gke.message}")
    private String gkeMessage;

    @GetMapping("/api/hello")
    public ResponseEntity<ApiResponse> hello() throws ApplicationException {
        try {
            if (appMessage == null || appMessage.isEmpty()) {
                throw new ApplicationException("Application message is not configured");
            }

            ApiResponse response = new ApiResponse(
                appMessage,
                appVersion,
                appEnvironment,
                true,
                null
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            throw new ApplicationException("Error processing hello request: " + e.getMessage());
        }
    }

    @GetMapping("/")
    public ResponseEntity<ApiResponse> root() throws ApplicationException {
        return hello();
    }

    @GetMapping(value = "/api/gke", produces = MediaType.TEXT_PLAIN_VALUE)
    public ResponseEntity<String> gkeMessage() {
        return ResponseEntity.ok(gkeMessage);
    }
}
