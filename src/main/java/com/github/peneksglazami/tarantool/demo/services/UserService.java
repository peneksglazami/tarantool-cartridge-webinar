package com.github.peneksglazami.tarantool.demo.services;

import com.github.peneksglazami.tarantool.demo.model.rest.CreateUserRequest;
import com.github.peneksglazami.tarantool.demo.model.rest.GetUserResponse;
import com.github.peneksglazami.tarantool.demo.model.rest.UpdateUserRequest;
import com.github.peneksglazami.tarantool.demo.model.rest.UserGroupUpdateRequest;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final TarantoolStorageService storageService;

    public UserService(TarantoolStorageService storageService) {
        this.storageService = storageService;
    }

    public GetUserResponse getUserByUUID(String uuid) {
        return storageService.getUserByUUID(uuid);
    }

    public boolean updateUser(String uuid, UpdateUserRequest request) {
        return storageService.updateUser(uuid, request);
    }

    public boolean deleteUser(String uuid) {
        return storageService.deleteUser(uuid);
    }

    public void updateUserGroup(UserGroupUpdateRequest request) {
        storageService.updateUserGroup(request);
    }

    public String createUser(CreateUserRequest request) {
        return storageService.createUser(request);
    }
}
