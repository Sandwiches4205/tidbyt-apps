"""
Applet: Richmond Ferry
Summary: Richmond to SF ferry departures
Description: Next departures from Richmond Ferry Terminal to San Francisco, in the
style of a station departure board. Live times from 511 SF Bay, with any delay
against the published schedule shown beside the time.
Author: cinemanerd

Ferry artwork by nyergler, from the SF Bay Ferry community app (Apache 2.0).
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TZ = "America/Los_Angeles"
AGENCY = "SB"  # San Francisco Bay Ferry, in 511's operator list
STOP = "7211"  # Richmond Ferry Terminal
LIVE_API = "https://api.511.org/transit/StopMonitoring?api_key=%s&agency=%s&stopCode=%s&format=json"
SCHED_API = "https://api.511.org/transit/StopTimetable?api_key=%s&OperatorRef=%s&MonitoringRef=%s&format=json"
TTL = 600

# Richmond sees boats both ways. 511 labels San Francisco-bound sailings "S"
# and returning ones "N"; only the former can be boarded here.
TO_SF = "S"

RED = "#ff2d1a"
AMBER = "#ffb000"
WHITE = "#ffffff"
DIM = "#6b1e12"

CHAR_W = 5

ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAeCAYAAACc7RhZAAAOAXpUWHRSYXcgcHJvZmlsZSB0eXBl
IGV4aWYAAHjarZlpkuO6EYT/4xQ+AoECUMBxsEb4Bj6+vwIp9TLT9rxnt2IkigLB2jIri+PWv/65
3T/4i9cVXUxacs354i/WWEPjoFz3Xzvv/orn/fzF5ye+fznv/Hp+CJwSPuX+WvKz/nXevze4PxpH
6dNGZTw/9K8/1OfWoXzb6LmRmEWBg/lsVJ+NJNw/+GeDdrt15Vr0swv98WC93C/3P3cO9h2V1ybf
v0clejNxHwlhiZeLd5FwGyD2T5w0DgrvnkUYzIImiU87Xx9XCMjv4nRZZh5r3XFjPJ7Lxw/H/PW+
5Akcxq7ry5p3sL+n9330Lb1afp/d1O4VjhNfs5Lfn78979Pvs+hOrj7dOb+OwtfzMq/1xc3y8W/v
Wdw+TuNFi5nc5Mepl4vniIWdwMi5LPNS/iWO9bwqr+KAwSDN8xpX5zV89YH8bh/99M1vv87n8AMT
Y1hB+QxhBDnnimioYcjlSHS0l99BpcqkFIKMUydRwtsWf+5bz+2GL9x4elYGz2YUjgRnb/+P148b
7W3Y8d6CqeXECruCVTNmWObsnVUkxO9XHaUT4Nfr+5/lVchgOmEuONiufm/Rk39qy+pITqKFhYnP
G19e57MBIeLeCWO8kIEre0k++0tDUO+JYyE/jY1KkBg6KfAphYmVIYpkklOC3Ztr1J+1IYX7NORH
IpJkUVJTpZErY0jqR2OhhlqSFFNKOWkqqaaWJceccs6ajUWbikZNmlW1aNVWpMSSSi5aiiu1tBqq
wLKp5qq11Fpb46aNnRtXNxa01kOXHnvquWsvvfY2KJ8RRxp56Chu1NFmmDIhnJmnzjLrbMsvSmnF
lVZeusqqq21KbcuOO+28dZddd3tnzbs7rb+8/jxr/pW1cDJlC/WdNS5VfW3hjU6S5YyMhejJuFoG
jAktZ1fxMQZnqbOcXRW+lBSwMllypreMkcG4fEjbv3P3kbkveXMx/k95C6/MOUvd/yNzzlL3Q+Z+
zdtvsjatbcH57mTIYGhBvQT4sWCVFkqz7vjHny702eCfvnzau8Ssa+pete9cd495bLauOXXJa865
lsrWviNO9akFUrpPZgfyhMT53uduQSpXlpR07+SrbTIqN1hjdXiS+/eRGklQYDnW2llwmyCE5hKB
E3Ypt5ljjGir90jpGAlNm5mjfjJznwC8zOzHTHfs3Nlups2nRS2Q++7h3Ew+Wolt9bwasZ33vbaW
3fLVzrfr9em+n/hbnxji9tUICvH1xKTjS8uklJD7LntRVmP2Tv11ojfXnqFzQVoSqWo7OUvFcDaK
eW3KpPydzFFdJ/6kaLkkVSUS8KWhJUo7WoV3vWzFMksp7D2j77ZdyHxg0ywbSBa1c1cVndUJ1soa
c2edJ91codyZXIjfqju1tZpHZYbQKR8gRIFvEd2txSUhtrZ7q24nrg/SqAYVy3loj3uW8ZLeGT/u
9VfGx7sw174WCMYiwoy5kTAnQwcBui/SbpaN3StWzUmIc1m4iAmRNJCTvBLAptCAn4MM5tDgj7c9
sW+72KnKKcZZEsko2Jrljsel02J2ySg4gqWjZ0zsDm7Zs/pF3UNFmqO1fgEGK+E8KIFQBvoxN3CV
AHyXWsB2Ue6NkLhhFLczHFXzL/HDjLi+Qzp379J2VC4qnWKDjuakCS526GOoj3X2g8Yr7RXVVYqf
xedULQuARkwnh2n0XaCt4zQWNGiq7yl9TcvAPOEPQ/PxTB1lLOQF6Cftw+prXnWlCTUSV4gVLtty
tVQ7BYDWgedW75lNo6y07YJFCG2E2DfGO+WEldwrp93lhXF56movxJjOSbI6xo78cSVJHM4uta+Z
sorrffFdLlzsXxAzggHzZig2BGpwzeUVMqP4pneTomgUfp0Fej48gVrrI/xFtnWvgx3TYQFSepzq
VjhdptK/qLU9pBDIfkJPsS+D+tqhd5BU5k5ON0rUC0g0P/DTg1QyS5vAPYFbwHNPlfpSsNpaW3nH
0ldvskfYlPOulIMbViFblrW/RtHqhL+RsmP7coqNJm14435U8ijzZoF58DM5T3MlStHdkPtTxImB
6CaP1gnyzr6H1aTg2lphKpbulYWtU2xhTknZcoDDycfk0yzynWNFSf8KuEcrLsHNShs+GFgQWaWr
VgEVdHE6TqAQIeSMAKql31u0Qp0rjht6zBHi63U7g3Kj7OX4vlJZh6TvzMU3qaZ1F/CpQnL8Ub/7
rl/3oqzfFrBfHbrzHU7NqJgII3WWJPJIaAagItBrU3bVNtL+CsVAr5RziNz6T5+ZvpEaHuVpYKXy
ncKo4XiSIRRqZskMDcSJ9QEF3spw2lP2sZFggbHKUAimTlwPoCySbItRpPyWsvO6Zi/YRK6bDUTc
kzms0vzM+VjNA/Od9oB6exWEdUccKi4Qq7XHSaS1ZYqU7sG+vZMHEkwc6BxPi+7TijKgJGxzb3xI
O7fUuv1861dFp2oj7Zxo5zrAbX1NrK+Fp68ZAj2iphH4JEeApLFGcwohkgUfVY2zTfdend5GLzv0
X8UouCDk6AF9REgS8OZDPRARBlZDDQVJ+Jj4qHX4X64RZ6ij1xw2rUYjd5ayJVbE6J7k9WIrSmm0
ASPEseVs2RT0E/jW5OY6b+0INbzrdTeAgBxFrrIqwHoIaiiY4YNG2Sr8AM1QdxtcOsM3/UYLxMHY
evZnpuKe5XDPrOnueSVYqKK5cR3Y5pTGpkGWQusbjn05Rl/1q1g9sx99ZNCINqGmjbzgBC9Yc3zQ
tNDILyz18FZsAJ/1anN5tHCHGzgmO9D6sCA6rgP3NWMPOwJBinYC2+EDQo4F240xfZ13wyYUNGyL
kOjTsP2Pv2QkLemmVZ417vBU4I7UaRnEYexHzfL38w0UcNjTgWKRpZMjjw+JYjDEpLck2Ob6NBJF
/a4NY0/MBtOCykCKgO0EFeBiRpIZN1AjKDbs72iPuTJyleVrwBemAZC3D62imIJiEbRnTXtTQ+vy
wJuFnd5hoH2tPnWEujnKwDrl8bxcZ3OjmCUVgfMjl7hDJh9ccv0FNmE6h0p2z9bIkDWVGYgwnk52
w0UNLpyPNqkB0W7xYsnuoEUHyhbnDpco9QX0m28OwVxBeLUgI6JWYkoqpfUCO9RAE+8bHMQ1UDI+
FTq9FhovjWusF3ARFdNZ+X0BLrTO8Hl6H8vO4gG1bJo3o3dismNTAVQQnZIgYjZoSHTabcrJygLj
pc+UTJT3sm4Ym/RqJrKrv6vdmzBFjKAF6WFMMAGvFcEONYWSae7Z4k9mlG3gkIIWpkWelBzr6KIn
lgg5NQ/KHctyKzpnFDGtvFG+p7ONBscaP9biB5VigwDD7baQQxu0TE83ZgSnfuzxUEQtAFxng8K+
+3xH1X3rAarofVTGqhGesx0jQyK8lZjua/cQCCMBFZmcZWIwomMxTXRk0wb10xeNSEUPodJ2mD/u
igSa4VRmsuew59Nd305cLN7N9Obdi6h6BojTib5VzzRt16lUY08K0rhuHmRBSwM5C3W3sJKf9mSx
wp2EBRFTCuSQrdiNr5Dr58Y6AEWOPjrspC2lzAxs857q2n3YhP8rYJp4BUjxQlor4uga3cYIa5ph
OSxGLSt4VhTbmSSogqzcGN4DEOOX5goGkZTIcWY9VM5cDYXhSGPr9niTrOcUp2b2NByeKaND7yDa
wkMBMSnqPCxreWKERqYyNyLKpqCPgI89Lw0dtRh3YQqQUGERtGe3DhZjEuL+jNiplA/tZlWhAhZC
cRZhJgWho+q80t3ha7RnAtPKSxcLGw3rpt37a2/BRNxiGZzRxnmkUSyI/20op28DQTLdvdxOL2Kj
RNIQA3OKQwRnE9IrzwQg7wKCm/IhWUroFSO9Y4S3tD0EEuI6ryCzE1g/FxChp6Ng10C3MauGilQg
M/Q7BvPxx8XhTG3RS+MtBaa16nsIVUIZrAsn1T4jCptb+dqfbWt9tp1AOZ/eT2HDVOyr6M94HsnY
gEGl5hgfth8fQ8yd0ExvlLVp3HeTsAeaICc8jaL7T5CzZyoL3BpvjFkKQ2hA7TSk4wEH8ucT2N3f
Rfv5/IRvVz/y8zuIw28pMH+C4sBMyySOwMsZPDCRD5OiAvA0TdoRWOqgv4laY7IeLVD/4N168beK
+LEeXEMG0b6RhX0t82oPqFGGSXsqzLJNeBU9tJlW9BG3A8ipvHQeEnc5BCP8Ek6HwBN7LnKk7zo/
kKVwyD2dbOq2hwnMUz1c31a6z0s/9v+2PWY8W/h8ekS9aw3o0zTOsQMdt5iy3z5+sdOkZSfoZY4w
ikm6W2s3PQrzHM/cnh/cPuetm/IL562YFzJHe0n1OjLqzuoyoeXPcZv2zednyjwbu/fORgOFNFNu
TJDcEh1yLYtEfyJxNgkm2rLEc4t934KYV3c/8gL3bDRNHHQUPwAqx84AS1OhZv2+3bL/CinzFoDz
CQpbTycnxMueWSEOTljXZGpBIzC09mNZOI+X6q0f7YJ1P9Tkgh6LghTqiLIJRxDLh2WVgXJ7JAmR
eCwLgXGi2hAVLSJhsFM7jx3j7bJ73P3lB84ne6ZkOuZ2lcZD01bTMvRve+SP0cc5H8ZwJtXruocn
Ag9eu215mx715XCzqdfDfPNxGGXLSO4bmFr2rOp0Wrl+1ELy49YV6YX/r8S4kxmbIr0JLZs/1uGq
W6zDjE/ST/U/cdBzLl2HT/edQTfvArbp8SNPJuBtoqz2fG3LwdVRcLfBZPx+YPbJZCw6Vh+bT0Jv
YJEeLGTGS0eBzaolcrSH1bc13O/jvXvP8zZxVtL4b1QPlcNb3PPqAAABhWlDQ1BJQ0MgcHJvZmls
ZQAAeJx9kT1Iw0AcxV9bxSIVBzOIOGSoLloQFRFctApFqBBqhVYdTC79giYNSYqLo+BacPBjserg
4qyrg6sgCH6AuLo4KbpIif9LCi1iPDjux7t7j7t3QLBeZprVMQZoum2mEnExk10Vu14RRgQCRjAj
M8uYk6QkfMfXPQJ8vYvxLP9zf44eNWcxICASzzLDtIk3iKc2bYPzPrHAirJKfE48atIFiR+5rnj8
xrngcpBnCmY6NU8sEIuFNlbamBVNjXiSOKpqOuUHMx6rnLc4a+Uqa96TvzCS01eWuU5zEAksYgkS
RCioooQybMRo1UmxkKL9uI9/wPVL5FLIVQIjxwIq0CC7fvA/+N2tlZ8Y95IicaDzxXE+hoCuXaBR
c5zvY8dpnAChZ+BKb/krdWD6k/RaS4seAb3bwMV1S1P2gMsdoP/JkE3ZlUI0g/k88H5G35QF+m6B
7jWvt+Y+Th+ANHWVvAEODoHhAmWv+7w73N7bv2ea/f0A1DhyzluVkZIAAA16aVRYdFhNTDpjb20u
YWRvYmUueG1wAAAAAAA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pO
VGN6a2M5ZCI/Pgo8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJY
TVAgQ29yZSA0LjQuMC1FeGl2MiI+CiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMu
b3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFi
b3V0PSIiCiAgICB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIK
ICAgIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3Vy
Y2VFdmVudCMiCiAgICB4bWxuczpHSU1QPSJodHRwOi8vd3d3LmdpbXAub3JnL3htcC8iCiAgICB4
bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iCiAgICB4bWxuczp0aWZm
PSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIKICAgIHhtbG5zOnhtcD0iaHR0cDovL25z
LmFkb2JlLmNvbS94YXAvMS4wLyIKICAgeG1wTU06RG9jdW1lbnRJRD0iZ2ltcDpkb2NpZDpnaW1w
OjQ5NmI4NTRkLWFmODItNDA0OC04MTA1LTNiMjBlNTY0M2RiOSIKICAgeG1wTU06SW5zdGFuY2VJ
RD0ieG1wLmlpZDo2MzU0MDM2ZS00NmE2LTRlN2YtODE3Yy03ODI0NTgwNjQ2YjYiCiAgIHhtcE1N
Ok9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDo3ZThiZDllYi03MzBlLTRhNzYtODIxNy1jMGIw
ZjI4ODNhOGUiCiAgIEdJTVA6QVBJPSIyLjAiCiAgIEdJTVA6UGxhdGZvcm09Ik1hYyBPUyIKICAg
R0lNUDpUaW1lU3RhbXA9IjE2OTE4NzM0Njk4MDM5MzUiCiAgIEdJTVA6VmVyc2lvbj0iMi4xMC4z
MiIKICAgZGM6Rm9ybWF0PSJpbWFnZS9wbmciCiAgIHRpZmY6T3JpZW50YXRpb249IjEiCiAgIHht
cDpDcmVhdG9yVG9vbD0iR0lNUCAyLjEwIgogICB4bXA6TWV0YWRhdGFEYXRlPSIyMDIzOjA4OjEy
VDEzOjUxOjA5LTA3OjAwIgogICB4bXA6TW9kaWZ5RGF0ZT0iMjAyMzowODoxMlQxMzo1MTowOS0w
NzowMCI+CiAgIDx4bXBNTTpIaXN0b3J5PgogICAgPHJkZjpTZXE+CiAgICAgPHJkZjpsaQogICAg
ICBzdEV2dDphY3Rpb249InNhdmVkIgogICAgICBzdEV2dDpjaGFuZ2VkPSIvIgogICAgICBzdEV2
dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjRmNmYxNTQzLWEwMTEtNDhkYy04MmMxLTMwNTQ0NGNiNWM5
OSIKICAgICAgc3RFdnQ6c29mdHdhcmVBZ2VudD0iR2ltcCAyLjEwIChNYWMgT1MpIgogICAgICBz
dEV2dDp3aGVuPSIyMDIzLTA4LTEyVDEzOjUxOjA5LTA3OjAwIi8+CiAgICA8L3JkZjpTZXE+CiAg
IDwveG1wTU06SGlzdG9yeT4KICA8L3JkZjpEZXNjcmlwdGlvbj4KIDwvcmRmOlJERj4KPC94Onht
cG1ldGE+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAog
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAg
ICAKPD94cGFja2V0IGVuZD0idyI/PgrAJ9UAAAAGYktHRAD/AP8A/6C9p5MAAAAJcEhZcwAAKEsA
AChLAVZ7GmYAAAAHdElNRQfnCAwUMwkrq6PbAAADx0lEQVRYw+3YW4hVVRgH8N9uZrxbeZuyFDSt
vCT2kFmZtVZgWBJRVgpZ+FDQQ0oJvgTReoqKoughCg3xoSiULlAIWe5tmnQxDCmxyZSCECNNK21y
tNPDbGMcR+eMo3OJ/nDgsM9a39n///rW+v7fynQTQh4GYSHm4hr0wWYsx/IiFpWueI+sm8jfj2cx
4iRD1mBuEYs/z/a71HbDqq/AXe0MvQXLsOA/kwEhD6PLlZ3cgWn3FLFY1eszIORhDD7G6HaG7sA3
2Ilv8Uuvz4B2yH+BteXvnxaxOHDC/E/yGocNx7moY2ojQ35j774iDv+7RwsQ8lCPTRjX4vEmvI7V
RSz2QEh5hiswDVNxOUZhvEn6Hn9UTsNAaCrFe6qI2YYeJ0DIQz98iBnYj1fxUhGLnSXpC3AHZuMG
DGkz0KTWteJfAVpiGRYXMWvsSQKsxCw8iRVFLA6GlA/CPNyLWFWgEwSYfLLquR63FjE71O0ChDzM
x4V4uYhFY0j52ApLMu7DeR0KVr0AsA6zi5g1VRv+nLOUAG8XsXhh2/onRtemfEUTOzIe7jD5juMm
PNf9WyDlQ5HwEOquRd/TjXVJ6/pxygw4htuKmL3XPQKk/AE80/JQOwsC/IF9+BVHWs2o4ADmFDH7
q+uMUMrHlDY3dCLKQWxHA/agwRF7VeySZYeo7Cpi/aEzuV61Z4j83WWZG1zljMPYgq+wFV9je5Hi
z1WlbcoHV5p9wgAMQ335Hc7HkIz+lWZ+dW1keqX0EUVtJ4n3Kbu6RacaVuH70gBtLN3f1iLFo63H
TUh5Noyxn3HRESbUMOooF5ebYERpjuqr6ZOr7KU3ZZ0gPxyrcWMbv+7GujrWHKGopPjTcWUy5DVm
mqTGlWWhm4DxmHiUmg26BE2or+3Efv8Al7Z4ugXv4H0pfnnsH0rCE0tHeFX5marSta14G3hXivtr
T4P8OORlWm7GKrwhxR9brPAU3FxmxwwM1fPwYsfLYMrH4k2srWNlU4oNzYTTgOZLjOlz6DcbI9uN
dX3bR/BRdMEW2CjFmadTBQZguhQrM0LqL6R5mF82NP2qPnq6FxU8etpGKIR0HR7UfJnZquxdjf7V
Beq+DHheiks65ANCSP00NzKLMEXvxed4rGojFEIajEdK4iP0bvyAO6XY2K4AIaSBWIylJ72o6F1o
wCyt/EibAoSQFpTNzEj/DbyFhVL8/ZS9QAjpMrzSyWamp6X8UimuarcZCiEtwtPVH+E9GhvLxuw1
KbZ7M1QbQnoct2NbLyW8G99lbK7wkRT3+B/V4x9BDQ3AYCJLiwAAAABJRU5ErkJggg==
""")

