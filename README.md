# CaTUstrophy backend [![Build Status](https://travis-ci.org/caTUstrophy/backend.svg?branch=master)](https://travis-ci.org/caTUstrophy/backend)

Backend part for our catastrophe aid tool. Written in Go.

This project provides the backend for a platform connecting people in a region suffering from a catastrophe, e.g. a natural disaster. The frontend part can be found [here](https://github.com/caTUstrophy/frontend). We develop this platform within the scope of one of our university courses, the [Programmierpraktikum: Soziale Netzwerke](https://www.cit.tu-berlin.de/menue/teaching/sommersemester_16/programmierpraktikum_soziale_netzwerke_ppsn/).


## Get it running

**1)** You have to have a working [Go installation](https://golang.org/doc/install) on your system. Preferably via your system's package manager.
Also, you need to have a working and running PostgreSQL + PostGIS instance. Therefore, make sure you have PostgreSQL installed and configured correctly and additionally install the PostGIS extension which enables spatial and geographic objects and functions in PostgreSQL.

**2)** Initially run
```bash
$ go get github.com/caTUstrophy/backend
```
which downloads the backend part of the project into your GOPATH.

**3)** Navigate to the project in your file system via
```bash
$ cd ${GOPATH}/src/github.com/caTUstrophy/backend
```
and execute
```bash
$ go get ./...
```
to fetch all dependencies of this project.

**4)** Create an `.env` file suited to your deployment. For this, copy the provided `.env.example` to `.env` and edit it to your needs. **Choose strong secret keys!**

**5)** Create a Postgres database user, e.g. `catustrophy`, and set a password for that user. Set up a Postgres database, e.g. `catustrophy`, too. Then add these information to your just created environment `.env` file. As above, have a look at the `.env.example` for a description of which values you have to set.

**6)** Add PostGIS to your database. For that, become the `postgres` user of your system and execute following commands, assuming you previously created the `catustrophy` database:
```bash
user@system $ sudo -i -u postgres
postgres@system $ psql
psql (9.5.3)
Type "help" for help.

postgres=# \c catustrophy 
You are now connected to database "catustrophy" as user "postgres".
catustrophy=# CREATE EXTENSION postgis;
catustrophy=# CREATE EXTENSION postgis_topology;
catustrophy=# CREATE EXTENSION fuzzystrmatch;
catustrophy=# CREATE EXTENSION postgis_tiger_geocoder;
catustrophy=# \q
postgres@system $ exit
```

**7)** Build the project via
```bash
$ go build
```

**8a)** If you are running the project the first time or after you dropped the database to start fresh, start the backend via
```bash
$ ./backend --init
```
This will create the tables and fill in some default needed content.

**8b)** Alternatively - and in the most common case - start it with
```bash
$ ./backend
```

Afterwards, the backend is reachable at `http://localhost:3001`.


## Available admin user

To be able to use this backend during development we provide a default admin account. When you initially run `./backend --init`, an admin user with the following credentials will be created:

**Mail:** admin@example.org  
**Password:** CaTUstrophyAdmin123$

**Please make sure you don't create this default admin user in production!**


## Matching Algorithm

We implemented an algorithm that helps to recommend matches. It's aim is to find pairs of offers and requests that share similar content. If you are interested, you can read about our basic thoughts [here](https://www.overleaf.com/read/tgkyxfzcptgf). The document is not a complete report of what we have actually done, you will have to look this up in `matching-algorithm.go`, but it might help you to get into the idea or inspire you for your own project.


## API documentation

Four roles are present in this model:
* unregistered user **(U)**: not yet present in our system
* not-logged-in user **(N)**: registered, but not authorized user
* logged-in user **(L)**: registered and authorized user
* logged-in and concerned user **(C)**: user is involved in e.g. a matching
* admin **(A)**: registered, authorized and privileged user for a specified region
* System admin **(S)**: registered, authorized and privileged user for the whole system. Like root

The coloumn `Role` denotes the minimum needed privilege to use the endpoint.

