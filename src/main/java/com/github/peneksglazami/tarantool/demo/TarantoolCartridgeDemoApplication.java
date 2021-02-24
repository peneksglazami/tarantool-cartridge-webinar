package com.github.peneksglazami.tarantool.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import springfox.documentation.oas.annotations.EnableOpenApi;

@SpringBootApplication
@EnableOpenApi
public class TarantoolCartridgeDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(TarantoolCartridgeDemoApplication.class, args);
    }

}
