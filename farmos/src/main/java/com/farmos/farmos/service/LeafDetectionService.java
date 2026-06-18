package com.farmos.farmos.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class LeafDetectionService {

    @Value("${huggingface.api.key:}")
    private String apiKey;

    @Value("${huggingface.model.url}")
    private String modelUrl;

    @Autowired
    private RestTemplate restTemplate;

    private final Map<String, Map<String, Object>> diseaseDetailsByKey = new HashMap<>();

    @PostConstruct
    public void loadDiseaseDetails() {
        try {
            ClassPathResource resource = new ClassPathResource("plant_diseases.json");
            try (InputStream stream = resource.getInputStream()) {
                ObjectMapper mapper = new ObjectMapper();
                List<Map<String, Object>> diseases = mapper.readValue(
                        stream,
                        new TypeReference<>() {
                        }
                );

                for (Map<String, Object> disease : diseases) {
                    Object className = disease.get("class_name");
                    Object displayName = disease.get("display_name");
                    Object crop = disease.get("crop");
                    if (className != null) {
                        diseaseDetailsByKey.put(normalizeLabel(String.valueOf(className)), disease);
                    }
                    if (displayName != null) {
                        diseaseDetailsByKey.put(normalizeLabel(String.valueOf(displayName)), disease);
                    }
                    if (crop != null && className != null) {
                        diseaseDetailsByKey.put(normalizeLabel(crop + "_" + className), disease);
                        diseaseDetailsByKey.put(normalizeLabel(crop + "___" + className), disease);
                    }
                }
            }
        } catch (Exception e) {
            throw new IllegalStateException("Could not load plant_diseases.json", e);
        }
    }

    public List<Map<String, Object>> detectDisease(byte[] imageBytes) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("HUGGINGFACE_API_KEY or HF_TOKEN is not configured");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + apiKey);
        headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        HttpEntity<byte[]> entity = new HttpEntity<>(imageBytes, headers);

        for (int attempt = 1; attempt <= 3; attempt++) {
            try {
                ResponseEntity<Object> response = restTemplate.exchange(
                        modelUrl, HttpMethod.POST, entity, Object.class
                );
                return normalizePredictions(response.getBody());
            } catch (ResourceAccessException e) {
                throw new RuntimeException(
                        "Could not reach Hugging Face. Check your internet connection, proxy/firewall, and model URL: " + modelUrl,
                        e
                );
            } catch (Exception e) {
                String msg = e.getMessage() != null ? e.getMessage() : "";
                if (msg.contains("503") || msg.toLowerCase(Locale.ROOT).contains("loading")) {
                    System.out.println("Model loading, attempt " + attempt + "/3. Waiting 20s...");
                    try {
                        Thread.sleep(20000);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        throw new RuntimeException("Interrupted while waiting for Hugging Face model", ie);
                    }
                } else {
                    System.out.println("Hugging Face error: " + msg);
                    throw e;
                }
            }
        }

        throw new RuntimeException("Model failed to load after 3 attempts");
    }

    public Map<String, Object> getDiseaseDetails(String label) {
        Map<String, Object> details = diseaseDetailsByKey.get(normalizeLabel(label));
        if (details != null) {
            return details;
        }

        return fallbackDiseaseDetails(label);
    }

    private List<Map<String, Object>> normalizePredictions(Object body) {
        if (body instanceof List<?> rawList) {
            List<Map<String, Object>> predictions = new ArrayList<>();
            for (Object item : rawList) {
                if (item instanceof Map<?, ?> rawMap) {
                    Map<String, Object> prediction = new HashMap<>();
                    for (Map.Entry<?, ?> entry : rawMap.entrySet()) {
                        prediction.put(String.valueOf(entry.getKey()), entry.getValue());
                    }
                    predictions.add(prediction);
                }
            }
            return predictions;
        }

        if (body instanceof Map<?, ?> rawMap && rawMap.get("error") != null) {
            throw new RuntimeException(String.valueOf(rawMap.get("error")));
        }

        throw new RuntimeException("Unexpected Hugging Face response");
    }

    private String normalizeLabel(String label) {
        return label == null ? "" : label
                .toLowerCase(Locale.ROOT)
                .replace("___", "_")
                .replace("-", "_")
                .replace(" ", "_")
                .replaceAll("[^a-z0-9_]", "")
                .replaceAll("_+", "_")
                .replaceAll("^_|_$", "");
    }

    private Map<String, Object> fallbackDiseaseDetails(String label) {
        String safeLabel = label == null ? "Unknown disease" : label;
        String cleaned = safeLabel.replace("___", " - ").replace("_", " ");
        boolean healthy = safeLabel.toLowerCase(Locale.ROOT).contains("healthy");

        Map<String, Object> details = new HashMap<>();
        details.put("class_name", safeLabel);
        details.put("display_name", cleaned);
        details.put("crop", "Unknown");
        details.put("is_healthy", healthy);
        details.put("disease_type", healthy ? "healthy" : "Unknown");
        details.put("visual_symptoms", List.of());
        details.put(
                "key_visual_cues",
                "Inspect the leaf for spots, discoloration, curling, mold, lesions, or yellowing before applying treatment."
        );

        if (healthy) {
            details.put("solutions", Map.of(
                    "immediate_actions", List.of("No urgent treatment is needed.", "Continue regular monitoring."),
                    "treatment", List.of("No chemical treatment required."),
                    "prevention", List.of(
                            "Keep the crop watered consistently without wetting leaves late in the day.",
                            "Maintain good spacing and airflow.",
                            "Inspect leaves weekly for early symptoms."
                    )
            ));
        } else {
            details.put("solutions", Map.of(
                    "immediate_actions", List.of(
                            "Mark or isolate affected plants.",
                            "Remove severely infected leaves and dispose of them away from the field.",
                            "Avoid overhead irrigation until the issue is controlled."
                    ),
                    "treatment", List.of(
                            "Use a crop-safe, locally recommended fungicide or treatment for the suspected disease.",
                            "Repeat only according to the product label.",
                            "Consult an agronomist if symptoms spread after treatment."
                    ),
                    "prevention", List.of(
                            "Improve airflow by pruning and spacing plants.",
                            "Water near the soil instead of wetting leaves.",
                            "Clean tools after working with infected plants.",
                            "Remove fallen plant debris that can carry disease."
                    )
            ));
        }

        return details;
    }
}
