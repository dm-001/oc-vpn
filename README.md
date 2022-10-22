# OpenConnect VPN Server with SAML 2.0 SSO

**Cisco AnyConnect compatible VPN server container, with SAML 2.0 single sign-in.**

A customised and updated fork of [docker-oc-saml](https://github.com/MorganOnBass/docker-ocserv-saml) from MorganOnBass with the following changes/updates:
1. Container rebased to Alpine 3.16
2. Core build dependencies updated.
3. Automated certificate management (letsencrypt/certbot) implemented within container
4. OpenConnect configuration edited to enforce perfect forward secrecy, drop support for outdated DTLS protocols, and present AnyConnect-compliant profiles to clients.
5. Basic geoblocking of VPN connections using the [GeoJS](https://www.geojs.io/) country-level Geolocation lookup API
