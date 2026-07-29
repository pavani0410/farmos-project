package com.farmos.farmos.service;

import java.net.URL;
import java.security.interfaces.RSAPublicKey;

import org.springframework.stereotype.Service;

import com.auth0.jwk.Jwk;
import com.auth0.jwk.JwkProvider;
import com.auth0.jwk.UrlJwkProvider;
import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;

@Service
public class CognitoTokenValidator {

    private static final String REGION = "ap-southeast-2";
    private static final String USER_POOL_ID = "ap-southeast-2_e9SbsucDJ";
    private static final String ISSUER =
            "https://cognito-idp." + REGION + ".amazonaws.com/" + USER_POOL_ID;
    private static final String JWKS_URL =
            ISSUER + "/.well-known/jwks.json";

    private final JwkProvider jwkProvider;

    public CognitoTokenValidator() throws Exception {
        this.jwkProvider = new UrlJwkProvider(new URL(JWKS_URL));
    }

    /**
     * Validates a Cognito-issued ID token's signature, issuer, and expiry.
     * Returns the decoded token if valid, throws an exception if not.
     */
    public DecodedJWT validate(String token) throws Exception {
        DecodedJWT unverified = JWT.decode(token);

        String keyId = unverified.getKeyId();
        Jwk jwk = jwkProvider.get(keyId);
        RSAPublicKey publicKey = (RSAPublicKey) jwk.getPublicKey();

        Algorithm algorithm = Algorithm.RSA256(publicKey, null);

        DecodedJWT verified = JWT.require(algorithm)
                .withIssuer(ISSUER)
                .build()
                .verify(token);

        return verified;
    }
}