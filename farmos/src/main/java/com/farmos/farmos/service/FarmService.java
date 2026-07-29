package com.farmos.farmos.service;

import com.farmos.farmos.model.Farm;

import java.util.List;

public interface FarmService {

    List<Farm> getAllFarmsForUser(Long userId);

    Farm createFarm(Long userId, Farm farm);

    void deleteFarm(Long id);

    Farm updateFarm(Long id, Farm updatedFarm);
}
