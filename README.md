Name
====

lua-resty-tornera - A traffic replay tool with an easy to use API for OpenResty/LuaJIT

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Synopsis](#synopsis)
* [API Usage](#api-usage)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Status
======

This library is still under early development and is still experimental.

Description
===========

This Lua library allows you replay incoming traffic per location directive to a configured target host and port.

Synopsis
========

```lua

    lua_shared_dict tornera_config 1m;
    lua_package_path "/path/to/lua-resty-tornera/lib/?.lua;;";

    init_by_lua_block {
        local tornera_m = require "tornera"
        tornera = tornera_m:new("tornera_config")

        local tornera_api_m = require "lib/resty/tornera/api"
        tornera_api = tornera_api_m:new("tornera_config")
    }
    
    upstream backend {
        server backend1.example.com;
        server backend2.example.com;
    }

    location /test {
        proxy_pass backend;
        
        log_by_lua_block {
            tornera:replay_request()
        }
    }
    
    location /_replay {
        content_by_lua_block {
            allow 127.0.0.1;
            allow 10.0.0.0/8;
            deny all;
            tornera_api:process_api_request()
        }
    }

```

API Usage
=========

check traffic replay status:

```bash
curl -vvv http://localhost/_replay

> GET /_replay HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost
> Accept: */*
>
< HTTP/1.1 200 OK
* Server openresty is not blacklisted
< Server: openresty
< Content-Type: application/json
< Transfer-Encoding: chunked
< Connection: close
<
* Closing connection 0
{}
```

enable traffic replay by specifying the target and duration:

```bash
curl -v -X POST "http://localhost/_replay?host=127.0.0.1&port=8080&duration=60"

> POST /_replay?host=10.10.10.123&port=8080&duration=60 HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost
> Accept: */*
>
< HTTP/1.1 201 Created
* Server openresty is not blacklisted
< Server: openresty
< Content-Type: application/json
< Transfer-Encoding: chunked
< Connection: close
<
* Closing connection 0
{"host":"10.10.10.123","port":8080,"duration":60}
```

disable traffic replay

```bash
$ curl -v -X DELETE http://localhost/_replay

> DELETE /_replay HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost
> Accept: */*
>
< HTTP/1.1 200 OK
* Server openresty is not blacklisted
< Server: openresty
< Content-Type: application/json
< Transfer-Encoding: chunked
< Connection: close
<
* Closing connection 0
{}
```

[Back to TOC](#table-of-contents)

Author
======

Nuno Pinge <nuno@pinge.org>.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the 2-clause BSD license.

Copyright (C) 2016, Nuno Pinge <nuno@pinge.org>

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule

[Back to TOC](#table-of-contents)
