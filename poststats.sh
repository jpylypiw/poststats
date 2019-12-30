#!/bin/bash

# __          _______  _  __
# \ \        / /  __ \| |/ /
#  \ \  /\  / /| |  | | ' /
#   \ \/  \/ / | |  | |  <
#    \  /\  /  | |__| | . \
#     \/  \/   |_____/|_|\_\
#

# Copyright (c) 2019 Webdesign Kronberg.
# ----------------------------------------------------------------------------
# This file is analyzing log files for E-Mail Statistics.
# DO NOT MAKE ANY CHANGES HERE! See poststats.cfg for configuration.
# ----------------------------------------------------------------------------

# Basic Variables and Configuration
SCRIPTPATH=$(dirname "$0")
LOGDATE=$(date -d "yesterday" +"%b %e")
IPV4ADDRESS=$(/sbin/ifconfig | grep 'inet ' | awk '{ print $2}')
IPV6ADDRESS=$(/sbin/ifconfig | grep '.*inet6 .*global.*' | awk '{ print $2}')
source "$SCRIPTPATH/poststats.cfg"

# CLAMAV
CLEANCOUNT=0
INFECTEDCOUNT=0

# IMAP
IMAPLOGINCOUNT=0
IMAPLOGINFAILCOUNT=0
IMAPIPV4LOGINCOUNT=0
IMAPIPV6LOGINCOUNT=0
IMAPWEBLOGINCOUNT=0

# POP3
POP3LOGINCOUNT=0
POP3LOGINFAILCOUNT=0
POP3IPV4LOGINCOUNT=0
POP3IPV6LOGINCOUNT=0
POP3WEBLOGINCOUNT=0

# CONNECTION
CONNECTIONCOUNT=0
CONNECTIONIPV4COUNT=0
CONNECTIONIPV6COUNT=0
RELAYDENIED=0
NOPTRCOUNT=0

# BLACKHOLE
BLACKHOLEDMAILCOUNT=0

# OUTGOING
SENTMAILCOUNT=0
BOUNCEDMAILCOUNT=0

# SPAMASSASSIN
TESTEDMAILCOUNT=0
SPAMCOUNT=0
HAMCOUNT=0

# RSPAMD
RSPAMD_REJECTED=0
RSPAMD_ADD_HEADER=0
RSPAMD_GREYLIST=0
RSPAMD_NO_ACTION=0
RSPAMD_SOFT_REJECT=0
RSPAMD_REWRITE_SUBJECT=0

