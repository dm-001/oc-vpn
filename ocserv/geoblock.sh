#!/bin/bash

# User connect script. Print details to log, and run geoblock routine.

echo "$(date) [info] User ${USERNAME} - ${REASON} received from ${IP_REAL}. Checking Geolocation..."

# Make sure Ocserv passes IP_REAL
if [ "x${IP_REAL}" = "x" ]; then
  echo "$(date) [err] No IP info passed from ocserv. Ending connection attempt." 
  exit 1
fi

# Get 2-letter code using geojs.io plaintext geoip country endpoint
COUNTRY_CODE=$(wget -q -O - https://get.geojs.io/v1/ip/country/$IP_REAL)

# Make sure we returned something for COUNTRY_CODE - fail closed if we didn't
if [ "x${COUNTRY_CODE}" = "x" ]; then
  echo "$(date) [err] No IP geolocation found or error looking up IP geolocation. Ending connection attempt." 
  exit 1
fi

# What happens if it returns 'nil'? i.e. address is in private range - fail open
if [ "${COUNTRY_CODE}" = "nil" ]; then
  echo "$(date) [info] User IP is internal RFC 1819 address - allowed"
  echo "$(date) [info] User ${USERNAME} Connected - Server: ${IP_REAL_LOCAL} VPN IP: ${IP_REMOTE}  Remote IP: ${IP_REAL} Device:${DEVICE}"
  exit 0
fi

# Check if returned code is in the allow list
for c in $ALLOW_COUNTRY_CODES; do
  if [ "${c}" = "${COUNTRY_CODE}" ]; then
    echo "$(date) [info] ser connected from ${COUNTRY_CODE} - allowed"
    echo "$(date) [info] User ${USERNAME} Connected - Server: ${IP_REAL_LOCAL} VPN IP: ${IP_REMOTE}  Remote IP: ${IP_REAL} Device:${DEVICE}"
    exit 0
  fi
done

# If we made it here, then COUNTRY_CODE was not found in ALLOW_COUNTRY_CODES
echo "$(date) [info] User geoblocked - disconnecting. Country code: ${COUNTRY_CODE} not in allow list (${ALLOW_COUNTRY_CODES})"
exit 1
