## Reliable-Public-Resolvers

Check a list of hosts (candidates) for reliable public DNS resolvers. Reliable means responding correctly to queries.

## Use Case

Initial use case is for finding a large number of open DNS resolvers for quick subdomain discovery using a parallel resolver tool such as blechschmidt's [massdns](https://github.com/blechschmidt/massdns).  This software will send very few packets to each host so as to be minimally invasive.

Don't be evil if you use this software.  If you are malicious, no one is responsibel but yourself.

## Candidates list

Provided by mzpqnxow's [public-dns-resolvers](https://github.com/mzpqnxow/public-dns-resolvers) project.  Not privy to the original source, but mzpqnxow claims a public source.

## To avoid the need for sudo on masscan

sudo setcap CAP_NET_RAW+ep /usr/bin/masscan