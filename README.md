# OpenConnect VPN Server with SAML 2.0 SSO

**Cisco AnyConnect compatible VPN server, integrated with SAML 2.0 single sign-in.**

This container is a customised and updated fork of [docker-oc-saml](https://github.com/MorganOnBass/docker-ocserv-saml) from MorganOnBass with the following changes/updates:

1. Container rebased to Alpine 3.16
2. Core build dependencies updated.
3. Automated certificate management (letsencrypt/certbot) implemented within container
4. OpenConnect configuration edited to enforce perfect forward secrecy, drop support for outdated DTLS protocols, and present AnyConnect-compliant profiles to clients.
5. Basic geoblocking of VPN connections using the [GeoJS](https://www.geojs.io/) country-level Geolocation lookup API


Planned changes not yet implemented:
- Remove LISTEN_PORT variable and implementation - user can simply map a different port with docker
- Remodel Dockerfile to use builder image for ocserv compilation (if possible)
- Implement optional port restrictions within VPN routes


## Environment Variables

HOSTNAME: "vpn.example.com"
: Hostname/FQDN of VPN server 
- VPN_NAME: "Example VPN"
: Friendly name of VPN server (fo
- GEOBLOCK: "true"
: True/False - Enable or disable 
- ALLOW_COUNTRY_CODES: "US FR DE 
: List of space-seperated ISO 316
- LISTEN_PORT: "443"
: Port for VPN advertisement and 
- TLS_EMAIL: "email@example.com"
: Email to register letsencrypt c
- TLS_TEST: "false"
: True/False - Use LetsEncrypt AC
- TUNNEL_MODE: "split-include"
: split-include/all - full of spl
- TUNNEL_ROUTES: "10.1.2.128/25, 
: VPN routes if running in split 
- DNS_SERVERS: "10.1.2.254"
: DNS servers to use via VPN
- DEFAULT_DOMAIN: "internal.examp
: Default VPN domain
- CLIENTNET: "192.168.248.0"
: Virtual network for VPN clients
- CLIENTNETMASK: "255.255.255.128
: VPN virtual network subnet mask



## Example implementation with docker compose:

```
version: "3.5"

services:

  oc-vpn:

    # Build direct from github repo
    build https://github.com/dm-001/oc-vpn.git

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
      LISTEN_PORT: "443"
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
