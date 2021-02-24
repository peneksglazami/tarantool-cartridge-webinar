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

-- Наполнение БД тестовыми записями
uuid = require('uuid')
function generate_test_data(user_count)
    for i = 1, user_count do
        local groups
        if i <= user_count / 4 then
            groups = { 'group_1' }
        elseif i <= user_count / 2 then
            groups = { 'group_2' }
        elseif i <= user_count / 2 + user_count / 4 then
            groups = { 'group_3' }
        else
            groups = { 'group_4' }
        end
        create_user(uuid.str(), 'login' .. i, 'c4ca4238a0b923820dcc509a6f75849b', 'ACTIVE', groups)
    end
end

generate_test_data(50000);

vshard = require('vshard')
function clean_all_spaces()
    local replicaset, _ = vshard.router.routeall()
    for _, replica in pairs(replicaset) do
        replica:callrw('box.space.users:truncate', {})
        replica:callrw('box.space.user_groups:truncate', {})
    end
end