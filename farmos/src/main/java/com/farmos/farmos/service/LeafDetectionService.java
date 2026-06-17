package com.farmos.farmos.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.*;

@Service
public class LeafDetectionService {

    @Value("${huggingface.api.key:}")
    private String apiKey;

    private static final String MODEL_URL =
            "https://api-inference.huggingface.co/models/linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification";

    // Spring automatically provides this now
    // because we registered it as a @Bean above
    @Autowired
    private RestTemplate restTemplate;

    public List<Map<String, Object>> detectDisease(byte[] imageBytes) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + apiKey);
        headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
        HttpEntity<byte[]> entity = new HttpEntity<>(imageBytes, headers);

        // retry up to 3 times — model may be loading
        for (int attempt = 1; attempt <= 3; attempt++) {
            try {
                ResponseEntity<List> response = restTemplate.exchange(
                        MODEL_URL, HttpMethod.POST, entity, List.class
                );
                return response.getBody();
            } catch (Exception e) {
                String msg = e.getMessage() != null ? e.getMessage() : "";
                // if model is loading, wait and retry
                if (msg.contains("503") || msg.contains("loading")) {
                    System.out.println("Model loading, attempt " + attempt + "/3. Waiting 20s...");
                    try { Thread.sleep(20000); } catch (InterruptedException ie) {}
                } else {
                    // different error — print and throw immediately
                    System.out.println("Hugging Face error: " + msg);
                    throw e;
                }
            }
        }
        throw new RuntimeException("Model failed to load after 3 attempts");
    }

    public Map<String, String> getTreatment(String label) {
        Map<String, String> treatment = new HashMap<>();

        String cleaned = label
                .replace("___", " — ")
                .replace("_", " ");
        treatment.put("disease", cleaned);

        if (label.toLowerCase().contains("healthy")) {
            treatment.put("severity", "NONE");
            treatment.put("recommendation", "Plant appears healthy. Continue regular maintenance and monitoring.");
            treatment.put("action", "No action needed");
        } else if (label.toLowerCase().contains("blight")) {
            treatment.put("severity", "HIGH");
            treatment.put("recommendation", "Apply copper-based fungicide immediately. Remove and destroy infected leaves. Avoid overhead irrigation.");
            treatment.put("action", "Apply fungicide within 24 hours");
        } else if (label.toLowerCase().contains("spot") || label.toLowerCase().contains("cercospora")) {
            treatment.put("severity", "MEDIUM");
            treatment.put("recommendation", "Apply mancozeb or chlorothalonil fungicide. Remove heavily infected leaves. Improve drainage.");
            treatment.put("action", "Apply fungicide within 48 hours");
        } else if (label.toLowerCase().contains("rust")) {
            treatment.put("severity", "MEDIUM");
            treatment.put("recommendation", "Apply triazole-based fungicide. Remove infected plant debris. Avoid wetting foliage.");
            treatment.put("action", "Apply fungicide within 48 hours");
        } else if (label.toLowerCase().contains("mold") || label.toLowerCase().contains("mildew")) {
            treatment.put("severity", "MEDIUM");
            treatment.put("recommendation", "Improve air circulation. Apply sulfur-based fungicide. Reduce humidity around plants.");
            treatment.put("action", "Apply fungicide and prune within 48 hours");
        } else if (label.toLowerCase().contains("virus") || label.toLowerCase().contains("mosaic")) {
            treatment.put("severity", "HIGH");
            treatment.put("recommendation", "No cure available. Remove and destroy infected plants immediately. Control insect vectors. Disinfect all tools.");
            treatment.put("action", "Remove infected plants immediately");
        } else {
            treatment.put("severity", "LOW");
            treatment.put("recommendation", "Monitor plant closely. Consult an agronomist for accurate diagnosis.");
            treatment.put("action", "Monitor and consult agronomist");
        }

        return treatment;
    }
}