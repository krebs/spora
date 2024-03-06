# spora network

this is a flake which exports some functions to join the spora network

## join

if you don't use clan or don't want this network as your primary. you can import our zerotier module:

```nix
{inputs, ...}: {
  imports = [
    inputs.spora.nixosModules.mycelium
    inputs.spora.nixosModules.hosts
  ];
}
```

## Adding host to network
First `git clone` this repository. Then
for your host to be accepted into the network the id needs to be whitelisted.
So add your host file to hosts:

if your client doesn't have any public reachable endpoints, just run:

```
mycelium inspect "$myPubkey" --json > hosts/$(hostname).json
```

if your machine has public endpoints add them like this:

```
mycelium inspect "$myPubkey" --json |
  jq -r '. * { "public_endpoints": [
    "tcp://95.217.192.59:9651",
    "quic://96.217.192.59:9651",
    "tcp://[2a01:4f9:4a:4f1a::2]:9651",
    "quic://[2a01:4f9:4a:4f1a::2]:9651"
  ] }' > hosts/$(hostname).json
```
