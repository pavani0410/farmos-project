package com.farmos.farmos.controller;

import com.farmos.farmos.service.LeafDetectionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.*;

@RestController
@RequestMapping("/api/leaf")
public class LeafDetectionController {

    private final LeafDetectionService leafDetectionService;

    public LeafDetectionController(LeafDetectionService leafDetectionService) {
        this.leafDetectionService = leafDetectionService;
    }

    // accepts image upload from React
    // returns top prediction + treatment
    @PostMapping("/detect")
    public ResponseEntity<Map<String, Object>> detect(
            @RequestParam("image") MultipartFile image) {
        try {
            // get raw bytes from uploaded image
            byte[] imageBytes = image.getBytes();

            // send to Hugging Face
            List<Map<String, Object>> predictions = leafDetectionService.detectDisease(imageBytes);

            if (predictions == null || predictions.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "No predictions returned"));
            }

            // top prediction is first result
            Map<String, Object> top = predictions.get(0);
            String label = (String) top.get("label");
            Number score = (Number) top.getOrDefault("score", 0);

            // get detailed disease-specific guidance
            Map<String, Object> details = leafDetectionService.getDiseaseDetails(label);

            // build response
            Map<String, Object> response = new HashMap<>();
            response.put("label", label);
            response.put("confidence", Math.round(score.doubleValue() * 100));
            response.put("disease", details.get("display_name"));
            response.put("crop", details.get("crop"));
            response.put("isHealthy", details.get("is_healthy"));
            response.put("diseaseType", details.get("disease_type"));
            response.put("visualSymptoms", details.get("visual_symptoms"));
            response.put("keyVisualCues", details.get("key_visual_cues"));
            //response.put("confusableWith", details.get("confusable_with"));
            response.put("solutions", details.get("solutions"));
            addSummaryFields(response, details);

            // also return top 3 predictions
            List<Map<String, Object>> top3 = predictions.subList(0, Math.min(3, predictions.size()));
            response.put("allPredictions", top3);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            // print full error to console
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Detection failed: " + e.getMessage()));
        }
    }

    private void addSummaryFields(Map<String, Object> response, Map<String, Object> details) {
        Object solutionsObj = details.get("solutions");
        if (!(solutionsObj instanceof Map<?, ?> solutions)) {
            return;
        }

        response.put("action", firstSolutionText(solutions.get("immediate_actions")));
        response.put("recommendation", firstSolutionText(solutions.get("treatment")));
        response.put("prevention", firstSolutionText(solutions.get("prevention")));
        response.put("severity", Boolean.TRUE.equals(details.get("is_healthy")) ? "NONE" : "CHECK REQUIRED");
    }

    private String firstSolutionText(Object value) {
        if (value instanceof List<?> list && !list.isEmpty()) {
            return String.valueOf(list.get(0));
        }
        return value == null ? "" : String.valueOf(value);
    }
}
