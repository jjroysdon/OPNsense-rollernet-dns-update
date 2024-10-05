#!/bin/sh

# script to set dynamic dns records at rollernet.us

# https://acc.rollernet.us/help/dns/primary.php#ddns
# Set either ip= or ip6=

# run this from OPNsense router to find it's IPv6 address
# need dig to be installed - https://www.cyberciti.biz/faq/how-to-install-dig-delv-host-commands-on-freebsd/
#  pkg search bind | grep -E 'dig|delv'
#  sudo pkg install -y bind-tools
# need wget to be installed
#  pkg search wget
#  sudo pkg install -y wget

## set variables:
# authoritative DNS server to query - this is where the record is really getting set, so we we the closest source
auth_dns=ns1-auth.rollernet.us
# record to update [this must be a primary dns zone hosted on rollernet.us]
update_domain=dyn.mydomain.tld
# this A and/or AAAA record must already exist in the above zone
#update_name=home
update_name=home
# client (username)  [as specified in Dynamic DNS, must start with a letter and only contain letters and numbers]
#login_client=home
login_client=home
# key (password)
login_key=PUT-TOKEN-HERE

orig_ip=`dig A +short $update_name.$update_domain @$auth_dns | awk -v ORS= '{print $1 }'`
# capture the IPv4 address assigned from the ISP to the WAN interface:
pub_ip=`ifconfig igc0 | grep inet | grep -v inet6 | awk -v ORS= '{print $2 }'`

date +%Y-%m-%d_%H:%M:%S_%Z
echo orig_ip IP: $orig_ip
echo pub_ip IP:   $pub_ip

if [ -n $orig_ip ]; then
    if [ -n $pub_ip ]; then
        if [ "$orig_ip" == "$pub_ip" ]; then
            echo Same ip: $orig_ip
        else
            echo IP changed, updating...
#
# older wget doesn't allow --http-user and --http-password, so must put it inline as a variable:
#            echo wget -q -O - "https://acc.rollernet.us/dns/dynamic.php?client=$login_client&key=$login_key&domain=$update_domain&name=$update_name&ip=$pub_ip"
#            wget -q -O - "https://acc.rollernet.us/dns/dynamic.php?client=$login_client&key=$login_key&domain=$update_domain&name=$update_name&ip=$pub_ip"
#
# newer wget allows for --http-user and --http-password:
            echo wget -q --http-user=$login_client --http-password=$login_key -O - "https://acc.rollernet.us/dns/dynamic.php?domain=$update_domain&name=$update_name&ip=$pub_ip"
            wget -q --http-user=$login_client --http-password=$login_key -O - "https://acc.rollernet.us/dns/dynamic.php?domain=$update_domain&name=$update_name&ip=$pub_ip"
        fi
    else
        echo Cannot determine WAN IP
    fi
else
    echo Cannot determine current DNS IP
fi

# clean up key (password)
login_key=

echo
