cartridge = require('cartridge')
replicasets = { {
                    alias = 'router1',
                    roles = { 'router', 'vshard-router', 'failover-coordinator' },
                    join_servers = { { uri = 'localhost:3301' } }
                }, {
                    alias = 'router2',
                    roles = { 'router', 'vshard-router', 'failover-coordinator' },
                    join_servers = { { uri = 'localhost:3305' } }
                }, {
                    alias = 'router3',
                    roles = { 'router', 'vshard-router', 'failover-coordinator' },
                    join_servers = { { uri = 'localhost:3309' } }
                }, {
                    alias = 'storage1',
                    roles = { 'storage', 'vshard-storage' },
                    join_servers = { { uri = 'localhost:3302' },
                                     { uri = 'localhost:3303' },
                                     { uri = 'localhost:3304' } }
                }, {
                    alias = 'storage2',
                    roles = { 'storage', 'vshard-storage' },
                    join_servers = { { uri = 'localhost:3306' },
                                     { uri = 'localhost:3307' },
                                     { uri = 'localhost:3308' } }
                }, {
                    alias = 'storage3',
                    roles = { 'storage', 'vshard-storage' },
                    join_servers = { { uri = 'localhost:3310' },
                                     { uri = 'localhost:3311' },
                                     { uri = 'localhost:3312' } }
                } }
return cartridge.admin_edit_topology({ replicasets = replicasets })
