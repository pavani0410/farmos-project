package com.farmos.farmos.controller;

import com.farmos.farmos.model.Farm;
import com.farmos.farmos.service.FarmService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/farms")
public class FarmController {

    private final FarmService farmService;

    public FarmController(FarmService farmService) {
        this.farmService = farmService;
    }

    @GetMapping
    public List<Farm> getAllFarms(@RequestParam Long userId) {
        return farmService.getAllFarmsForUser(userId);
    }

    @PostMapping
    public ResponseEntity<Farm> createFarm(
            @RequestParam Long userId,
            @RequestBody Farm farm) {
        Farm saved = farmService.createFarm(userId, farm);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Farm> updateFarm(
            @PathVariable Long id,
            @RequestBody Farm farm) {
        Farm updated = farmService.updateFarm(id, farm);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFarm(@PathVariable Long id) {
        farmService.deleteFarm(id);
        return ResponseEntity.ok().build();
    }

}