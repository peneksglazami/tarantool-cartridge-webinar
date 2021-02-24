package com.github.peneksglazami.tarantool.demo.controllers;

import com.github.peneksglazami.tarantool.demo.model.rest.*;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.github.peneksglazami.tarantool.demo.services.UserService;

@RestController
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping(value = "/user", produces = {"application/json"})
    public ResponseEntity<CreateUserResponse> createUser(@RequestBody CreateUserRequest request) {
        String uuid = userService.createUser(request);
        if (uuid != null) {
            CreateUserResponse resp = new CreateUserResponse();
            resp.setUuid(uuid);
            return ResponseEntity.status(HttpStatus.OK)
                    .cacheControl(CacheControl.noCache())
                    .body(resp);
        } else {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
    }

    @GetMapping(value = "/user/{uuid}", produces = {"application/json"})
    public ResponseEntity<GetUserResponse> getUser(@PathVariable("uuid") String uuid) {
        GetUserResponse resp = userService.getUserByUUID(uuid);
        if (resp != null) {
            return ResponseEntity.status(HttpStatus.OK)
                    .cacheControl(CacheControl.noCache())
                    .body(resp);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @PutMapping(value = "/user/{uuid}")
    public ResponseEntity<Void> updateUser(@PathVariable("uuid") String uuid,
                                           @RequestBody UpdateUserRequest request) {
        boolean updated = userService.updateUser(uuid, request);
        if (updated) {
            return ResponseEntity.status(HttpStatus.OK)
                    .cacheControl(CacheControl.noCache())
                    .build();
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping(value = "/user/{uuid}")
    public ResponseEntity<Void> deleteUser(@PathVariable("uuid") String uuid) {
        boolean updated = userService.deleteUser(uuid);
        if (updated) {
            return ResponseEntity.status(HttpStatus.OK)
                    .cacheControl(CacheControl.noCache())
                    .build();
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @PutMapping(value = "/user/update-group")
    public ResponseEntity<Void> updateUserGroup(@RequestBody UserGroupUpdateRequest request) {
        userService.updateUserGroup(request);

        return ResponseEntity.status(HttpStatus.OK)
                .cacheControl(CacheControl.noCache())
                .build();
    }
}