function analyzeFile() {
    # CLAMAV
    let CLEANCOUNT=$CLEANCOUNT+$(grep -Enc ".*$LOGDATE.*Clean message from.*" "$1")
    let INFECTEDCOUNT=$INFECTEDCOUNT+$(grep -Enc ".*$LOGDATE.*infected by.*" "$1")

    # IMAP
    let IMAPLOGINCOUNT=$IMAPLOGINCOUNT+$(grep -Enc ".*$LOGDATE.*imap-login.*" "$1")
    let IMAPLOGINFAILCOUNT=$IMAPLOGINFAILCOUNT+$(grep -Enc ".*$LOGDATE.*imap-login: Disconnected.*" "$1")
    let IMAPIPV4LOGINCOUNT=$IMAPIPV4LOGINCOUNT+$(grep -Enc ".*$LOGDATE.*imap-login.*lip=[1-9]{1,3}\..*" "$1")
    let IMAPIPV6LOGINCOUNT=$IMAPIPV6LOGINCOUNT+$(grep -Enc ".*$LOGDATE.*imap-login.*lip=[0-9a-z]{0,4}\:.*" "$1")
    let IMAPWEBLOGINCOUNT=$IMAPWEBLOGINCOUNT+$(grep -Enc ".*$LOGDATE.*imap-login.*method=CRAM-MD5.*" "$1")

    # POP3
    let POP3LOGINCOUNT=$POP3LOGINCOUNT+$(grep -Enc ".*$LOGDATE.*pop3-login.*" "$1")
    let POP3LOGINFAILCOUNT=$POP3LOGINFAILCOUNT+$(grep -Enc ".*$LOGDATE.*pop3-login: Disconnected.*" "$1")
    let POP3IPV4LOGINCOUNT=$POP3IPV4LOGINCOUNT+$(grep -Enc ".*$LOGDATE.*pop3-login.*lip=[1-9]{1,3}\..*" "$1")
    let POP3IPV6LOGINCOUNT=$POP3IPV6LOGINCOUNT+$(grep -Enc ".*$LOGDATE.*pop3-login.*lip=[0-9a-z]{0,4}\:.*" "$1")
    let POP3WEBLOGINCOUNT=$POP3WEBLOGINCOUNT+$(grep -Enc ".*$LOGDATE.*pop3-login.*method=CRAM-MD5.*" "$1")

    # CONNECTION
    let CONNECTIONCOUNT=$CONNECTIONCOUNT+$(grep -Enc ".*$LOGDATE.*connect from.*" "$1")
    let CONNECTIONIPV4COUNT=$CONNECTIONIPV4COUNT+$(grep -Enc ".*$LOGDATE.*connect from.*\[[1-9]{1,3}\..*" "$1")
    let CONNECTIONIPV6COUNT=$CONNECTIONIPV6COUNT+$(grep -Enc ".*$LOGDATE.*connect from.*\[[0-9a-z]{0,4}\:.*" "$1")
    let RELAYDENIED=$RELAYDENIED+$(grep -Enc ".*$LOGDATE.*NOQUEUE: reject.*Relay access denied.*" "$1")
    let NOPTRCOUNT=$NOPTRCOUNT+$(grep -Enc ".*$LOGDATE.*NOQUEUE: reject.*cannot find your reverse hostname.*" "$1")

    # BLACKHOLE
    let BLACKHOLEDMAILCOUNT=$BLACKHOLEDMAILCOUNT+$(grep -Enc ".*$LOGDATE.*Service unavailable.*blocked using.*" "$1")

    # OUTGOING
    let SENTMAILCOUNT=$SENTMAILCOUNT+$(grep -Enc ".*$LOGDATE.*postfix/smtp.*status=sent.*" "$1")
    let BOUNCEDMAILCOUNT=$BOUNCEDMAILCOUNT+$(grep -Enc ".*$LOGDATE.*postfix/smtp.*status=bounced.*" "$1")

    # SPAMASSASSIN
    let TESTEDMAILCOUNT=$TESTEDMAILCOUNT+$(grep -Enc ".*$LOGDATE.*spamd: checking message.*" "$1")
    let SPAMCOUNT=$SPAMCOUNT+$(grep -Enc ".*$LOGDATE.*spamd: identified spam.*" "$1")
    let HAMCOUNT=$HAMCOUNT+$(grep -Enc ".*$LOGDATE.*spamd: clean message.*" "$1")

    # RSPAMD
    let RSPAMD_REJECTED=$RSPAMD_REJECTED+$(grep -Enc ".*$LOGDATE.* (reject):.*" "$1")
    let RSPAMD_ADD_HEADER=$RSPAMD_ADD_HEADER+$(grep -Enc ".*$LOGDATE.* (add header):.*" "$1")
    let RSPAMD_GREYLIST=$RSPAMD_GREYLIST+$(grep -Enc ".*$LOGDATE.* (greylist):.*" "$1")
    let RSPAMD_NO_ACTION=$RSPAMD_NO_ACTION+$(grep -Enc ".*$LOGDATE.* (no action):.*" "$1")
    let RSPAMD_SOFT_REJECT=$RSPAMD_SOFT_REJECT+$(grep -Enc ".*$LOGDATE.* (soft reject):.*" "$1")
    let RSPAMD_REWRITE_SUBJECT=$RSPAMD_REWRITE_SUBJECT+$(grep -Enc ".*$LOGDATE.* (rewrite subject):.*" "$1")
}

for logfile in "${LOGFILES[@]}"; do
    echo "Analyzing Logfile ${logfile}..."
    analyzeFile "$logfile"
    echo "Done."
done

# Service Status
STOPPED="<span class=\"stateDOWN\">STOPPED</span>"
RUNNING="<span class=\"stateUP\">RUNNING</span>"

POSTFIX=$STOPPED
SPAMASSASSIN=$STOPPED
CLAMAV=$STOPPED
DOVECOT=$STOPPED
OPENDKIM=$STOPPED
RSPAMD=$STOPPED

if (($(pgrep -c "smtpd") > 0)); then
    POSTFIX=$RUNNING
fi
if (($(pgrep -c "rspamd") > 0)); then
    RSPAMD=$RUNNING
fi
if (($(pgrep -c "spamd") > 0)); then
    SPAMASSASSIN=$RUNNING
fi
if (($(pgrep -c "clamav") > 0)); then
    CLAMAV=$RUNNING
fi
if (($(pgrep -c "dovecot") > 0)); then
    DOVECOT=$RUNNING
fi
if (($(pgrep -c "opendkim") > 0)); then
    OPENDKIM=$RUNNING
fi

# load E-Mail Template from HTML file and replace all variables in the template
TEMPLATE=$(eval "cat << EOF
$(<"$SCRIPTPATH"/mailtemplate.html)
EOF
")

# send E-Mail using the parameters from configuration

echo "$TEMPLATE" | mail \
    -a "From: $MAILFROM" \
    -a "MIME-Version: 1.0" \
    -a "Content-Type: text/html" \
    -s "$MAILSUBJECT" \
    "$MAILTO"

exit 0
