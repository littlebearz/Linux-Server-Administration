# Linux Commands — AI Agent Index

> Source folder: `Linux Commands/`
> This file consolidates all snippet files in this folder into a single markdown document for AI agents and human operators.
> Each section names its source file. Copy the command blocks as-is.

## Contents

- [60s Diagnose](#60s-diagnose) — `60s_diagnose.txt`
- [Backups (rsnapshot)](#backups-rsnapshot) — `backups.txt`
- [Ban / Unban IP (iptables)](#ban--unban-ip-iptables) — `ban_ip.txt`
- [DNS Ratelimit with iptables](#dns-ratelimit-with-iptables) — `DNS ratelimit with iptables.sh`
- [Find Large Files](#find-large-files) — `Find Large Files.txt`
- [Find Mode / Frequency of Content](#find-mode--frequency-of-content) — `find_mode_frequency_of_content.txt`
- [Firewalls / Log Dropped Packets](#firewalls--log-dropped-packets) — `firewalls.txt`
- [Generate SSL Cert — ssl.conf](#generate-ssl-cert--sslconf) — `Generate SSL Cert/ssl.conf`
- [Generate SSL Cert — step1](#generate-ssl-cert--step1) — `Generate SSL Cert/step1`
- [Get Cronjobs](#get-cronjobs) — `getCronjobs.txt`
- [Get Permission Octal](#get-permission-octal) — `getPermissionOctact.txt`
- [Git Pull (all repos)](#git-pull-all-repos) — `git_pull.sh`
- [Harddrive Info](#harddrive-info) — `Harddrive Info.txt`
- [IRC irssi](#irc-irssi) — `IRC irssi.txt`
- [make](#make) — `make.txt`
- [mtr Network Statistic](#mtr-network-statistic) — `mtr network statistic.txt`
- [Network Monitor](#network-monitor) — `network_monitor.txt`
- [nginx_conf](#nginx_conf) — `nginx_conf`
- [npm Clear Registry](#npm-clear-registry) — `npm clear registry.txt`
- [Pi-hole DNS](#pi-hole-dns) — `piholedns.txt`
- [Remove Leading / Trailing Spaces](#remove-leading--trailing-spaces) — `remove leading spaces.txt`
- [Restart HHVM](#restart-hhvm) — `restart_hhvm.sh.txt`
- [rsync](#rsync) — `rsync.txt`
- [Set Reminder](#set-reminder) — `Set Reminder.txt`
- [SSL Certificates (openssl)](#ssl-certificates-openssl) — `SSL certificates.txt`
- [sudoer (NOPASSWD)](#sudoer-nopasswd) — `sudoer.txt`
- [Symlinks](#symlinks) — `symlinks symbolic links.txt`
- [Sync Large Files over LAN](#sync-large-files-over-lan) — `Sync Large Files LAN.sh`
- [Ubuntu Guest (VirtualBox)](#ubuntu-guest-virtualbox) — `ubuntu_guest.txt`
- [youtube-dl mp3](#youtube-dl-mp3) — `youtube-dl mp3.txt`

---

## 60s Diagnose

Source: `60s_diagnose.txt`

```text
1. uptime
Displays current system uptime and active time

2. dmesg | tail
Shows the last few lines of system log messages (can be used to troubleshoot issues)

3. vmstat 1
Displays virtual memory statistics every second (shows CPU usage, page faults, etc.)

4. mpstat -P ALL 1
Monitors multi-core processor usage and idle times every second

5. pidstat 1
Shows process information, such as CPU usage, memory usage, and I/O statistics, for each process every second (can be used to monitor specific processes)

6. iostat -xz 1
Displays disk statistics (including reads, writes, and latency) every second

7. free -m
Shows free memory, used memory, and available memory in megabytes (useful for checking system resources)

8. sar -n DEV 1
Monitors system performance on a specific device (such as disk or network) every second

9. sar -n TCP,ETCP 1
Analyzes system performance statistics related to TCP and ETCP protocols (useful for monitoring network traffic)

10. top
Displays real-time system activity, including CPU usage, memory usage, and process information
```

## Backups (rsnapshot)

Source: `backups.txt`

```text
rsnapshot
edit /etc/rsnapshot.conf

For local backup the two important lines are:

snapshot_root $dest/
backup $source/ $hostname/

For remote backup the one important line is:
backup root@des.com:/home/ des.com/

Cronjob:
30 23 * * * /usr/bin/rsnapshot daily # daily backup is ran at 11:30 pm
00 23 * * 7 /usr/bin/rsnapshot weekly # weekly backup is ran at 11:00pm # on Sunday
```

## Ban / Unban IP (iptables)

Source: `ban_ip.txt`

```sh
#!/bin/bash
# Ban an IP address using iptables
if [ "$1" != "" ]; then
  echo 'Banning IP = ' $1
  sudo iptables -A INPUT -s $1 -j DROP
else
  echo "First Parameter is missing, please input IP"
fi

#View the Banned IP:
sudo iptables -L -v

# Unban an IP address using iptables
if [ "$1" == "unban" ];then
sudo iptables -D INPUT -s $2 -j DROP

#Generate Helper Text when parameter is /?:
elif [ "$1" == "/?" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "Usage: ban_ip.sh IP or unban_ip.sh unban IP"
fi
```

## DNS Ratelimit with iptables

Source: `DNS ratelimit with iptables.sh`

```sh
#!/bin/bash
# This script limits the queries per second to 5/s
# with a burst rate of 15/s and does not require
# buffer space changes

# Requests per second
RQS="5"

# Requests per 7 seconds
RQH="35"

iptables --flush
iptables -A INPUT -p udp --dport 53 -m state --state NEW -m recent --set --name DNSQF --rsource
iptables -A INPUT -p udp --dport 53 -m state --state NEW -m recent --update --seconds 1 --hitcount ${RQS} --name DNSQF --rsource -j DROP
iptables -A INPUT -p udp --dport 53 -m state --state NEW -m recent --set --name DNSHF --rsource
iptables -A INPUT -p udp --dport 53 -m state --state N
```

Note: the last line in the source file is truncated (`-m state --state N`).

## Find Large Files

Source: `Find Large Files.txt`

```sh
#Recursive Sort using the 5th column
ls -lR | grep '^-' | sort -k 5 -rn

#Same as above with full path
find . -type f -exec du -h {} + | sort -r -h

#Sorting using the currently files that are opened by the OS+Programs
/usr/sbin/lsof -s | awk '$5 == "REG"' | sort -n -r -k 7,7 | head -n 50

#Sorting via the current directory and ignoring permission
du -a . 2>&1| sort -n -r | head -n 15 | grep -v 'Permission denied'

#Sorting via find and ignoring permission denied
find . -type f -path ./ignore_path -prune -o -mtime -1 2>&1 |  grep -v 'Permission denied'

#Recursively search content within same directory and ignoring permission issue
grep -r "content_goes_here" . 2>&1| grep -v 'Permission denied'

#Find and dump all error into /dev/null , replace npm_lazy with the actual file name
find / -name npm_lazy 2>/dev/null

#Find all old files >1yr and greater than 30 megabytes and ignore permission issue
find / -type f -size +30M -mtime +365 2>/dev/null
```

## Find Mode / Frequency of Content

Source: `find_mode_frequency_of_content.txt`

```sh
#Convert csv file to new lines, then trim it, sort, get uniq value and counter, reverse list so most common goes top, cut the top 10
cat tester.csv | tr , '\n' | grep "\S" | sort | uniq -c | sort -nr  | head -10

#similar but uses replacement of tr
<trester.csv tr -c '[:alnum:]' '[\n*]' | sort|uniq -c|sort -nr|head  -10
```

## Firewalls / Log Dropped Packets

Source: `firewalls.txt`

```sh
#Log packets that are dropped
sudo iptables -I INPUT 1 -m limit --limit 5/min -j LOG --log-prefix "iptables DROPPED: " --log-level 4
sudo journalctl -k --grep="iptables DROPPED:"
```

## Generate SSL Cert — ssl.conf

Source: `Generate SSL Cert/ssl.conf`

```ini
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
req_extensions     = req_ext
[ req_distinguished_name ]
countryName                 = CA
stateOrProvinceName         = Ontario
localityName               = Toronto
organizationName           = Information Technology
commonName                 = localhost
[ req_ext ]
subjectAltName = @alt_names
[alt_names]
DNS.1   = web1.localhost
DNS.2   = web2.localhost
DNS.3   = web3.localhost
```

## Generate SSL Cert — step1

Source: `Generate SSL Cert/step1`

```sh
#Optional: Creating your own CA Authority
openssl req -new -x509 -days 3650 -extensions v3_ca -keyout private/cakey.pem -out cacert.pem
#Generate the CSR to be sent to Certificate Authority
openssl req -out sslcert.csr -newkey rsa:4096 -nodes -keyout private/private.key -config ssl.cnf
#Self Signing SSL Certificate
openssl ca -out signed-cert.crt -infiles sslcert.csr
#Output to PKCS12 so MSFT can import it
openssl pkcs12 -inkey private.key -in signed-cert.crt -export -out certificate.p12
```

## Get Cronjobs

Source: `getCronjobs.txt`

```sh
#Output cronjobs + username
for user in $(cut -f1 -d: /etc/passwd); do echo $user; crontab -u $user -l; done
```

## Get Permission Octal

Source: `getPermissionOctact.txt`

```sh
/usr/bin/stat -c "%a %n" PATHHERE
```

## Git Pull (all repos)

Source: `git_pull.sh`

```sh
#!/bin/bash

# Use the provided argument or default to the current directory
DIRECTORY=${1:-$(pwd)}

# Find .git directories and perform the operations
find "$DIRECTORY" -type d -name '.git' -execdir sh -c 'git --git-dir="{}" remote get-url origin && git --git-dir="{}" pull' \;
```

## Harddrive Info

Source: `Harddrive Info.txt`

```sh
#!/bin/bash
echo "Harddrive Information:"
sudo lshw -class disk | grep -E 'description|size|capacity'
sudo smartctl --all /dev/sda | grep Power_On_Hours

ncdu

#find disk usage
du -sk *

#http://linux.dell.com/wiki/index.php/Repository/OMSA#Yum_setup
yum install srvadmin-all
$ omreport storage vdisk
$ omreport storage pdisk controller=0
$ omreport storage vdisk controller=0 vdisk=1
```

## IRC irssi

Source: `IRC irssi.txt`

```text
/ignore * JOINS PARTS QUITS NICKS
```

## make

Source: `make.txt`

```sh
nice -n 19 make -j 4

Where 4 is the 1.5x the number of cores
where nice -n 19 means the lowest priority
```

## mtr Network Statistic

Source: `mtr network statistic.txt`

```sh
mtr --report --report-cycles 1000 myserver.tld > myserver.txt
```

## Network Monitor

Source: `network_monitor.txt`

```sh
#bandwidth monitor for 100kb+
iftop -BPm 1048576
```

## nginx_conf

Source: `nginx_conf` (example `nginx.conf`)

```nginx
user  www-data www-data;

worker_processes  2;

pid /var/run/nginx.pid;

#                          [ debug | info | notice | warn | error | crit ]

error_log  /var/log/nginx.error_log  info;

events {
    worker_connections   2000;

    # use [ kqueue | epoll | /dev/poll | select | poll ];
    #use kqueue;
}

http {

    include       conf.d/mime.types;
    default_type  application/octet-stream;


    log_format main      '$remote_addr - $remote_user [$time_local] '
                         '"$request" $status $bytes_sent '
                         '"$http_referer" "$http_user_agent" '
                         '"$gzip_ratio"';

    log_format download  '$remote_addr - $remote_user [$time_local] '
                         '"$request" $status $bytes_sent '
                         '"$http_referer" "$http_user_agent" '
                         '"$http_range" "$sent_http_content_range"';

    client_header_timeout  3m;
    client_body_timeout    3m;
    send_timeout           3m;

    client_header_buffer_size    1k;
    large_client_header_buffers  4 4k;

    gzip on;
    gzip_min_length  1100;
    gzip_buffers     4 8k;
    gzip_types       text/plain;

    output_buffers   1 32k;
    postpone_output  1460;

    sendfile         on;
    tcp_nopush       on;
    tcp_nodelay      on;
    send_lowat       12000;

    keepalive_timeout  75 20;

    #lingering_time     30;
    #lingering_timeout  10;
    #reset_timedout_connection  on;
    include '/etc/nginx/sites-enabled/*';

    server {
        listen        80;
        server_name   one.example.com  www.one.example.com;

        access_log   /var/log/nginx.access_log  main;

        location / {
            proxy_pass         http://127.0.0.1/;
            proxy_redirect     off;

            proxy_set_header   Host             $host;
            proxy_set_header   X-Real-IP        $remote_addr;
            #proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;

            client_max_body_size       10m;
            client_body_buffer_size    128k;

            client_body_temp_path      /var/nginx/client_body_temp;

            proxy_connect_timeout      70;
            proxy_send_timeout         90;
            proxy_read_timeout         90;
            proxy_send_lowat           12000;

            proxy_buffer_size          4k;
            proxy_buffers              4 32k;
            proxy_busy_buffers_size    64k;
            proxy_temp_file_write_size 64k;

            proxy_temp_path            /var/nginx/proxy_temp;

            charset  koi8-r;
        }

        error_page  404  /404.html;

        location = /404.html {
            root  /spool/www;
        }

        location /old_stuff/ {
            rewrite   ^/old_stuff/(.*)$  /new_stuff/$1  permanent;
        }

        location /download/ {

            valid_referers  none  blocked  server_names  *.example.com;

            if ($invalid_referer) {
                #rewrite   ^/   http://www.example.com/;
                return   403;
            }

            #rewrite_log  on;

            # rewrite /download/*/mp3/*.any_ext to /download/*/mp3/*.mp3
            rewrite ^/(download/.*)/mp3/(.*)\..*$
                    /$1/mp3/$2.mp3                   break;

            root         /spool/www;
            #autoindex    on;
            access_log   /var/log/nginx-download.access_log  download;
        }

        location ~* \.(jpg|jpeg|gif)$ {
            root         /spool/www;
            access_log   off;
            expires      30d;
        }
    }
}
```

## npm Clear Registry

Source: `npm clear registry.txt`

```sh
npm config delete registry
```

## Pi-hole DNS

Source: `piholedns.txt`

```sh
cat -v  pihole.log | grep $1 | grep ANY | awk '{print $8}' | sort | uniq -u
```

## Remove Leading / Trailing Spaces

Source: `remove leading spaces.txt`

```sh
sed -E 's/^\s*//; s/\s*$//'
```

## Restart HHVM

Source: `restart_hhvm.sh.txt`

```sh
#!/bin/sh

PIDS=`ps cax | grep hhvm | grep -v grep | grep -o '^[ ]*[0-9]*'`

if [ -z "$PIDS" ]; then
  /usr/bin/hhvm --config /etc/hhvm/php.ini --config /etc/hhvm/server.ini --user www-data --mode daemon -vPidFile=/var/run/hhvm/pid > /dev/null
else
  for PID in $PIDS; do
        echo $PID
  done
fi
```

## rsync

Source: `rsync.txt`

```sh
rsync -vaPe "ssh -p 22" /source_folder --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} /mnt/destination_folder
```

## Set Reminder

Source: `Set Reminder.txt`

```sh
leave +hhmm
```

## SSL Certificates (openssl)

Source: `SSL certificates.txt`

```sh
#check expiration date
echo | openssl s_client -connect $domain_goes_here:$port_goes_here 2>/dev/null | openssl x509 -noout -dates

#check SHA2 or SHA1
openssl s_client -connect $domain_goes_here:$port_goes_here < /dev/null 2>/dev/null  | openssl x509 -text -in /dev/stdin | grep "Signature Algorithm" | cut -d ":" -f2 | uniq | sed '/^$/d' | sed -e 's/^[ \t]*//';

#Convert x509 to PEM
openssl x509 -in certificatename.cer -outform PEM -out certificatename.pem

#Convert PEM to P7B
#Note: The PKCS#7 or P7B format is stored in Base64 ASCII format and has a file extension of .p7b or .p7c.
#A P7B file only contains certificates and chain certificates (Intermediate CAs), not the private key. The most common platforms that support P7B files are Microsoft Windows and Java Tomcat.
openssl crl2pkcs7 -nocrl -certfile certificatename.pem -out certificatename.p7b -certfile CACert.cer

#Source Information: https://knowledge.digicert.com/generalinformation/INFO4448.html
```

## sudoer (NOPASSWD)

Source: `sudoer.txt`

```sh
echo 'littlebear ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/littlebear-nopasswd && sudo chmod 440 /etc/sudoers.d/littlebear-nopasswd
```

## Symlinks

Source: `symlinks symbolic links.txt`

```sh
ln -s target source
```

## Sync Large Files over LAN

Source: `Sync Large Files LAN.sh`

```sh
#!/bin/bash

# SETUP OPTIONS

display_help() {
    echo "Usage: $0 SRCDIR DESDIR [THREADS]" >&2
    echo
    echo "   $1 is source directory"
    echo "   $2 is destination directory"
    echo
    # echo some stuff here for the -a or --add-options
    exit 1
}

export SRCDIR="$1"
export DESTDIR="$2"
export THREADS="8"

# echo "Source: $SRCDIR\n Destination: $DESDIR\n Threads: $THREADS"
# RSYNC DIRECTORY STRUCTURE

rsync -zr --progress -f"+ */" -f"- *" $SRCDIR/ $DESTDIR/

# FOLLOWING MAYBE FASTER BUT NOT AS FLEXIBLE
# cd $SRCDIR; find . -type d -print0 | cpio -0pdm $DESTDIR/
# FIND ALL FILES AND PASS THEM TO MULTIPLE RSYNC PROCESSES

cd $SRCDIR; find . ! -type d -print0 | xargs -0 -n1 -P$THREADS -I% rsync -az --progress % $DESTDIR/%


# IF YOU WANT TO LIMIT THE IO PRIORITY,
# PREPEND THE FOLLOWING TO THE rsync & cd/find COMMANDS ABOVE:
#   ionice -c2
```

## Ubuntu Guest (VirtualBox)

Source: `ubuntu_guest.txt`

```sh
sudo apt-get install build-essential linux-headers-$(uname -r);
sudo apt-get install virtualbox-guest-x11;
sudo apt-get install virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11;
```

## youtube-dl mp3

Source: `youtube-dl mp3.txt`

```sh
sudo wget https://yt-dl.org/latest/youtube-dl -O /usr/local/bin/youtube-dl
              sudo chmod a+x /usr/local/bin/youtube-dl
              hash -r


youtube-dl --extract-audio --audio-format mp3 "URL"
```
