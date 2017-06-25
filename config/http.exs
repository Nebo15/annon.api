use Mix.Config
# This file configures HTTP and HTTPS endpoints of the Gateway

config :annon_api,
  enable_ssl?: {:system, :boolean, "GATEWAY_SSL_ENABLED", false}

config :annon_api, :private_http,
  port: {:system, :integer, "GATEWAY_PRIVATE_PORT", 8000}

config :annon_api, :management_http,
  port: {:system, :integer, "GATEWAY_MANAGEMENT_PORT", 4001}

config :annon_api, :public_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 4000}

config :annon_api, :public_https,
  port: {:system, :integer, "GATEWAY_PUBLIC_SSL_PORT", 4443},
  keyfile: {:system, :string, "SSL_KEY_PATH"},
  certfile: {:system, :string, "SSL_CERT_PATH"},
  cacertfile: {:system, :string, "SSL_CACERT_PATH"},
  dhfile: {:system, :string, "SSL_DHFILE_PATH"},
  versions: [:'tlsv1.2', :'tlsv1.1', :'tlsv1'],
  secure_renegotiate: true,
  client_renegotiation: false,
  reuse_sessions: true,
  honor_cipher_order: true,
  max_connections: :infinity,
  # Uses ciphers from Mozilla Modern compatibility suite
  # https://wiki.mozilla.org/Security/Server_Side_TLS#Modern_compatibility
  ciphers: [
    "ECDHE-ECDSA-AES256-GCM-SHA384",
    "ECDHE-RSA-AES256-GCM-SHA384",
    "ECDHE-ECDSA-CHACHA20-POLY1305",
    "ECDHE-RSA-CHACHA20-POLY1305",
    "ECDHE-ECDSA-AES128-GCM-SHA256",
    "ECDHE-RSA-AES128-GCM-SHA256",
    "ECDHE-ECDSA-AES256-SHA384",
    "ECDHE-RSA-AES256-SHA384",
    "ECDHE-ECDSA-AES128-SHA256",
    "ECDHE-RSA-AES128-SHA256"
  ],
  # http://erlang.org/doc/man/ssl.html#type-ssloption
  eccs: [
    :sect571r1, :sect571k1, :secp521r1, :brainpoolP512r1, :sect409k1,
    :sect409r1, :brainpoolP384r1, :secp384r1, :sect283k1, :sect283r1,
    :brainpoolP256r1, :secp256k1, :secp256r1, :sect239k1, :sect233k1,
    :sect233r1, :secp224k1, :secp224r1
  ]

config :annon_api, :ssl,
  redirect_port: {:system, :integer, "GATEWAY_SSL_REDIRECT_PORT", 443},
  hsts: {:system, :boolean, "GATEWAY_SSL_HSTS", false},
  expires: {:system, :integer, "GATEWAY_SSL_HSTS_EXPIRES", 31_536_000},
  preload: {:system, :boolean, "GATEWAY_SSL_HSTS_PRELOAD", false},
  subdomains: {:system, :boolean, "GATEWAY_SSL_HSTS_INCLUDE_SUBDOMAINS", false},
  rewrite_on: {:system, :list, "GATEWAY_SSL_REWRITE_ON", []}
