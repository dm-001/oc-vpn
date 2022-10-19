# OpenConnect VPN Server with SAML 2.0 SSO

**Cisco AnyConnect compatible VPN server container, with SAML 2.0 single sign-in.**

This container is a customised and updated fork of [docker-oc-saml](https://github.com/MorganOnBass/docker-ocserv-saml) from MorganOnBass with the following changes/updates:
1. Container rebased to Alpine 3.16
2. Core build dependencies updated.
3. Automated certificate management (letsencrypt/certbot) implemented within container
4. OpenConnect configuration edited to enforce perfect forward secrecy, drop support for outdated DTLS protocols, and present AnyConnect-compliant profiles to clients.
5. Basic geoblocking of VPN connections using the [GeoJS](https://www.geojs.io/) country-level Geolocation lookup API


Planned changes not yet implemented:
- Remodel Dockerfile to use builder image for ocserv compilation (if possible)
- Implement optional port restrictions within VPN routes


## Environment Variables


| Environment Var | Example Value | Definition |
|--|--|--|
| HOSTNAME | "vpn.example.com" | Hostname/FQDN of VPN server |
| VPN_NAME | "My Example VPN" | Friendly name of VPN server |
| GEOBLOCK | "true" | Enable/disable geoblocking function. Accepted values: true, false |
| ALLOW_COUNTRY_CODES | "US FR DE GB CA AU NZ" | List of space-seperated ISO 3166 two-letter country codes for geoblocking whitelist |
| TLS_EMAIL | "email@example.com" | Email to register letsencrypt certificates against |
| TLS_TEST | "false" | Use letsencrypt ACME test endpoint instead of production endpoint. Accepted values: true, false |
| TUNNEL_MODE | "split-include" | Full of split tunnel VPN mode. Accepted values: full, split-include |
| TUNNEL_ROUTES | "10.1.2.128/25, 192.168.1.0/24" | VPN routes if running in split tunnel mode. CIDR, comma separated |
| DNS_SERVERS | "10.1.2.254" | DNS servers to use via VPN |
| DEFAULT_DOMAINS | "internal.example.com" | Default VPN domain |
| CLIENTNET | "192.168.248.0" | Virtual network used for VPN clients |
| CLIENTNETMASK | "255.255.255.128" | VPN virtual network subnet mask | 



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

## Step by step guide

Pre-requisites:
1. Server with publicly routable hostname
2. Docker and docker-compose installed
3. SAML 2.0 IDP


### Step 0
Download or clone this repository

### Step 1
Create a docker-compose.yml file on your server with your preferred settings, based off the example above. The server must be reachable via the hostname given, using the ports specified in the docker-compose port mappings (80, 443 by default).

### Step 2
Configure your SAML IDP to handle authentication from the VPN server. Depending on the ID provider you may require the values below (substitute your VPN server hostname):
- Assertion Consumer Service URL: https://vpn.example.com/+CSCOE+/saml/sp/acs
- Login URL: https://vpn.example.com/+CSCOE+/saml/sp/login
- Name ID Format: unspecified

### Step 3
Create a folder called 'config' in the location of your docker-compose.yml file. Retreive the metadata XML file and certificate from your SAML IDP and plave them in the 'config' folder with the following names:
- idp-metadata.xml
- idp-cert.pem

### Step 4 (optional)
If you want to supply your own certificates:
Create a 'certs' subdirectory within the config folder and place your certificate and key within, named server-cert.pem and server-key.pem.
If you do not want to supply your own certificates simply skip this step and the container will request and configure the correct certificates automatically from letsencrypt (via HTTP ACME challenge on port 80).


**Setup complete.** 
You can now launch your OpenConnect VPN server with `docker-compose up -d`. After completing it's initial setup the VPN server will listen on the specified ports (443 tcp and 443 udp by default) for incoming connections from clients.
You can view the VPN server logs using `docker-compose logs` to review VPN status and events.