# ------------------------------------------------------------------ data

def strip_bom(s):
    """511 returns JSON with a byte-order mark that json.decode chokes on."""
    i = s.find("{")
    return s[i:] if i > 0 else s

def as_list(v):
    if v == None:
        return []
    return v if type(v) == "list" else [v]

def get_json(url):
    resp = http.get(url, ttl_seconds = TTL)
    if resp.status_code != 200:
        return None
    body = strip_bom(resp.body())
    if not body:
        return None
    return json.decode(body)

def delivery(data, wrapper, name):
    """Both feeds nest their payload differently; this digs it out."""
    if data == None:
        return []
    root = data.get("Siri", data) if wrapper else data
    return as_list(root.get("ServiceDelivery", {}).get(name, {}))

def live_delays(key):
    """{journey id: minutes late} from the real-time feed."""
    data = get_json(LIVE_API % (key, AGENCY, STOP))
    out = {}
    for d in delivery(data, True, "StopMonitoringDelivery"):
        for v in as_list(d.get("MonitoredStopVisit")):
            mvj = v.get("MonitoredVehicleJourney", {})
            call = mvj.get("MonitoredCall", {})
            aimed = call.get("AimedDepartureTime")
            expected = call.get("ExpectedDepartureTime")
            ref = mvj.get("FramedVehicleJourneyRef", {}).get("DatedVehicleJourneyRef")
            if not aimed or not expected or not ref:
                continue
            late = int((time.parse_time(expected).unix - time.parse_time(aimed).unix) / 60)
            out[ref] = late
    return out

