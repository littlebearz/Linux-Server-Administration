#!/bin/sh
# /usr/local/bin/gen-motd-login-info
# Generates the custom login banner for littlebear-vegas and prints it to
# stdout. Refreshed every 5 minutes by root's crontab into
# /run/motd-login-info.cache; /etc/update-motd.d/99-login-info serves the
# cache at login so logins stay instant. Safe to run manually: ./gen-motd-login-info
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

printf '\n'

# --- 1. Last IP that connected to the server ------------------------------
# Primary: sshd "Accepted" lines in the systemd journal, matched by syslog
# identifier so it covers the system unit and any extra sshd instances.
# (Neither box keeps /var/log/auth.log.) Fallback: most recent wtmp entry
# that carries an IP address (last -w avoids the 8-char name truncation).
CONN=""
if command -v journalctl >/dev/null 2>&1; then
    LINE=$(journalctl -t sshd --since "7 days ago" --no-pager -o short 2>/dev/null \
        | grep -E 'Accepted (publickey|password|keyboard-interactive) ' | tail -n 1)
    if [ -n "$LINE" ]; then
        # "... sshd[123]: Accepted publickey for USER from IP port ..."
        # (IP patterns avoid {n,m} intervals: mawk on these boxes lacks them)
        CONN=$(printf '%s' "$LINE" | awk '{
            u=""; ip="";
            for (i=1; i<=NF; i++)
                if ($i == "for" && $(i+2) == "from") { u=$(i+1); ip=$(i+3) }
            is_v4 = (ip ~ /^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$/)
            is_v6 = (ip ~ /:/ && ip ~ /^[0-9a-fA-F:][0-9a-fA-F:]*$/)
            if (u != "" && (is_v4 || is_v6)) print u"|"ip"|"$1" "$2" "$3
        }')
    fi
fi
if [ -z "$CONN" ] && command -v last >/dev/null 2>&1 && [ -r /var/log/wtmp ]; then
    CONN=$(last -w -i 2>/dev/null | awk '
        $1 != "reboot" && $1 != "shutdown" && \
        ($3 ~ /^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$/ || \
         ($3 ~ /:/ && $3 ~ /^[0-9a-fA-F:][0-9a-fA-F:]*$/)) \
        { print $1"|"$3"|"$4" "$5" "$6; exit }')
fi
if [ -n "$CONN" ]; then
    WHO=${CONN%%|*}; REST=${CONN#*|}; IP=${REST%%|*}; WHEN=${REST#*|}
    printf 'Last SSH connection: %s from %s at %s\n' "$WHO" "$IP" "$WHEN"
else
    printf 'Last SSH connection: unknown\n'
fi

# --- 2. Last 3 commands that were executed -----------------------------------
# Portable across hosts: littlebear uses bash on some boxes, fish on others.
# Show whichever history file was written most recently.
printf '\nLast 3 commands:\n'
FISH_HIST=/home/littlebear/.local/share/fish/fish_history
BASH_HIST=/home/littlebear/.bash_history
HIST_OUT=""
USE_FISH=0
if [ -r "$FISH_HIST" ]; then
    if [ ! -r "$BASH_HIST" ] || [ "$FISH_HIST" -nt "$BASH_HIST" ]; then
        USE_FISH=1
    fi
fi
if [ "$USE_FISH" = 1 ]; then
    # fish history entries look like: - cmd: <command>
    HIST_OUT=$(grep -a '^- cmd: ' "$FISH_HIST" 2>/dev/null | sed 's/^- cmd: //' | tail -n 3)
elif [ -r "$BASH_HIST" ]; then
    # strip bash "#<epoch>" timestamp lines, keep the last 3 commands
    HIST_OUT=$(grep -v '^#[0-9][0-9]*$' "$BASH_HIST" 2>/dev/null | tail -n 3)
fi
if [ -n "$HIST_OUT" ]; then
    printf '%s\n' "$HIST_OUT" | sed 's/^/  /'
else
    printf '  (history not readable)\n'
fi

# --- 3. Recent fail2ban activity ---------------------------------------------
printf '\nFail2ban (last 5 lines):\n'
F2B=/var/log/fail2ban.log
if [ -r "$F2B" ]; then
    tail -n 5 "$F2B" 2>/dev/null | sed 's/^/  /'
else
    printf '  (log not readable)\n'
fi

# --- 4. System statistics -------------------------------------------------------
printf '\nSystem statistics:\n'
if command -v uptime >/dev/null 2>&1; then
    UP=$(uptime -p 2>/dev/null | sed 's/^up //')
    [ -z "$UP" ] && UP=$(uptime | sed 's/^.*up *//; s/, *[0-9][0-9]* users\?.*//')
    LOAD=$(awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null)
    printf '  Uptime: %s%s\n' "$UP" "${LOAD:+  |  Load: $LOAD}"
fi
if command -v free >/dev/null 2>&1; then
    MEM=$(free -m | awk '/^Mem:/{printf "%d MB / %d MB (%d%% used)", $3, $2, $3*100/$2}')
    [ -n "$MEM" ] && printf '  Memory: %s\n' "$MEM"
fi
DISK=$(df -h / 2>/dev/null | awk 'NR==2{printf "%s / %s (%s used)", $3, $2, $5}')
[ -n "$DISK" ] && printf '  Disk /: %s\n' "$DISK"

printf '\n'
