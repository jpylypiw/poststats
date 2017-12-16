#!/bin/bash

# __          _______  _  __
# \ \        / /  __ \| |/ /
#  \ \  /\  / /| |  | | ' / 
#   \ \/  \/ / | |  | |  <  
#    \  /\  /  | |__| | . \ 
#     \/  \/   |_____/|_|\_\
# 
# Copyright (c) 2017 Webdesign Kronberg.
# ----------------------------------------------------------------------------
# This file is analyzing log files for E-Mail Statistics.
# DO NOT MAKE ANY CHANGES HERE! See poststats.cfg for configuration.
# ----------------------------------------------------------------------------

# Basic Variables and Configuration
SCRIPTPATH=$(dirname $0)
LOGDATE=$(date -d "yesterday" +"%b %d")
IPV4ADDRESS=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{ print $2}')
IPV6ADDRESS=$(/sbin/ifconfig eth0 | grep '.*inet6 .*global.*' | awk '{ print $2}')
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

# SPAMASSASSIN
TESTEDMAILCOUNT=0
SPAMCOUNT=0
HAMCOUNT=0

# OUTGOING
SENTMAILCOUNT=0
BOUNCEDMAILCOUNT=0

function analyzeFile {
    # CLAMAV
    let CLEANCOUNT=$CLEANCOUNT+`egrep -nc ".*$LOGDATE.*Clean message.*" $1`
    let INFECTEDCOUNT=$INFECTEDCOUNT+`egrep -nc ".*$LOGDATE.*infected by.*" $1`

    # IMAP
    let IMAPLOGINCOUNT=$IMAPLOGINCOUNT+`egrep -nc ".*$LOGDATE.*imap-login.*" $1`
    let IMAPLOGINFAILCOUNT=$IMAPLOGINFAILCOUNT+`egrep -nc ".*$LOGDATE.*imap-login: Disconnected.*" $1`
    let IMAPIPV4LOGINCOUNT=$IMAPIPV4LOGINCOUNT+`egrep -nc ".*$LOGDATE.*imap-login.*lip=[1-9]{1,3}\..*" $1`
    let IMAPIPV6LOGINCOUNT=$IMAPIPV6LOGINCOUNT+`egrep -nc ".*$LOGDATE.*imap-login.*lip=[0-9a-z]{0,4}\:.*" $1`
    let IMAPWEBLOGINCOUNT=$IMAPWEBLOGINCOUNT+`egrep -nc ".*$LOGDATE.*imap-login.*method=CRAM-MD5.*" $1`

    # POP3
    let POP3LOGINCOUNT=$POP3LOGINCOUNT+`egrep -nc ".*$LOGDATE.*pop3-login.*" $1`
    let POP3LOGINFAILCOUNT=$POP3LOGINFAILCOUNT+`egrep -nc ".*$LOGDATE.*pop3-login: Disconnected.*" $1`
    let POP3IPV4LOGINCOUNT=$POP3IPV4LOGINCOUNT+`egrep -nc ".*$LOGDATE.*pop3-login.*lip=[1-9]{1,3}\..*" $1`
    let POP3IPV6LOGINCOUNT=$POP3IPV6LOGINCOUNT+`egrep -nc ".*$LOGDATE.*pop3-login.*lip=[0-9a-z]{0,4}\:.*" $1`
    let POP3WEBLOGINCOUNT=$POP3WEBLOGINCOUNT+`egrep -nc ".*$LOGDATE.*pop3-login.*method=CRAM-MD5.*" $1`

    # CONNECTION
    let CONNECTIONCOUNT=$CONNECTIONCOUNT+`egrep -nc ".*$LOGDATE.*connect from.*" $1`
    let CONNECTIONIPV4COUNT=$CONNECTIONIPV4COUNT+`egrep -nc ".*$LOGDATE.*connect from.*\[[1-9]{1,3}\..*" $1`
    let CONNECTIONIPV6COUNT=$CONNECTIONIPV6COUNT+`egrep -nc ".*$LOGDATE.*connect from.*\[[0-9a-z]{0,4}\:.*" $1`
    let RELAYDENIED=$RELAYDENIED+`egrep -nc ".*$LOGDATE.*NOQUEUE: reject.*Relay access denied.*" $1`
    let NOPTRCOUNT=$NOPTRCOUNT+`egrep -nc ".*$LOGDATE.*NOQUEUE: reject.*cannot find your reverse hostname.*" $1`

    # BLACKHOLE
    let BLACKHOLEDMAILCOUNT=$BLACKHOLEDMAILCOUNT+`egrep -nc ".*$LOGDATE.*Service unavailable.*blocked using.*" $1`

    # SPAMASSASSIN
    let TESTEDMAILCOUNT=$TESTEDMAILCOUNT+`egrep -nc ".*$LOGDATE.*spamd: checking message.*" $1`
    let SPAMCOUNT=$SPAMCOUNT+`egrep -nc ".*$LOGDATE.*spamd: identified spam.*" $1`
    let HAMCOUNT=$HAMCOUNT+`egrep -nc ".*$LOGDATE.*spamd: clean message.*" $1`

    # OUTGOING
    let SENTMAILCOUNT=$SENTMAILCOUNT+`egrep -nc ".*$LOGDATE.*postfix/smtp.*status=sent.*" $1`
    let BOUNCEDMAILCOUNT=$BOUNCEDMAILCOUNT+`egrep -nc ".*$LOGDATE.*postfix/smtp.*status=bounced.*" $1`
}

for logfile in "${LOGFILES[@]}"
do
    echo "Reading Logfile ${logfile}..."
    analyzeFile $logfile
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

if (( $(ps -ef | grep -v grep | grep "postfix" | wc -l) > 0 ))
then
    POSTFIX=$RUNNING
fi
if (( $(ps -ef | grep -v grep | grep "spamassassin" | wc -l) > 0 ))
then
    SPAMASSASSIN=$RUNNING
fi
if (( $(ps -ef | grep -v grep | grep "clamav" | wc -l) > 0 ))
then
    CLAMAV=$RUNNING
fi
if (( $(ps -ef | grep -v grep | grep "dovecot" | wc -l) > 0 ))
then
    DOVECOT=$RUNNING
fi
if (( $(ps -ef | grep -v grep | grep "opendkim" | wc -l) > 0 ))
then
    OPENDKIM=$RUNNING
fi

# Source E-Mail Template and send Mail
source "$SCRIPTPATH/mailtemplate.sh"

echo $body | mail \
-a "From: $MAILFROM" \
-a "MIME-Version: 1.0" \
-a "Content-Type: text/html" \
-s "$MAILSUBJECT" \
"$MAILTO"

exit 0