def fetch_departures(key):
    """Today's San Francisco-bound sailings, with live delays folded in."""
    data = get_json(SCHED_API % (key, AGENCY, STOP))
    visits = []
    for d in delivery(data, True, "StopTimetableDelivery"):
        visits.extend(as_list(d.get("TimetabledStopVisit")))
    if not visits:
        return None

    delays = live_delays(key)

    out = []
    for v in visits:
        tvj = v.get("TargetedVehicleJourney", {})
        if tvj.get("DirectionRef") != TO_SF:
            continue
        aimed = tvj.get("TargetedCall", {}).get("AimedDepartureTime")
        if not aimed:
            continue
        out.append({
            "aimed": time.parse_time(aimed).in_location(TZ),
            "delay": delays.get(tvj.get("DatedVehicleJourneyRef"), 0),
        })

    return sorted(out, key = lambda d: d["aimed"].unix)

def mock_departures(now):
    """Stand-in data so the layout can be checked without calling the API."""
    return [
        {"aimed": now + time.parse_duration("22m"), "delay": 5},
        {"aimed": now + time.parse_duration("2h7m"), "delay": 0},
        {"aimed": now + time.parse_duration("3h12m"), "delay": 0},
    ]

# ---------------------------------------------------------------- screen

def at(x, y, child):
    return render.Padding(pad = (x, y, 0, 0), child = child)

