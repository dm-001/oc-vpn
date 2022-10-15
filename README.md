# ocserv-saml
### OpenConnect VPN container with SAML 2.0 auth integration

Forked from [MorganOnBass docker-ocserv-saml](https://github.com/MorganOnBass/docker-ocserv-saml) 

Notable build changes:
- Rebased to Alpine Linux 3.16
- Updated Python to Python 3
- Updated xmlsec1 to xmlsec1 1.2.34 
- Updated lasso to lasso 2.8.0

Notable OpenConnect configuration changes:
- OpenConnect now enforces perfect forward secrecy by default
- Legacy DTLS negotiation disabled by default
- AnyConnect profile (profile.xml) enabled by default, allowing additional connection settings and restrictions for clients using Cisco AnyConnect

Docker configuration changes:
- SSL certificate handling now carried out automatically. If no certificates are present the container will request certificates from LetsEncrypt and set up automatic renewals.
- TLS_EMAIL environment variable introduced to register certificate against
- TLS_TEST environment variable introduced to allow use of LetsEncrypt's test endpoint
- VPN_NAME environment variable introduced to define VPN friendly name in profile.xml


Usage:

Clone this repository, and build with Docker.
Once the container image has been built with docker follow the steps below to launch a OpenConnect VPN Server with SAML 2.0 authentication:

1. Ensure your server can be reached from the internet on the following ports:
- 80 tcp: ACME certificate challenges only, not used by VPN
- 443 udp: SSL VPN traffic
- 443 tcp: VPN Server advertisement and profile, failover SSL VPN traffic if client cannot use UDP

2. Ensure the server's hostname resolves correctly via DNS records

3. Set up your SAML IDP and retreive the certificate and metadata XML file which the IDP provides

4. If you have an AnyConnect profile you wish to use, retreive the profile xml file (a default will be created if not).

5. Create a directory to house your VPN container info (e.g. /opt/vpn)

6. Create a subdirectory called 'config' to house the configuration files (e.g. /opt/vpn/config)

7. Place the IPD certificate and metadata files in the config subdirectory as idp-cert.pem and idp-metadata.xml, if you have a preferred AnyConnect profile place it in the same directory as profile.xml

8. Create a docker-compose.yml file with your preferred settings



    version: "3"
    
    services:
    
      oc-vpn:
        # Point to the folder this repo was cloned to
        build:
          context: /opt/ocserv-saml
    
        # Map host ports to container ports  
        ports:
          - "80:80/tcp"
          - "443:443/tcp"
          - "443:443/udp"
    
        # Set variables  
        environment:
          HOSTNAME: "vpn.example.com"
          VPN_NAME: "Example VPN"
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
