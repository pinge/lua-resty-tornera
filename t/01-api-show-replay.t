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

=== TEST 1: GET /_replay show replay resource
--- http_config eval: $::HttpConfig
--- config
location /_replay {
    content_by_lua_block {
        tornera_api:process_api_request()
    }
}
--- request
GET /_replay
--- response_headers_like
Content-Type: application/json
--- response_body chomp
{}
--- error_code: 200
