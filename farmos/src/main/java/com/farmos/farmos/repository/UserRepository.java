package com.farmos.farmos.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.farmos.farmos.model.User;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByCognitoSub(String cognitoSub);
}