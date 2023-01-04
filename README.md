# Stateless Per-Device PSK for hostapd in OpenWRT

This set of scripts makes use of the `wpa_psk_file` configuration
in hostapd to assign each station (wifi client device) a pre-shared
key derived from a Master Password and the station MAC address. The
code used to derive the PPSK is equivalent to this bash function:

```bash
get_ppsk () {
    local master_pwd="$1" sta_addr="$2" ppsk_len_bytes="$3"
    printf "%s%s" \
            "$master_pwd" \
            "$(echo "$sta_addr" | tr -d : | xxd -r -p)" | \
        sha256sum | \
        cut -d" " -f 1 | \
        xxd -r -p | \
        head -c "$ppsk_len_bytes" | \
        base64
}
```

Essentially the Master Password and the station address (without
colons) are concatenated, hashed using the SHA256 algorithm,
trimmed to a set length and then converted to base64 (to avoid
padding use a multiple of 3 length). I believe this key derivation
process is secure since SHA256 is irreversible, although I am not
at all an expert in cryptography, so please let me know if you find
any issues with the implementation.

The advantage of using keys derived from a Master Password is the
minimal configuration, no databases to maintain, no sync issues, and
the whole thing is pretty lightweight compared to using a RADIUS server
like freeradius.

This project is inspired by 
[this answer](https://security.stackexchange.com/a/266499/193181)
in Stack Exchange Information Security.

## TODO
* Add uci config
* Add service
* Fix inconsistent naming in code around "master password"
* Fix inconsistent naming of project: "hostapd_slppsk" vs "slppsk-hostapd"
