package com.farmos.farmos.service;

import com.farmos.farmos.model.Farm;
import com.farmos.farmos.model.User;
import com.farmos.farmos.repository.FarmRepository;
import com.farmos.farmos.repository.UserRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class FarmService {

    private final FarmRepository farmRepository;
    private final UserRepository userRepository;

    public FarmService(FarmRepository farmRepository, UserRepository userRepository) {
        this.farmRepository = farmRepository;
        this.userRepository = userRepository;
    }

    public List<Farm> getAllFarmsForUser(Long userId) {
        return farmRepository.findByUserId(userId);
    }

    public Farm createFarm(Long userId, Farm farm) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        farm.setUser(user);
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