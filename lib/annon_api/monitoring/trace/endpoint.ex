defmodule Annon.Monitoring.Trace.Endpoint do
  defstruct serviceName: nil, # Classifier of this endpoint in lowercase, such as "acme-front-end"
            ipv4: nil, # The text representation of a IPv4 address associated with this endpoint. Ex. 192.168.99.100
            ipv6: nil, # The text representation of a IPv6 address associated with this endpoint. Ex. 2001:db8::c001
            port: nil
end
