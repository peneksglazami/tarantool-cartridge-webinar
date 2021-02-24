local vshard = require('vshard')
local log = require('log')

local function init(opts)
    return true
end

local function stop()
end

local function validate_config(conf_new, conf_old)
    return true
end

local function apply_config(conf, opts)
    return true
end

local USERS_BUCKET_ID_FIELD_NUM = 1;
local USERS_UUID_FIELD_NUM = 2;
local USERS_LOGIN_FIELD_NUM = 3;
local USERS_PASSWORD_FIELD_NUM = 4;
local USERS_STATUS_FIELD_NUM = 5;
local USER_GROUPS_BUCKET_ID_FIELD_NUM = 1;
local USER_GROUPS_USER_UUID_FIELD_NUM = 2;
local USER_GROUPS_GROUP_ID_FIELD_NUM = 3;
local UUID_LOGIN_LOGIN_FIELD_NUM = 3;

--- Определение логина пользователя по UUID учётной записи пользователя.
-- @param user_uuid UUID учетной записи пользователя.
-- @return Логин пользователя.
function get_user_login_by_uuid(user_uuid)
    log.debug('get_user_login_by_uuid ' .. user_uuid)
    local bucket_id = vshard.router.bucket_id(user_uuid)
    local user_login, _ = vshard.router.callbro(bucket_id, 'box.space.uuid_login:select', { user_uuid })
    if user_login[1] == nil then
        return nil
    end

    return user_login[1][UUID_LOGIN_LOGIN_FIELD_NUM];
end

--- Установка связки между UUID учётной записи пользователя и логином пользователя.
-- @param user_uuid UUID учетной записи пользователя.
-- @param login Логин пользователя.
function add_uuid_login_mapping(user_uuid, login)
    log.debug('add_uuid_login_mapping ' .. user_uuid .. '|' .. login)
    local bucket_id = vshard.router.bucket_id(user_uuid)
    local _, _ = vshard.router.callrw(bucket_id, 'box.space.uuid_login:insert', {
        { bucket_id, user_uuid, login }
    })
end

--- Удаление связки между UUID учётной записи пользователя и логином пользователя.
-- @param user_uuid UUID учетной записи пользователя.
function delete_uuid_login_mapping(user_uuid)
    log.debug('delete_uuid_login_mapping ' .. user_uuid)
    local bucket_id = vshard.router.bucket_id(user_uuid)
    local _, _ = vshard.router.callrw(bucket_id, 'box.space.uuid_login:delete', {
        { user_uuid }
    })
end

--- Обновление связки между UUID учётной записи пользователя и логином пользователя.
-- @param user_uuid UUID учетной записи пользователя.
-- @param login Логин пользователя.
function update_uuid_login_mapping(user_uuid, login)
    log.debug('update_uuid_login_mapping ' .. user_uuid .. '|' .. login)
    local bucket_id = vshard.router.bucket_id(user_uuid)
    local _, _ = vshard.router.callrw(bucket_id, 'box.space.uuid_login:update', { user_uuid, {
        { '=', UUID_LOGIN_LOGIN_FIELD_NUM, login },
    } })
end

--- Создание учётной записи пользователя.
function create_user(user_uuid, login, password_hash, status, groups)
    log.debug('create_user ' .. user_uuid .. '|' .. login .. '|' .. password_hash .. '|' .. status)

    local bucket_id = vshard.router.bucket_id(login);

    local _, err = vshard.router.callrw(bucket_id, 'box.space.users:insert', {
        { bucket_id, user_uuid, login, password_hash, status }
    })

    if err ~= nil then
        log.error(err)
        return nil
    end

    insert_user_groups(bucket_id, user_uuid, groups)
    add_uuid_login_mapping(user_uuid, login)

    return user_uuid
end

--- Получение информации об учётной записи пользователя по логину пользователя.
function get_user_by_login(login)
    log.debug('get_user_by_login ' .. login)

    local bucket_id = vshard.router.bucket_id(login);

    local users, err = vshard.router.callbro(bucket_id, 'box.space.users:select', { login })

    if err ~= nil then
        log.error(err)
        return nil
    end

    return users[1]
end

--- Получение информации об учётной записи пользователя по UUID учётной записи.
function get_user_by_uuid(user_uuid)
    log.debug('get_user_by_uuid ' .. user_uuid)

    local login = get_user_login_by_uuid(user_uuid)
    if login == nil then
        return nil
    end

    local user = get_user_by_login(login)
    local user_groups = get_user_groups(user[USERS_BUCKET_ID_FIELD_NUM], user_uuid)
    return { user, user_groups }
end

--- Удаление учётной записи пользователя по UUID учётной записи.
function delete_user_by_uuid(user_uuid)
    log.debug('delete_user_by_uuid ' .. user_uuid)

    local login = get_user_login_by_uuid(user_uuid)
    if login == nil then
        return nil
    end

    local user = get_user_by_login(login)

    if user ~= nil then
        local user_groups, _ = vshard.router.callbro(user[USERS_BUCKET_ID_FIELD_NUM], 'box.space.user_groups.index.user_groups_user_uuid_index:select', { user_uuid })
        for _, user_group in pairs(user_groups) do
            vshard.router.callrw(user[USERS_BUCKET_ID_FIELD_NUM], 'box.space.user_groups:delete', { { user_group[USER_GROUPS_USER_UUID_FIELD_NUM], user_group[USER_GROUPS_GROUP_ID_FIELD_NUM] } })
        end

        delete_uuid_login_mapping(user_uuid)

        return user
    end

    return nil
