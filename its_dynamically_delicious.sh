#!/bin/bash

# This is where you should put your key, if you don't put your key, spoiler alert, it won't work.
dreamKey= PUT YOUR KEY HERE

# sets the ip address based on ipinfo.io this sets as a variable and in a file for different use in both address update and for the comm command below.
ip=$(curl ipinfo.io/ip)
curl ipinfo.io/ip > /tmp/newip

while read i
do

# nslookup takes the fqdn, 1 at a time per loop, spits out the output, pipes into grep for the Address which is an IP, after that its regreped using legacy egrep compatibility which filters out for ipv4 addresses. Techinically this could produce a bad output if the dns server submitted an invalid IP as this doesn't limit at 255 but this is unlikely due to RFC and DNS side checks.
        nslookup $i 1.1.1.1 | grep Address | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" >/tmp/55
        cat /tmp/55 | grep -v 1.1.1.1 >/tmp/69
        sleep 1

# Comm takes the IP listed from the nslookup and compares against the new ip it produces a new file and sets a variable called cip which is used to delete the old record if needed. Sleeps in case of network delay.
        comm -2 -3 <(sort /tmp/69) <(sort /tmp/newip) >/tmp/420
        cat /tmp/420
        cip=$(cat /tmp/420)
        sleep 1

# Checks to see if the file produced from the comm is empty, if it is it skips the address because its already up to date.
                if ! [ -s "/tmp/420" ];then
                        continue
                fi
        sleep 1
# Delete the old record, this is necessary to not have duplicate records, sleep is after in case of network delay.
        curl "https://api.dreamhost.com/?key=$dreamKey&cmd=dns-remove_record&record=$i&type=A&value=$cip"
        sleep 10
# Add the new DNS record, sleep after is to slow down script in case of network delay
        curl "https://api.dreamhost.com/?key=$dreamKey&cmd=dns-add_record&record=$i&type=A&value=$ip"
        echo
        echo
        sleep 5
done < domains.txt

# Cleanup all temporary files, technically not necessary due to overwriting file each time but just good practice, I could do this better but I'm lazy.
rm /tmp/420
rm /tmp/55
rm /tmp/69
rm /tmp/newip
