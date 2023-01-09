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
            "$(echo "$sta_addr" | tr -dc a-fA-F0-9 | xxd -r -p)" | \
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
like freeradius. Roaming between multiple APs should also not be an
issue as long as both APs share the same Master Password.

This project is inspired by
[this answer](https://security.stackexchange.com/a/266499/193181)
in Stack Exchange Information Security.

## Typical config

```conf
config password
    # 2.5GHz network connected to lan interface
    list ifname wlan-lan
    # same but 5GHz
    list ifname wlan-lan-fghz

    # Master password used to derive the pre shared
    # keys for each station
    option master_password testing12345
```

Nothing more than that should be needed to have a functional PPSK
setup. For more details read the comments in the
[config file](./files/etc/config/slppsk)

## TODO
* Perm MAC files can only be modified by the event listener on a single interface, otherwise things get out of sync
* Fix inconsistent naming in code around "master password"
* Fix inconsistent naming of project: "hostapd_slppsk" vs "slppsk-hostapd"

## Useful links
* https://forum.openwrt.org/t/how-to-add-a-shell-script-as-a-package-in-menuconfig/95766
* https://github.com/michael-dev/hostapd/blob/f91680c15f80f0b617a0d2c369c8c1bb3dcf078b/src/ap/ap_config.c#L360-L364
* https://openwrt.org/docs/guide-developer/helloworld/chapter3
* https://android.googlesource.com/platform/external/wpa_supplicant_8/+/refs/heads/master/hostapd/hostapd.wpa_psk
