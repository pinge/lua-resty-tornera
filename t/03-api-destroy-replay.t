use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $shm_handle = 'tornera_config';
my $pwd = cwd();

our $HttpConfig = qq{
    lua_shared_dict $shm_handle 1m;
    lua_package_path "$pwd/lib/?.lua;";
    init_by_lua_block {
        local tornera_api_m = require "resty/tornera/api"
        tornera_api = tornera_api_m:new("$shm_handle")
    }
};

no_long_string();

run_tests();

__DATA__

=== TEST 1: DELETE /_replay destroy replay resource
--- http_config eval: $::HttpConfig
--- config
location /_replay {
    content_by_lua_block {
        tornera_api:process_api_request()
    }
}
--- request
DELETE /_replay
--- response_headers_like
Content-Type: application/json
--- error_code: 200
