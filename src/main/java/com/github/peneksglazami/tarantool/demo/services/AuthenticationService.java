package com.github.peneksglazami.tarantool.demo.services;

import com.github.peneksglazami.tarantool.demo.model.UserInfo;
import com.github.peneksglazami.tarantool.demo.model.rest.LoginResponse;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.util.UUID;

@Service
public class AuthenticationService {

    private final TarantoolStorageService storageService;

    public AuthenticationService(TarantoolStorageService storageService) {
        this.storageService = storageService;
    }

    public LoginResponse authenticate(String login, String password) {
        UserInfo userInfo = storageService.getUserByLogin(login);

        if (userInfo == null) {
            return null;
        }

        String passwordHash = DigestUtils.md5DigestAsHex(password.getBytes());
        if (userInfo.getPasswordHash().equals(passwordHash)) {
            LoginResponse resp = new LoginResponse();
            resp.setAuthToken(UUID.randomUUID().toString()); // Для примера пусть будет просто UUID
            return resp;
        } else {
            return null;
        }
    }
}