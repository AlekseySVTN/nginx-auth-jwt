use Test::Nginx::Socket 'no_plan';

no_root_location();
no_shuffle();

run_tests();

__DATA__

=== valid
--- http_config
include $TEST_NGINX_CONF_DIR/authorized_server.conf;
--- config
include $TEST_NGINX_CONF_DIR/jwt.conf;
location / {
  auth_jwt "" token=$test1_with_nbf_jwt;
  auth_jwt_key_file $TEST_NGINX_DATA_DIR/jwks.json;
  auth_jwt_validate_nbf on;
  include $TEST_NGINX_CONF_DIR/authorized_proxy.conf;
}
--- request
GET /
--- response_headers
X-Jwt-Claim-Iss: https://test1.issuer.example.com
X-Jwt-Claim-Sub: test1.identifier
X-Jwt-Claim-Aud: test1.audience.example.com
X-Jwt-Claim-Email: test1@example.com
--- error_code: 200

=== missing nbf
--- http_config
include $TEST_NGINX_CONF_DIR/authorized_server.conf;
--- config
include $TEST_NGINX_CONF_DIR/jwt.conf;
location / {
  auth_jwt "" token=$test1_jwt;
  auth_jwt_key_file $TEST_NGINX_DATA_DIR/jwks.json;
  auth_jwt_validate_nbf on;
  include $TEST_NGINX_CONF_DIR/authorized_proxy.conf;
}
--- request
GET /
--- response_headers
X-Jwt-Claim-Iss:
X-Jwt-Claim-Sub:
X-Jwt-Claim-Aud:
X-Jwt-Claim-Email:
--- error_code: 401
--- error_log: auth_jwt: rejected due to nbf claim could not be obtained
--- log_level: info

=== missing nbf on off
--- http_config
include $TEST_NGINX_CONF_DIR/authorized_server.conf;
--- config
include $TEST_NGINX_CONF_DIR/jwt.conf;
location / {
  auth_jwt "" token=$test1_jwt;
  auth_jwt_key_file $TEST_NGINX_DATA_DIR/jwks.json;
  auth_jwt_validate_nbf off;
  include $TEST_NGINX_CONF_DIR/authorized_proxy.conf;
}
--- request
GET /
--- response_headers
X-Jwt-Claim-Iss: https://test1.issuer.example.com
X-Jwt-Claim-Sub: test1.identifier
X-Jwt-Claim-Aud: test1.audience.example.com
X-Jwt-Claim-Email: test1@example.com
--- error_code: 200

=== invalid
--- http_config
include $TEST_NGINX_CONF_DIR/authorized_server.conf;
--- config
include $TEST_NGINX_CONF_DIR/jwt.conf;
location / {
  auth_jwt "" token=$test1_with_invalid_nbf_jwt;
  auth_jwt_key_file $TEST_NGINX_DATA_DIR/jwks.json;
  auth_jwt_validate_nbf on;
  include $TEST_NGINX_CONF_DIR/authorized_proxy.conf;
}
--- request
GET /
--- response_headers
X-Jwt-Claim-Iss:
X-Jwt-Claim-Sub:
X-Jwt-Claim-Aud:
X-Jwt-Claim-Email:
--- error_code: 401
--- error_log eval
qr/auth_jwt: rejected due to nbf claim validate failure: nbf=4133862000: after or equal to expected=[0-9]+ actual=4133862000/
--- log_level: info

=== valid in leeway
--- http_config
include $TEST_NGINX_CONF_DIR/authorized_server.conf;
--- config
include $TEST_NGINX_CONF_DIR/jwt.conf;
location / {
  auth_jwt "" token=$test1_with_invalid_nbf_jwt;
  auth_jwt_key_file $TEST_NGINX_DATA_DIR/jwks.json;
  auth_jwt_validate_nbf on;
  auth_jwt_leeway 100y;
  include $TEST_NGINX_CONF_DIR/authorized_proxy.conf;
}
--- request
GET /
--- response_headers
X-Jwt-Claim-Iss: https://test1.issuer.example.com
X-Jwt-Claim-Sub: test1.identifier
X-Jwt-Claim-Aud: test1.audience.example.com
X-Jwt-Claim-Email: test1@example.com
--- error_code: 200
