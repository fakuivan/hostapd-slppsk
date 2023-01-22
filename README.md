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

## Usage

### Typical config

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

### VLANs

A VLAN ID can be assigned to a Master Password, this can be used
along with the `dynamic_vlan` switch to connect a station to a certain
VLAN depending on if the which PSK the station authenticated with.
Every station is able to connect to every configured VLAN _if_ the PSK
used comes from the correct Master Password.

To allow hostapd to connect a wireless interface to a particular
VLAN a bridge is used, the wireless interface is added to
the bridge for that VLAN whenever a station connects with
the PSK that has a `vlanid` specified. For this to work
hostapd needs to know how to map a specific ID to a bridge
and wireless interface name. There are two main mechanisms to
achieve this, using a `vlan_file` with static names or
dynamically trough `vlan_naming`. Since the primary objective
for this project is home networking (many switch chips for OpenWRT
compatible routers don't support more than 15 VLANs), I'll
explain the static method.

The wifi interface config should look like this:

```conf
config wifi-iface 'wifinet4'
    # ...
    option ifname 'wlan-main'
    # Add the following params
    option dynamic_vlan '2'
    option vlan_no_bridge '0'
    option vlan_file '/etc/slppsk/wlan-main.vlan'
```

And the `vlan_file` associated with this interface follows this
syntax:

`/etc/slppsk/wlan-main.vlan`:

```text
10 wlan-main.10 br-iot
2  wlan-main.2  br-lan
4  wlan-main.4  br-guests
```

The first column corresponds to the `vlanid` parameter in
`/etc/config/slppsk`, the second column is the name for the
wireless interface, and the last column should match the bridge
name the VLAN interface is attached to.

The following links contain more info about this feature:

* [Code that parses the `vlan_file`](https://w1.fi/cgit/hostap/tree/hostapd/config_file.c?id=4d663233e64f639998aab31195ab7c819164019c#n36)
* [The third column in `vlan_file` was added in this (relatively recent) commit](https://w1.fi/cgit/hostap/commit/?id=4d663233e64f639998aab31195ab7c819164019c)
* [Patch that added the `vlan_no_bridge` parameter](https://github.com/openwrt/openwrt/blob/openwrt-21.02/package/network/services/hostapd/patches/710-vlan_no_bridge.patch)
* [`vlan_no_bridge` was changed at some point to be default `1`](https://github.com/openwrt/openwrt/issues/9944)
* [Troubleshooting dynamic VLANs](https://openwrt.org/docs/guide-user/network/wifi/wireless.security.8021x#how_it_workstroubleshooting)

One more thing to keep in mind is that interface names have length
limit, so while it might be fine for interface names alone,
once you specify the VLAN ID using dot notation (`<ifname>.<vlan_id>`)
the interface name might excede that limit.

## TODO

* Perm MAC files can only be modified by the event listener on a single interface, otherwise things get out of sync
* Fix inconsistent naming in code around "master password"
* Fix inconsistent naming of project: "hostapd_slppsk" vs "slppsk-hostapd"

## Useful links

* https://forum.openwrt.org/t/how-to-add-a-shell-script-as-a-package-in-menuconfig/95766
* https://github.com/michael-dev/hostapd/blob/f91680c15f80f0b617a0d2c369c8c1bb3dcf078b/src/ap/ap_config.c#L360-L364
* https://openwrt.org/docs/guide-developer/helloworld/chapter3
* https://android.googlesource.com/platform/external/wpa_supplicant_8/+/refs/heads/master/hostapd/hostapd.wpa_psk
