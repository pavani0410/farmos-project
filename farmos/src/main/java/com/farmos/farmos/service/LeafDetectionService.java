package com.farmos.farmos.service;

import java.util.List;
import java.util.Map;

public interface LeafDetectionService {

    List<Map<String, Object>> detectDisease(byte[] imageBytes);

    Map<String, Object> getDiseaseDetails(String label);
}
