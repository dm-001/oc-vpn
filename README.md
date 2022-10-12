# ocserv-saml
OpenConnect VPN container with SAML 2.0 auth integration

An updated implementation of https://github.com/MorganOnBass/docker-ocserv-saml

### The following changes have been implemented and tested:

Dockerfile:
1. Rebase to Alpine 3.16 (container base OS)
2. Move to python 3 (dependency for xml sec and lasso)
3. Move to xmlsec1-1.2.34 (XML signing, encrypting etc)
4. Move to lasso 2.8.0 (SAML 2.0 implementation library)
5. Remove pip (not required)
6. Add protobuf-c-dev to build dependencies list (alpine 3.16 packaging change?)

Docker entrypoint script:
1. Implement VPN_PROFILE env variable to set AnyConnect-compatible VPN profile XML filename and location 

OpenConnect default configuration changes:
1. Turn cisco-client-compat flag off by default - remove compatability with outdated VPN clients, in exchange for better crytography
2. Require perfect forward secrecy compliance in cipher suites by default - removes compatability with older clients in exchange for better ciphers


### The following changes are planned but not implemented:

Docker entrypoint script:
- Move letsencrypt automated certificate management to container entrypoint script
- Implement GEOBLOCK_ALLOW_ONLY env variable to set geojs.io-based IP geoblocking via environment variable
- Implement OpenConnect-based port restrictions for connected users via env variable (i.e. restrict VPN clients to only using port 3389 etc)
- Implement OpenConnect-based route restrictions for connected users via SAML group attributes (i.e. restrict VPN clients to only using specific routes based on group memberships provided by SAML assertion etc)

Dockerfile:
- Lower container size and footprint by using builder images to compile requirements, and only copy the compiled binaries and needed libraries to the live container