end

--- Удаление учётной записи пользователя по логину пользователя.
function delete_user_by_login(login)
    log.debug('delete_user_by_login ' .. login)

    local bucket_id = vshard.router.bucket_id(login);

    local user, err = vshard.router.callrw(bucket_id, 'box.space.users:delete', { login })

    if err ~= nil then
        log.error(err)
        return nil
    end

    delete_user_groups(bucket_id, user[USERS_UUID_FIELD_NUM])
    delete_uuid_login_mapping(user[USERS_UUID_FIELD_NUM])

    return user
end

--- Обновление учётной записи пользователя. Поиск учётной записи производится по UUID учётной записи.
function update_user(user_uuid, new_login, password_hash, status, groups)
    log.debug('update_user ' .. user_uuid .. '|' .. new_login .. '|' .. password_hash .. '|' .. status)

    local login = get_user_login_by_uuid(user_uuid)
    if login == nil then
        return nil
    end

    local user = get_user_by_login(login)

    if user ~= nil then
        local new_bucket_id

        if new_login ~= login then
            new_bucket_id = vshard.router.bucket_id(new_login);
        end

        if new_bucket_id ~= nil and new_bucket_id ~= user[USERS_BUCKET_ID_FIELD_NUM] then
            delete_user_by_login(login);
            return create_user(user_uuid, new_login, password_hash, status, groups)
        else
            update_user_internal(user[USERS_BUCKET_ID_FIELD_NUM], user_uuid, new_login, password_hash, status, groups)
            if new_login ~= login then
                update_uuid_login_mapping(user_uuid, new_login)
            end

            return user_uuid
        end
    end

    return nil
end

function update_user_internal(bucket_id, user_uuid, login, password_hash, status, groups)
    log.debug('update_user_internal ' .. bucket_id .. '|' .. user_uuid .. '|' .. login .. '|' .. password_hash .. '|' .. status)
    local user, err = vshard.router.callrw(bucket_id, 'box.space.users:update', { login, {
        { '=', USERS_LOGIN_FIELD_NUM, login },
        { '=', USERS_PASSWORD_FIELD_NUM, password_hash },
        { '=', USERS_STATUS_FIELD_NUM, status }
    } })

    if err ~= nil then
        log.error(err)
        return nil, err
    end

    delete_user_groups(bucket_id, user_uuid)
    insert_user_groups(bucket_id, user_uuid, groups)

    return user
end

function delete_user_groups(bucket_id, user_uuid)
    log.debug('delete_user_groups ' .. bucket_id .. '|' .. user_uuid)
    local user_groups, _ = vshard.router.callbro(bucket_id, 'box.space.user_groups.index.user_groups_user_uuid_index:select', { user_uuid })
    for _, user_group in pairs(user_groups) do
        local _, err = vshard.router.callrw(bucket_id, 'box.space.user_groups:delete', { { user_group[USER_GROUPS_USER_UUID_FIELD_NUM], user_group[USER_GROUPS_GROUP_ID_FIELD_NUM] } })

        if err ~= nil then
            log.error(err)
            return nil
        end
    end
end

function get_user_groups(bucket_id, user_uuid)
    log.debug('get_user_groups ' .. bucket_id .. '|' .. user_uuid)
    local user_groups, _ = vshard.router.callbro(bucket_id, 'box.space.user_groups.index.user_groups_user_uuid_index:select', { user_uuid })
    return user_groups
end

function insert_user_groups(bucket_id, user_uuid, groups)
    log.debug('insert_user_groups ' .. bucket_id .. '|' .. user_uuid)
    for i = 1, #groups do
        local _, err = vshard.router.callrw(bucket_id, 'box.space.user_groups:insert', {
            { bucket_id, user_uuid, groups[i] }
        })

        if err ~= nil then
            log.error(err)
            return nil
        end
    end
end

--- Установка нового статуса для всех учётных записей, которые относятся к указанной группе.
function update_user_group(filter_group_id, new_status)
    log.debug('update_user_group filter_group_id = ' .. filter_group_id .. ' new_status = ' .. new_status)

    local startTime = os.time()

    local replicaset, _ = vshard.router.routeall()
    for _, replica in pairs(replicaset) do
        local user_groups, _ = replica:callbro('box.space.user_groups.index.user_groups_group_id_index:select', { filter_group_id })
        for _, user_group in pairs(user_groups) do
            local bucket_id = user_group[USER_GROUPS_BUCKET_ID_FIELD_NUM]
            local users, _ = vshard.router.callrw(bucket_id, 'box.space.users.index.user_uuid_index:select', { user_group[USER_GROUPS_USER_UUID_FIELD_NUM] })
            local user = users[1]
            if user ~= nil then
                vshard.router.callrw(bucket_id, 'box.space.users:update', { user[USERS_LOGIN_FIELD_NUM], {
                    { '=', USERS_STATUS_FIELD_NUM, new_status }
                } })
            end
        end
    end

    local endTime = os.difftime(os.time(), startTime)
    log.debug('update_user_group execution time: ' .. endTime .. ' sec.')

    return nil
end

local role_name = "router"

return {
    dependencies = { 'cartridge.roles.vshard-router' },
    role_name = role_name,
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config
}
