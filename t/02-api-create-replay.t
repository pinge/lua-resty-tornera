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

=== TEST 1: POST /_replay create replay resource without parameters
--- http_config eval: $::HttpConfig
--- config
location /_replay {
    content_by_lua_block {
        tornera_api:process_api_request()
    }
}
--- request
POST /_replay
--- response_headers_like
Content-Type: application/json
--- error_code: 400

=== TEST 2: POST /_replay create replay resource with 'port' parameter only
--- http_config eval: $::HttpConfig
--- config
location /_replay {
    content_by_lua_block {
        tornera_api:process_api_request()
    }
}
--- request
POST /_replay?port=8080
--- response_headers_like
Content-Type: application/json
--- error_code: 400

=== TEST 3: POST /_replay create replay resource with 'host' and 'port' parameters only
--- http_config eval: $::HttpConfig
--- config
location /_replay {
    content_by_lua_block {
        tornera_api:process_api_request()
    }
}
--- request
POST /_replay?host=127.0.0.1&port=8080
--- response_headers_like
Content-Type: application/json
--- error_code: 400

=== TEST 4: POST /_replay create replay resource with valid parameters
--- http_config eval: $::HttpConfig
--- config
location /_replay {
    content_by_lua_block {
        tornera_api:process_api_request()
    }
}
--- request
POST /_replay?host=127.0.0.1&port=8080&duration=60
--- response_body chomp
{"host":"127.0.0.1","port":8080,"duration":60}
--- response_headers_like
Content-Type: application/json
--- error_code: 201

=== TEST 5: POST /_replay create replay resource with 'host' and 'duration' parameters only
--- http_config eval: $::HttpConfig
--- config
location /_replay {
    content_by_lua_block {
        tornera_api:process_api_request()
    }
}
--- request
POST /_replay?host=127.0.0.1&duration=60
--- response_body chomp
{"host":"127.0.0.1","port":80,"duration":60}
--- response_headers_like
Content-Type: application/json
--- error_code: 201

