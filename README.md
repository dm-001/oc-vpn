# OpenConnect VPN Server with SAML 2.0 SSO

A customised and updated fork of [docker-oc-saml](https://github.com/MorganOnBass/docker-ocserv-saml) from MorganOnBass with the following changes/updates:
1. Container rebased to Alpine 3.16
2. Core build dependencies updated.
3. Automated certificate management (letsencrypt/certbot) implemented within container
4. OpenConnect configuration edited to enforce perfect forward secrecy, drop support for outdated DTLS protocols, and present AnyConnect-compliant profiles to clients.
5. Basic geoblocking of VPN connections using the [GeoJS](https://www.geojs.io/) country-level Geolocation lookup API

## Example implementation with docker compose:

```
version: "3.5"
services:
  oc-vpn:
    # Build the container - tell docker to build based on the Dockerfile
    build: 
      context: ./oc-vpn/Dockerfile
    
    # Map host ports to container ports  
    ports:
      - "80:80/tcp"
      - "443:443/tcp"
      - "443:443/udp"
    # Set variables  
    environment:
      HOSTNAME: "vpn.example.com"
      VPN_NAME: "Example VPN"
      GEOBLOCK: "true"
      ALLOW_COUNTRY_CODES: "US FR DE GB CA AU NZ"
      TLS_EMAIL: "email@example.com"
      TLS_TEST: "false"
      TUNNEL_MODE: "split-include"
      TUNNEL_ROUTES: "10.1.2.128/25, 192.168.1.0/24"
      DNS_SERVERS: "10.1.2.254"
      DEFAULT_DOMAIN: "internal.example.com"
      CLIENTNET: "192.168.248.0"
      CLIENTNETMASK: "255.255.255.128"
    
    # Mount the config folder in the container
    volumes:
      - "./config:/config"
      
    # Give container the right to bind to low ports (80,443)
    cap_add:
      - NET_ADMIN
    
    # Required privilege for VPN networking
    privileged: true
    
    # Restart the container if it stops
    restart: unless-stopped
```


## Pre-requisites:

1. Server with publicly routable hostname
2. Docker and docker-compose installed
3. SAML 2.0 IDP 
   - IDP cert mapped to /config/idp-cert.pem in container
   - IDP metadata doc mapped to /config/idp-metadata.xml in container
