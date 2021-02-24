package com.github.peneksglazami.tarantool.demo.services;

import com.github.peneksglazami.tarantool.demo.model.UserInfo;
import com.github.peneksglazami.tarantool.demo.model.rest.*;
import io.tarantool.driver.api.TarantoolClient;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class TarantoolStorageService {

    private final TarantoolClient tarantoolClient;

    public TarantoolStorageService(TarantoolClient tarantoolClient) {
        this.tarantoolClient = tarantoolClient;
    }

    public UserInfo getUserByLogin(String login) {
        List<Object> userTuple = null;
        try {
            userTuple = (List<Object>) tarantoolClient.call("get_user_by_login", login).get().get(0);
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }

        if ((userTuple != null) && !userTuple.isEmpty()) {
            UserInfo userInfo = new UserInfo();
            userInfo.setUuid((String) userTuple.get(1));
            userInfo.setLogin((String) userTuple.get(2));
            userInfo.setPasswordHash((String) userTuple.get(3));
            userInfo.setStatus((String) userTuple.get(4));
            return userInfo;
        }

        return null;
    }

    public String createUser(CreateUserRequest request) {
        String userUuid = UUID.randomUUID().toString();
        Object res = null;
        try {
            res = tarantoolClient.call("create_user",
                    userUuid,
                    request.getLogin(),
                    DigestUtils.md5DigestAsHex(request.getPassword().getBytes()),
                    request.getStatus().getValue(),
                    request.getGroups()
            ).get().get(0);
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        return (String) res;
    }

    public GetUserResponse getUserByUUID(String uuid) {
        List<List<Object>> res = null;
        try {
            res = (List<List<Object>>) tarantoolClient.call("get_user_by_uuid", uuid).get().get(0);
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }

        if (res != null && !res.isEmpty()) {
            List<Object> userTuple = res.get(0);
            GetUserResponse userInfo = new GetUserResponse();
            userInfo.setUuid((String) userTuple.get(1));
            userInfo.setLogin((String) userTuple.get(2));
            userInfo.setStatus(UserStatus.fromValue((String) userTuple.get(4)));
            List<Object> groupTuples = res.get(1);
            List<String> groups = groupTuples.stream()
                    .map(groupTuple -> ((List<Object>) groupTuple).get(2).toString())
                    .collect(Collectors.toList());
            userInfo.setGroups(groups);
            return userInfo;
        }

        return null;
    }

    public boolean deleteUser(String uuid) {
        Object res = null;
        try {
            res = tarantoolClient.call("delete_user_by_uuid", uuid).get().get(0);
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        return res != null;
    }

    public boolean updateUser(String userUuid, UpdateUserRequest request) {
        Object res = null;
        try {
            res = tarantoolClient.call("update_user",
                    userUuid,
                    request.getLogin(),
                    DigestUtils.md5DigestAsHex(request.getPassword().getBytes()),
                    request.getStatus().getValue(),
                    request.getGroups()
            ).get().get(0);
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        return res != null;
    }

    public void updateUserGroup(UserGroupUpdateRequest request) {
        tarantoolClient.call("update_user_group",
                request.getGroupId(),
                request.getNewStatus().toString()
        );
    }
}
