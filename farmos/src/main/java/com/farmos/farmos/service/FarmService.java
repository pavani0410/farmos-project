package com.farmos.farmos.service;

import com.farmos.farmos.model.Farm;
import com.farmos.farmos.repository.FarmRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class FarmService {

    private final FarmRepository farmRepository;

    public FarmService(FarmRepository farmRepository) {
        this.farmRepository = farmRepository;
    }

    public List<Farm> getAllFarms() {
        return farmRepository.findAll();
    }

    public Farm createFarm(Farm farm) {
        return farmRepository.save(farm);
    }
    public void deleteFarm(Long id) {
        farmRepository.deleteById(id);
    }
    public Farm updateFarm(Long id, Farm updatedFarm) {
        Farm farm = farmRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Farm not found"));

        farm.setName(updatedFarm.getName());
        farm.setAcres(updatedFarm.getAcres());
        farm.setLocation(updatedFarm.getLocation());

        return farmRepository.save(farm);
    }
}