| Functionality                                                   | Role | HTTP verb | Endpoint                     | API version | Done? |
| --------------------------------------------------------------- | ---- | --------- | ---------------------------- | ----------- | ----- |
| [Login](#login)                                                 | N    | POST      | /auth                        | MVP         | ✔    |
| [Renew auth token](#renew-auth-token)                           | L    | GET       | /auth                        | MVP         | ✔    |
| [Logout](#logout)                                               | L    | DELETE    | /auth                        | MVP         | ✔    |
| [Create user](#create-user-registration)                        | U    | POST      | /users                       | MVP         | ✔    |
| [List users](#list-all-users)                                   | A    | GET       | /users                       | 3.0         | ✔    |
| [Get user `userID`](#get-user-with-id-userid)                   | A    | GET       | /users/:userID               | 3.0         | ✔    |
| [Update user `userID`](#update-user-with-id-userid)             | A    | PUT       | /users/:userID               | 3.0         | ✔    |
| [List tags](#list-all-tags)                                     | L    | GET       | /tags                        | 4.0         | ✔    |
| [Create offer](#create-offer)                                   | L    | POST      | /offers                      | MVP         | ✔    |
| [Get offer `offerID`](#get-offer-with-offerid)                  | C    | GET       | /offers/:offerID             | 2.0         | ✔    |
| [Update offer `offerID`](#update-offer-with-offerid)            | C    | PUT       | /offers/:offerID             | 3.0         | ✔    |
| [Create request](#create-request)                               | L    | POST      | /requests                    | MVP         | ✔    |
| [Get request `requestID`](#get-request-with-requestid)          | C    | GET       | /requests/:requestID         | 2.0         | ✔    |
| [Update request `requestID`](#update-request-with-requestid)    | C    | PUT       | /requests/:requestID         | 3.0         | ✔    |
| [Create matching](#create-matching)                             | A    | POST      | /matchings                   | MVP         | ✔    |
| [Get matching `matchingID`](#get-matching-with-matchingid)      | C    | GET       | /matchings/:matchingID       | MVP         | ✔    |
| [Update matching `matchingID`](#update-matching-with-matchingid)| C    | PUT       | /matchings/:matchingID       | 3.0         | ✔    |
| [Create a region](#create-region)                               | L    | POST      | /regions                     | 2.0         | ✔    |
| [List regions](#list-regions)                                   | U    | GET       | /regions                     | 2.0         | ✔    |
| [Get region `regionID`](#get-region-regionid)                   | U    | GET       | /regions/:regionID           | 2.0         | ✔    |
| [Update region `regionID`](#update-region-with-regionid)        | A    | PUT       | /regions/:regionID           | 3.0         | ✔    |
| [List offers in region `regionID`](#list-offers-in-region-with-regionid) | A | GET | /regions/:regionID/offers    | 2.0         | ✔    |
| [List requests in region `regionID`](#list-requests-in-region-with-regionid) | A | GET | /regions/:regionID/requests | 2.0      | ✔    |
| [List matchings in region `regionID`](#list-matchings-in-region-with-regionid) | A | GET | /regions/:regionID/matchings | 2.0   | ✔    |
| [List recommendations for region `regionID`](#list-recommendations-for-region) | A | GET | /regions/:regionID/recommendations | 4.0   | ✔    |
| [List recommendations for offer](#list-recommendations-for-offer) | A | GET | /regions/:ID/offers/:ID/recommendations | 4.0   | ✔    |
| [List recommendations for request](#list-recommendations-for-request) | A | GET | /regions/:ID/requests/:ID/recommendations | 4.0   | ✔    |
| [Promote user to admin for region `regionID`](#promote-user-to-admin-in-region-with-regionid) | A | POST | /regions/:regionID/admins | 3.0 | ✔ |
| [List admins for region `regionID`](#list-admins-in-region-with-regionid) | A | GET | /regions/:regionID/admins   | 3.0         | ✔    |
| [Promote user to system admin](#promote-user-to-system-admin) | S | POST | /system/admins | 3.0 | ✔ |
| [List admins for system](#list-system-admins) | A | GET | /system/admins   | 3.0         | ✔    |
| [Own profile](#own-profile)                                     | L    | GET       | /me                          | 2.0         | ✔    |
| [Update own profile](#update-own-profile)                       | L    | PUT       | /me                          | 3.0         | ✔    |
| [List own offers](#list-own-offers)                             | L    | GET       | /me/offers                   | 2.0         | ✔    |
| [List own requests](#list-own-requests)                         | L    | GET       | /me/requests                 | 2.0         | ✔    |
| [List own matchings](#list-own-matchings)                       | L    | GET       | /me/matchings                | 3.0         | ✔    |
| [List unread notifications](#list-unread-notifications)         | L    | GET       | /notifications               | 3.0         | ✔    |
| [Update notification `notificationID`](#update-notification-with-notificationid) | C | PUT | /notifications/:notificationID | 3.0 | ✔  |


### What is inside a JWT?

Inside a JWT issued by this backend, the following fields are present:

```
{
    "iss": "ralollol@bernd.orgorg",
    "iat": "2016-06-09T21:39:12+02:00",
    "nbf": "2016-06-09T21:38:12+02:00",
    "exp": "2016-06-09T22:09:12+02:00"
}
```

**iss (issuer):** Mail of user this token is issued to.  
**iat (issued at):** Time and date when token was issued. [RFC3339 date](https://www.ietf.org/rfc/rfc3339.txt)  
**nbf (not before):** Token is to be discarded when used before this time and date. [RFC3339 date](https://www.ietf.org/rfc/rfc3339.txt)  
**exp (expires):** Token is to be discarded when used after this time and date. [RFC3339 date](https://www.ietf.org/rfc/rfc3339.txt)

Please note that further identification fields may be added in the future.


### General request information

#### Fail responses

If a request was not okay, we will always send one of the following responses:

```
400 Bad Request

{
    "<FIELD NAME>": "<ERROR MESSAGE FOR THIS FIELD>"
}
```

```
401 Unauthorized
WWW-Authenticate: Bearer realm="CaTUstrophy", error="invalid_token", error_description="<ERROR DESCRIPTION>"
```

```
404 Not Found
{
	"<FIELDNAME OR ERROR>": "<MORE INFORMATION ON WHAT WAS NOT FOUND>"
}
```


### Detailed request information

#### Login

**Request:**

```
POST /auth

{
    "Mail": required, string/email
    "Password": required, string
}
```

**Response:**

```
200 OK

{
    "AccessToken": string/jwt
}
```


#### Renew auth token

**Request:**

```
GET /auth
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

```
200 OK

{
    "AccessToken": string/jwt
}
```

#### Logout

**Request:**

```
DELETE /auth
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

```
200 OK

{
    "ID": UUID v4
}
```

#### Create user (registration)

**Request:**

```
POST /users

{
    "Name": required, string
    "PreferredName": optional, string
    "Mail": required, string/email
    "PhoneNumbers": required, array of strings
    "Password": required, string
}
```

***Example:***

Note that `PhoneNumbers` can contain no, one or multiple phone numbers in string representation, but cannot be missing.

```
POST /users

{
    "Name": "Alexandra Maria Namia",
    "PreferredName": "alex",
    "Mail": "alexandra.m.namia@example.com",
    "PhoneNumbers": [
        "012012312373",
        "07791184228843",
        "+9999230203920"
    ],
    "Password": "WhyNotSafe1337Worlds?"
}
```

**Response:**

[Single complete user object](#single-user-complete)


#### List all users

```
GET /users
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

```

**Response:**

[List of complete user objects](#list-users-complete)


#### Get user with ID `userID`

```
GET /users/:userID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[Single complete user object](#single-user-complete)


#### Update user with ID `userID`

```
PUT /users/:userID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
	"Name": optional, string
    "PreferredName": optional, string
    "Mail": optional, string/email
    "PhoneNumbers": optional, array of strings
    "Password": optional, string
    "Groups": optinal, [
        {
            "ID": required, UUID v4
        },
        ...
    ]
}
```

**Response:**

[Single complete user object](#single-user-complete)


#### List all tags

```
GET /tags
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[Tag list](#tag-list)


#### Create offer

**Request:**

```
POST /offers
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Name": required, string,
    "Tags": optional, string array,
    "Description": optional, string,
    "ValidityPeriod": required, RFC3339 date,
    "Location": {
        "lng": float64,
        "lat": float64
    },
    "Radius": required, float64, [km]
}
```

***Example:***

```
POST /offers
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Name": "hugs",
    "Tags": ["tag", "another tag"],
    "ValidityPeriod": "2017-11-01T22:08:41+00:00",
    "Location": {
        "lng": 12.3,
        "lat": 0.0
    }
    "Radius": 10
}
```

**Response:**

[Offer object](#offer-object)


#### Get offer with `offerID`

**Request:**

```
GET /offers/:offerID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[Offer object](#offer-object)


#### Update offer with `offerID`

**Request:**

```
PUT /offers/:offerID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
}
```

**Response:**

[Offer object](#offer-object)


#### Create request

**Request:**

```
POST /requests
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Name": required, string,
    "Tags": optional, string array,
    "ValidityPeriod": required, RFC3339 date,
    "Location": {
        "lng": required, float64,
        "lat": required, float64
    },
    "Radius": required, float64, [km]
}
```

**Response:**

[Request object](#request-object)


#### Get request with `requestID`

**Request:**

```
GET /requests/:requestID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[Request object](#request-object)


#### Update request with `requestID`

**Request:**

```
PUT /requests/:requestID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
}
```

**Response:**

[Request object](#request-object)


#### Create matching

**Request:**

```
POST /matchings
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Region": required, UUID v4,
    "Request": required, UUID v4,
    "Offer": required, UUID v4
}
```

**Response:**

[Matching object](#matching-object)


#### Get matching with `matchingID`

**Request:**

```
GET /matchings/:matchingID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[Matching object](#matching-object)


#### Update matching with `matchingID`

**Request:**

```
PUT /matchings/:matchingID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Invalid": true
}
```

**Response:**

[Matching object](#matching-object)


#### Create region

**Request:**

```
POST /regions
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Name": required, string,
    "Description": required, string,
    "Boundaries": {
        "Points": [
            {
                "lat": required, float64,
                "lng": required, float64
            },
            ...
        ]
    }
}
```

**Response:**

[Region object](#region-object)


#### List regions

**Request:**

```
GET /regions
```

**Response:**

[Region list](#region-list)


#### Get region `regionID`

**Request:**

```
GET /regions/:regionID
```

**Response:**

[Region object](#region-object)


#### Update region with `regionID`

```
PUT /regions/:regionID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Name": required, string,
    "Description": required, string,
    "Boundaries": {
        "Points": [
            {
                "lat": required, float64,
                "lng": required, float64
            },
            ...
        ]
    }
}
```

**Response:**

[Region object](#region-object)


#### List offers in region with `regionID`

**Request:**

```
GET /regions/:regionID/offers
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[Offer list](#offer-list)


#### List requests in region with `regionID`

**Request:**

```
GET region/:regionID/requests/
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[Request list](#request-list)


#### List matchings in region with `regionID`

**Request:**

```
GET /regions/:regionID/matchings
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[Matching list](#matching-list)

#### List recommendations for region

**Request:**
```
GET /regions/:regionID/recommendations
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**
[Match partner list](#match-partner-list)

#### List recommendations for offer

**Request:**
```
GET /regions/:ID/offers/:ID/recommendations
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**
[Request list with matching score](#request-with-matching-score)

#### List recommendations for request

**Request:**
```
GET /regions/:ID/requests/:ID/recommendations
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**
[Offer list with matching score](#offers-with-matching-score)

#### Promote user to admin in region with `regionID`

**Request:**

```
POST /regions/:regionID/admins
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Mail": required, string
}
```

**Response:**

[User without groups](#user-without-groups)


#### List admins in region with `regionID`

**Request**

```
GET /regions/:regionID/admins
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[List of users without their groups](#list-of-users-without-groups)

#### Promote user to system admin

**Request:**

```
POST /system/admins
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Mail": required, string
}
```

**Response:**

[User without groups](#user-without-groups)


#### List system admins

**Request**

```
GET /system/admins
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[List of users without their groups](#list-of-users-without-groups)
#### Own profile

**Request:**

```
GET /me
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[User object complete](#single-user-complete)


#### Update own profile

**Request:**

```
PUT /me
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
	"Name": optional, string,
    "PreferredName": optional, string,
    "Mail": optional, string/email,
    "PhoneNumbers": optional, array of strings,
    "Password": optional, string
}
```

**Response:**

[User object complete](#single-user-complete)


#### List own offers

**Request:**

```
GET /me/offers
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[List of offers](#offer-list)


#### List own requests

**Request:**

```
GET /me/requests
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[List of requests](#request-list)


#### List own matchings

**Request:**

```
GET /me/matchings
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[List of matchings](#matching-list)


#### List unread notifications

**Request:**

```
GET /notifications
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>
```

**Response:**

[List of notifications](#notification-list)

or in case that notifications for matchings are included:

[List of matching notifications](#notification-list-for-matching-notifications)


#### Update notification with `notificationID`

**Request:**

```
PUT /notifications/:notificationID
Authorization: Bearer <USER'S ACCESS TOKEN AS JWT>

{
    "Read": true
}
```

**Response:**

[Single notification](#notification-object)

or in case that this specific notification is meant for a matching:

[Single matching notification](#notification-object-for-matching-notification)



### Responses

#### Single user complete

```
{
	"Groups": [
		{
			"AccessRight": "string",
			"Description": "string",
			"ID": "UUID v4",
			"Region": {
				"Description": "string",
				"ID": "UUID v4",
				"Name": "string"
			}
		}
	],
	"ID": "UUID v4",
	"Mail": "string",
	"MailVerified": "bool",
	"Name": "string",
	"PhoneNumbers": "[string, ...]",
	"PreferredName": "string"
}
```

#### List users complete

```
[
	{
		"Groups": [
			{
				"AccessRight": "string",
				"Description": "string",
				"ID": "UUID v4",
				"Region": {
					"Description": "string",
					"ID": "UUID v4",
					"Name": "string"
				}
			}
		],
		"ID": "UUID v4",
		"Mail": "string",
		"MailVerified": "bool",
		"Name": "string",
		"PhoneNumbers": "[string, ...]",
		"PreferredName": "string"
	}
]
```

#### User without group

```
{
	"ID": "UUID v4",
	"Mail": "string",
	"MailVerified": "bool",
	"Name": "string",
	"PhoneNumbers": "[string, ...]"
}
```

#### List of users without group

```
[
	{
		"ID": "UUID v4",
		"Mail": "string",
		"MailVerified": "bool",
		"Name": "string",
		"PhoneNumbers": "[string, ...]"
	}
]
```

#### Tag list

```
[
	{
		"Name": "string"
	}
]
```

#### Offer object

```
{
	"Description": "string",
	"Expired": "bool",
	"ID": "UUID v4",
	"Location": {
		"lat": "float64",
		"lng": "float64"
	},
	"Matched": "bool",
	"MatchingScore": "float64",
	"Name": "string",
	"Radius": "float64",
	"Recommended": "bool",
	"Tags": [
		{
			"Name": "string"
		}
	],
	"ValidityPeriod": "RFC3339 date"
}
```

#### Offer list

```
[
	{
		"Description": "string",
		"Expired": "bool",
		"ID": "UUID v4",
		"Location": {
			"lat": "float64",
			"lng": "float64"
		},
		"Matched": "bool",
		"MatchingScore": "float64",
		"Name": "string",
		"Radius": "float64",
		"Recommended": "bool",
		"Tags": [
			{
				"Name": "string"
			}
		],
		"ValidityPeriod": "RFC3339 date"
	}
]
```

#### Request object

```
{
	"Description": "string",
	"Expired": "bool",
	"ID": "UUID v4",
	"Location": {
		"lat": "float64",
		"lng": "float64"
	},
	"Matched": "bool",
	"MatchingScore": "float64",
	"Name": "string",
	"Radius": "float64",
	"Recommended": "bool",
	"Tags": [
		{
			"Name": "string"
		}
	],
	"ValidityPeriod": "RFC3339 date"
}
```

#### Request list

```
[
	{
		"Description": "string",
		"Expired": "bool",
		"ID": "UUID v4",
		"Location": {
			"lat": "float64",
			"lng": "float64"
		},
		"Matched": "bool",
		"MatchingScore": "float64",
		"Name": "string",
		"Radius": "float64",
		"Recommended": "bool",
		"Tags": [
			{
				"Name": "string"
			}
		],
		"ValidityPeriod": "RFC3339 date"
	}
]
```

#### Matching object

```
{
	"ID": "UUID v4",
	"Invalid": "bool",
	"Offer": {
		"Description": "string",
		"Expired": "bool",
		"ID": "UUID v4",
		"Location": {
			"lat": "float64",
			"lng": "float64"
		},
		"Matched": "bool",
		"Name": "string",
		"Radius": "float64",
		"Tags": [
			null
		],
		"User": {
			"ID": "UUID v4",
			"Mail": "string",
			"Name": "string",
			"PhoneNumbers": "[string, ...]"
		},
		"ValidityPeriod": "RFC3339 date"
	},
	"RegionId": "UUID v4",
	"Request": {
		"Description": "string",
		"Expired": "bool",
		"ID": "UUID v4",
		"Location": {
			"lat": "float64",
			"lng": "float64"
		},
		"Matched": "bool",
		"Name": "string",
		"Radius": "float64",
		"Tags": [
			null
		],
		"User": {
			"ID": "UUID v4",
			"Mail": "string",
			"Name": "string",
			"PhoneNumbers": "[string, ...]"
		},
		"ValidityPeriod": "RFC3339 date"
	}
}
```

#### Matching list

```
[
	{
		"ID": "UUID v4",
		"Invalid": "bool",
		"Offer": {
			"Description": "string",
			"Expired": "bool",
			"ID": "UUID v4",
			"Location": {
				"lat": "float64",
				"lng": "float64"
			},
			"Matched": "bool",
			"Name": "string",
			"Radius": "float64",
			"Tags": [
				null
			],
			"User": {
				"ID": "UUID v4",
				"Mail": "string",
				"Name": "string",
				"PhoneNumbers": "[string, ...]"
			},
			"ValidityPeriod": "RFC3339 date"
		},
		"RegionId": "UUID v4",
		"Request": {
			"Description": "string",
			"Expired": "bool",
			"ID": "UUID v4",
			"Location": {
				"lat": "float64",
				"lng": "float64"
			},
			"Matched": "bool",
			"Name": "string",
			"Radius": "float64",
			"Tags": [
				null
			],
			"User": {
				"ID": "UUID v4",
				"Mail": "string",
				"Name": "string",
				"PhoneNumbers": "[string, ...]"
			},
			"ValidityPeriod": "RFC3339 date"
		}
	}
]
```

#### Region object

```
{
	"Boundaries": {
		"Points": [
			{
				"lat": "float64",
				"lng": "float64"
			}
		]
	},
	"Description": "string",
	"ID": "UUID v4",
	"Name": "string"
}
```

#### Region list

```
[
	{
		"Boundaries": {
			"Points": [
				{
					"lat": "float64",
					"lng": "float64"
				}
			]
		},
		"Description": "string",
		"ID": "UUID v4",
		"Name": "string"
	}
]
```

#### Notification object

```
{
	"ID": "UUID v4",
	"ItemID": "string",
	"Type": "string"
}
```

#### Notification object for matching notification

```
{
	"ID": "UUID v4",
	"ItemID": "string",
	"Matching": {
		"ID": "UUID v4",
		"Invalid": "bool",
		"Offer": {
			"Description": "string",
			"Expired": "bool",
			"ID": "UUID v4",
			"Location": {
				"lat": "float64",
				"lng": "float64"
			},
			"Matched": "bool",
			"Name": "string",
			"Radius": "float64",
			"Tags": [
				null
			],
			"User": {
				"ID": "UUID v4",
				"Mail": "string",
				"Name": "string",
				"PhoneNumbers": "[string, ...]"
			},
			"ValidityPeriod": "RFC3339 date"
		},
		"RegionId": "UUID v4",
		"Request": {
			"Description": "string",
			"Expired": "bool",
			"ID": "UUID v4",
			"Location": {
				"lat": "float64",
				"lng": "float64"
			},
			"Matched": "bool",
			"Name": "string",
			"Radius": "float64",
			"Tags": [
				null
			],
			"User": {
				"ID": "UUID v4",
				"Mail": "string",
				"Name": "string",
				"PhoneNumbers": "[string, ...]"
			},
			"ValidityPeriod": "RFC3339 date"
		}
	},
	"Type": "string"
}
```

#### Notification list

```
[
	{
		"ID": "UUID v4",
		"ItemID": "string",
		"Type": "string"
	}
]
```

#### Notification list for matching notifications

```
[
	{
		"ID": "UUID v4",
		"ItemID": "string",
		"Matching": {
			"ID": "UUID v4",
			"Invalid": "bool",
			"Offer": {
				"Description": "string",
				"Expired": "bool",
				"ID": "UUID v4",
				"Location": {
					"lat": "float64",
					"lng": "float64"
				},
				"Matched": "bool",
				"Name": "string",
				"Radius": "float64",
				"Tags": [
					null
				],
				"User": {
					"ID": "UUID v4",
					"Mail": "string",
					"Name": "string",
					"PhoneNumbers": "[string, ...]"
				},
				"ValidityPeriod": "RFC3339 date"
			},
			"RegionId": "UUID v4",
			"Request": {
				"Description": "string",
				"Expired": "bool",
				"ID": "UUID v4",
				"Location": {
					"lat": "float64",
					"lng": "float64"
				},
				"Matched": "bool",
				"Name": "string",
				"Radius": "float64",
				"Tags": [
					null
				],
				"User": {
					"ID": "UUID v4",
					"Mail": "string",
					"Name": "string",
					"PhoneNumbers": "[string, ...]"
				},
				"ValidityPeriod": "RFC3339 date"
			}
		},
		"Type": "string"
	}
]
```

#### Match partner list

```
[
	{
		"MatchingScore": "float64",
		"Offer": {
			"Description": "string",
			"Expired": "bool",
			"ID": "UUID v4",
			"Location": {
				"lat": "float64",
				"lng": "float64"
			},
			"Matched": "bool",
			"Name": "string",
			"Radius": "float64",
			"Tags": [
				{
					"Name": "string"
				}
			],
			"ValidityPeriod": "RFC3339 date"
		},
		"Recommended": "bool",
		"Region": {
			"Boundaries": {
				"Points": [
					null
				]
			},
			"Description": "string",
			"ID": "UUID v4",
			"Name": "string"
		},
		"Request": {
			"Description": "string",
			"Expired": "bool",
			"ID": "UUID v4",
			"Location": {
				"lat": "float64",
				"lng": "float64"
			},
			"Matched": "bool",
			"Name": "string",
			"Radius": "float64",
			"Tags": [
				{
					"Name": "string"
				}
			],
			"ValidityPeriod": "RFC3339 date"
		}
	}
]
```

#### Offers with matching score

```
[
	{
		"Description": "string",
		"Expired": "bool",
		"ID": "UUID v4",
		"Location": {
			"lat": "float64",
			"lng": "float64"
		},
		"Matched": "bool",
		"MatchingScore": "float64",
		"Name": "string",
		"Radius": "float64",
		"Recommended": "bool",
		"Tags": [
			{
				"Name": "string"
			}
		],
		"ValidityPeriod": "RFC3339 date"
	}
]
```

#### Requests with matching score

```
[
	{
		"Description": "string",
		"Expired": "bool",
		"ID": "UUID v4",
		"Location": {
			"lat": "float64",
			"lng": "float64"
		},
		"Matched": "bool",
		"MatchingScore": "float64",
		"Name": "string",
		"Radius": "float64",
		"Recommended": "bool",
		"Tags": [
			{
				"Name": "string"
			}
		],
		"ValidityPeriod": "RFC3339 date"
	}
]
```


## Incredible third-party packages

We would like to thank all third-party packages we are using in this project! The golang community is incredible.  
A probably incomplete list of used packages looks like:

* [Gin](github.com/gin-gonic/gin)
* [GORM](github.com/jinzhu/gorm)
* [munkres](github.com/clyphub/munkres)
* [JWT](github.com/dgrijalva/jwt-go)
* [Validator](github.com/go-playground/validator)
* [Conform](github.com/leebenson/conform)
* [gin-cors](github.com/itsjamie/gin-cors)
* [gormGIS](github.com/nferruzzi/gormGIS)
* [UUID](github.com/satori/go.uuid)
* [GoDotEnv](github.com/joho/godotenv)

And of course we make heavy use of a lot of golang standard packages.


## License

This project is licensed under [GPLv3](https://github.com/caTUstrophy/backend/blob/master/LICENSE).