#!/bin/bash
#Test cases:

echo ''
echo '### TEST: Offer ###'

# -> create user
echo 'POST /users'
curl -s -H "Content-Type: application/json" -X POST -d '{"Name": "jery", "PreferredName": "jery", "Mail": "jery@gmx.de", "Password": "yoloyoloyoloyolo!12"}' http://localhost:3001/users

# -> login
echo 'POST /auth'
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"Mail":"jery@gmx.de", "Password":"yoloyoloyoloyolo!12"}' http://localhost:3001/auth)
TOKEN=$(echo $TOKEN | cut -d'"' -f 4)
#echo "$TOKEN"

# -> post offer
echo 'POST /offers'
OFFER=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -X POST -d '{"Location":"Berlin", "Name":"Test Name", "ValidityPeriod":2000000000}' http://localhost:3001/offers)
echo "$OFFER"