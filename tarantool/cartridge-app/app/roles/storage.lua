local function init(opts)
    if opts.is_master then

        -- Список учётных записей пользователей.
        -- Для данного списка будет применяться шардирование.
        -- bucket_id необходимо привязать к логину пользователя.
        local users = box.schema.space.create('users',
            { if_not_exists = true }
        )

        users:format({
            { 'bucket_id', 'unsigned' },
            { 'uuid', 'string' },
            { 'login', 'string' },
            { 'password', 'string' },
            { 'status', 'string' }
        })

        users:create_index('user_login_index', {
            parts = { { field = "login", type = "string" } },
            if_not_exists = true
        })

        users:create_index('user_uuid_index', {
            parts = { { field = "uuid", type = "string" } },
            if_not_exists = true
        })
        
        -- Данные о привязке пользователей к определённым группам
        local user_groups = box.schema.space.create('user_groups',
            { if_not_exists = true }
        )

        user_groups:format({
            { 'bucket_id', 'unsigned' },
            { 'user_uuid', 'string' },
            { 'group_id', 'string' }
        })

        user_groups:create_index('user_groups_user_uuid_group_id_index', {
            parts = { { field = "user_uuid", type = "string" }, { field = "group_id", type = "string" } },
            unique = true,
            if_not_exists = true
        })

        user_groups:create_index('bucket_id', {
            parts = { 'bucket_id' },
            unique = false,
            if_not_exists = true
        })

        user_groups:create_index('user_groups_user_uuid_index', {
            parts = { { field = "user_uuid", type = "string" } },
            unique = false,
            if_not_exists = true
        })

        user_groups:create_index('user_groups_group_id_index', {
            parts = { { field = "group_id", type = "string" } },
            unique = false,
            if_not_exists = true
        })

        -- Обратный индекс для поиска логина клиента по uuid.
        -- Для данного списка будет применяться шардирование.
        -- bucket_id необходимо привязать к uuid пользователя.
        local uuid_login = box.schema.space.create('uuid_login',
            { if_not_exists = true }
        )

        uuid_login:format({
            { 'bucket_id', 'unsigned' },
            { 'uuid', 'string' },
            { 'login', 'string' }
        })

        uuid_login:create_index('user_uuid_index', {
            parts = { { field = "uuid", type = "string" } },
            if_not_exists = true
        })
    end
end

local role_name = "storage"

return {
    dependencies = { 'cartridge.roles.vshard-storage' },
    role_name = role_name,
    init = init
}
