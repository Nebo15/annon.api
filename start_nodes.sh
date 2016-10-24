env GATEWAY_PUBLIC_PORT=$1 \
    GATEWAY_PRIVATE_PORT=$2 \
    iex --sname $3@localhost \
        --cookie my_secret_cookie \
        -S mix run
