# tlsa
A quick shell wrapper to check if a domain's DANE/TLSA hash entry is correct.

Default port is 443.

```shell
# ./tlsa.sh [domain] [port]

$ ./tlsa.sh bytema.re
DANE/TLSA record matches server certificate

$ ./tlsa.sh bytema.re 443
DANE/TLSA record matches server certificate
```

## Future Features

- [ ] Error handling of openssl and dig output
- [ ] Check rest of DNS entry
- [ ] Ability to create DANE/TLSA entries with options