def small(txt, color):
    return render.Text(content = txt, font = "CG-pixel-4x5-mono", color = color, height = 5)

def clock(t):
    return t.format("3:04")

def board(deps, now):
    nxt = deps[0]
    mins = int((nxt["aimed"].unix - now.unix) / 60)

    # The delay rides directly alongside the time, so a Row rather than a fixed
    # position - the hero time is 4 or 5 glyphs wide depending on the hour.
    hero = [render.Text(content = clock(nxt["aimed"]), font = "tb-8", color = WHITE)]
    if nxt["delay"] > 0:
        hero.append(render.Box(width = 2, height = 1))
        hero.append(small("+%d" % nxt["delay"], RED))

    kids = [
        at(0, 1, small("RICHMOND>SF", RED)),
        at(0, 7, render.Box(width = 64, height = 1, color = DIM)),
        at(0, 10, render.Row(cross_align = "end", children = hero)),
    ]

    # Minutes-away, so it reads at a glance from across the room. Dina rather
    # than the pixel font: that font's M is easily misread as an H.
    label = "%dM" % mins if mins < 100 else "99M+"
    kids.append(at(0, 10, render.Box(
        width = 64,
        height = 8,
        child = render.Row(
            expanded = True,
            main_align = "end",
            children = [render.Text(content = label, font = "Dina_r400-6", color = AMBER)],
        ),
    )))

    # The two after that, stacked underneath like a departure board.
    for i in range(1, min(3, len(deps))):
        kids.append(at(0, 14 + 6 * i, small(clock(deps[i]["aimed"]), AMBER)))

    kids.append(at(36, 17, render.Image(src = ICON, width = 28)))
    return render.Stack(children = kids)

def notice(line):
    return render.Stack(children = [
        at(0, 1, small("RICHMOND>SF", RED)),
        at(0, 7, render.Box(width = 64, height = 1, color = DIM)),
        at(0, 13, render.Text(content = line, font = "tb-8", color = WHITE)),
    ])

def main(config):
    now = time.now().in_location(TZ)

    if config.bool("mock", False):
        deps = mock_departures(now)
    else:
        key = config.str("api_key", "")
        if not key:
            return render.Root(child = notice("NO KEY"))
        deps = fetch_departures(key)
        if deps == None:
            return render.Root(child = notice("NO DATA"))
        deps = [d for d in deps if d["aimed"].unix > now.unix]

    if not deps:
        return render.Root(child = notice("NO BOATS"))

    return render.Root(child = board(deps, now))

def get_schema():
    return schema.Schema(version = "1", fields = [])
