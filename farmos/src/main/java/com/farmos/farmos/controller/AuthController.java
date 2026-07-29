package com.farmos.farmos.controller;

import java.util.Map;
import java.util.Optional;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.farmos.farmos.model.User;
import com.farmos.farmos.repository.UserRepository;
import com.farmos.farmos.service.CognitoTokenValidator;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserRepository userRepository;
    private final CognitoTokenValidator cognitoTokenValidator;

    public AuthController(UserRepository userRepository, CognitoTokenValidator cognitoTokenValidator) {
        this.userRepository = userRepository;
        this.cognitoTokenValidator = cognitoTokenValidator;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");

        User user = userRepository.findByUsername(username).orElse(null);

        if (user == null || !user.getPassword().equals(password)) {
            return ResponseEntity.status(401).body(Map.of("error", "Invalid username or password"));
        }

        return ResponseEntity.ok(Map.of(
                "id", user.getId(),
                "username", user.getUsername()
        ));
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");

        User user = new User();
        user.setUsername(username);
        user.setPassword(password);

        User saved = userRepository.save(user);

        return ResponseEntity.ok(Map.of(
                "id", saved.getId(),
                "username", saved.getUsername()
        ));
    }

    @PostMapping("/cognito")
    public ResponseEntity<?> cognitoLogin(@RequestBody Map<String, String> body) {
        String idToken = body.get("idToken");

        if (idToken == null || idToken.isBlank()) {
            return ResponseEntity.status(400).body(Map.of("error", "Missing idToken"));
        }

        DecodedJWT decoded;
        try {
            decoded = cognitoTokenValidator.validate(idToken);
        } catch (Exception e) {
            return ResponseEntity.status(401).body(Map.of("error", "Invalid or expired token"));
        }

        String cognitoSub = decoded.getSubject();
        String email = decoded.getClaim("email").asString();

        Optional<User> existing = userRepository.findByCognitoSub(cognitoSub);

        User user;
        if (existing.isPresent()) {
            user = existing.get();
        } else {
            user = new User();
            user.setCognitoSub(cognitoSub);
            user.setEmail(email);
            // Generate a unique username since Cognito's own generated
            // username (e.g. "loginwithamazon_amzn1.account...") is long and ugly.
            String baseUsername = (email != null && email.contains("@"))
                    ? email.substring(0, email.indexOf("@"))
                    : "amazon_user";
            String uniqueUsername = baseUsername + "_" + cognitoSub.substring(0, 8);
            user.setUsername(uniqueUsername);
            user = userRepository.save(user);
        }

        return ResponseEntity.ok(Map.of(
                "id", user.getId(),
                "username", user.getUsername()
        ));
    }
}