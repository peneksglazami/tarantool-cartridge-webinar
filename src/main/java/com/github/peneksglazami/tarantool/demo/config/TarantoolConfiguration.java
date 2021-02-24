package com.github.peneksglazami.tarantool.demo.config;

import io.tarantool.driver.ClusterTarantoolClient;
import io.tarantool.driver.TarantoolServerAddress;
import io.tarantool.driver.api.TarantoolClient;
import io.tarantool.driver.auth.SimpleTarantoolCredentials;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;
import java.util.Collection;
import java.util.stream.Collectors;

@Configuration
public class TarantoolConfiguration {

    @Bean
    public TarantoolClient tarantoolClient(
            @Value("${tarantool.nodes}") String nodes,
            @Value("${tarantool.username}") String username,
            @Value("${tarantool.password}") String password) {

        SimpleTarantoolCredentials credentials = new SimpleTarantoolCredentials(username, password);

        Collection<TarantoolServerAddress> tarantoolServerAddresses =
                Arrays.stream(nodes.split(","))
                        .map(address -> {
                            String[] addressParts = address.split(":");
                            String host = addressParts[0];
                            int port = Integer.parseInt(addressParts[1]);
                            return new TarantoolServerAddress(host, port);
                        }).collect(Collectors.toList());

        return new ClusterTarantoolClient(credentials, tarantoolServerAddresses);
    }

}
