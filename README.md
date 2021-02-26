# Демо-приложение для вебинара "Tarantool Cartridge: разработка отказоустойчивого кластера"

В данном репозитории хранится исходный код демо-приложения, являющегося примером работы Java-приложения
с кластером [Tarantool](http://tarantool.io).

Слайды презентации доступны в файле [slides.pdf](./slides.pdf).

## Запуск демонстративного кластера через docker-compose
На схеме ниже показан вариант развертывания демо-приложения в виде набора docker-контейнеров
(см. файл [docker-compose.yml](./docker-compose.yml)).
![deployment_schema](./deployment-schema.png)

Для запуска демо-приложения в виде набора docker-контейнеров необходимо выполнить следующие шаги:

1. Выполнить сборку веб-приложения через команду

```shell
mvnw clean package
```
или
```shell
sh mvnw clean package
```

2. Запустить сеть docker-контейнеров через команду

```shell
docker-compose up --build --detach
```   

3. Подключиться к консоли одного из контейнеров, например, к `tarantool-server1` через команду

```shell
docker-compose exec tarantool-server1 /bin/bash
```

4. Подключитесь с использованием `tarantoolctl` к экземпляру Tarantool.

```shell
tarantoolctl connect http://admin:admin@127.0.0.1:3301
```

5. Затем в командной строке tarantool выполните следующий lua-скрипт
   (см. файл [tarantool/init-script-demo.lua](./tarantool/init-script-demo.lua)).
   Он выполнит объединение экземпляров Tarantool в replica sets и назначение экземплярам определённых ролей.

```lua
cartridge = require('cartridge')
replicasets = { {
                   alias = 'router1',
                   roles = { 'router', 'vshard-router', 'failover-coordinator' },
                   join_servers = { { uri = 'tarantool-server1:3301' } }
                }, {
                   alias = 'router2',
                   roles = { 'router', 'vshard-router', 'failover-coordinator' },
                   join_servers = { { uri = 'tarantool-server2:3301' } }
                }, {
                   alias = 'router3',
                   roles = { 'router', 'vshard-router', 'failover-coordinator' },
                   join_servers = { { uri = 'tarantool-server3:3301' } }
                }, {
                   alias = 'storage1',
                   roles = { 'storage', 'vshard-storage' },
                   join_servers = { { uri = 'tarantool-server4:3301' },
                                    { uri = 'tarantool-server5:3301' },
                                    { uri = 'tarantool-server6:3301' } }
                }, {
                   alias = 'storage2',
                   roles = { 'storage', 'vshard-storage' },
                   join_servers = { { uri = 'tarantool-server7:3301' },
                                    { uri = 'tarantool-server8:3301' },
                                    { uri = 'tarantool-server9:3301' } }
                }}
cartridge.admin_edit_topology({ replicasets = replicasets })
```

Если произойдёт отключение от консоли Tarantool, то снова выполните подключение к ней

```shell
tarantoolctl connect http://admin:admin@127.0.0.1:3301
```

В командной строке tarantool выполните следующий lua-скрипт, который выполнит инициализацию шардинга БД и включение
режима аварийного восстановления с использованием etcd для хранения информации о состоянии кластера.

```lua
cartridge.admin_bootstrap_vshard()
cartridge.failover_set_params({
   mode = 'stateful',
   state_provider = 'etcd2',
   failover_timeout = 10,
   etcd2_params = {
      prefix = '/',
      lock_delay = 10,
      endpoints = { '172.20.0.12:2379', '172.20.0.13:2379', '172.20.0.14:2379' }
   }
})
```
6. Корректности настройки кластера можно проверить через веб-приложение Tarantool Cartridge
   `http://<IP-адрес хоста, где запускается docker>:8081/admin` (например, http://localhost:8081/admin или
   http://192.168.99.100:8081/admin).
   
7. Для получения доступа к Swagger-UI демо-приложения переходите по ссылке http://localhost:8080/swagger-ui или
http://192.168.99.100/swagger-ui.

## Запуск демонстративного кластера в Gitpod
Для запуска демо-приложения в облаке [gitpod.io](https://gitpod.io) необходимо выполнить следующие действия:
1. Создайте учётную запись на [gitpod.io](https://gitpod.io).
2. Необходимо в личном кабинете gitpod.io зайти в раздел Settings и проставить галочку напротив настойки
"Enable Feature Preview". Это позволит запускать docker-контейнеры внутри docker-контейнера с облачной IDE.
3. Запустить workspace с приложением. Создать workspace можно, перейдя по ссылке https://gitpod.io/#https://github.com/peneksglazami/tarantool-cartridge-webinar.
   [![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/peneksglazami/tarantool-cartridge-webinar)
4. В терминале выполните команду `sudo docker-up`. Эта команда запустит демон docker.
5. Откройте новое окно терминала и далее выполните команды запуска кластера, описанные выше в разделе
"Запуск демонстративного кластера через docker-compose".
