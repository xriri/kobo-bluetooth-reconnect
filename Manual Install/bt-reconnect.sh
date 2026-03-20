#!/bin/sh
# kobo-bluetooth-reconnect
# https://github.com/xriri/kobo-bluetooth-reconnect

LOG="/tmp/bt-reconnect.log"
LOCKFILE="/tmp/bt-connecting.lock"
DBUSLOG="/tmp/bt-dbus.log"
BT_CONFIG="/data/misc/bluedroid/bt_config.conf"

# Timing settings - adjust these if needed
WAIT_BEFORE_CONNECT=3   # seconds to wait after seeing remote before attempting connection
WAIT_AFTER_CONNECT=3    # seconds to wait after connection attempt before checking success
RETRY_DELAY=2           # seconds between retry attempts if connection failed

echo "$(date): bt-reconnect started" >> $LOG

detect_remote_mac() {
    MAC=""
    CURRENT_MAC=""
    IN_REMOTE=0
    while IFS= read -r line; do
        case "$line" in
            \[??:??:??:??:??:??\])
                CURRENT_MAC=$(echo "$line" | tr -d '[]')
                IN_REMOTE=0
                ;;
            *"Name = Kobo Remote"*)
                IN_REMOTE=1
                ;;
            *"HidDescriptor"*)
                if [ "$IN_REMOTE" = "1" ] && [ -n "$CURRENT_MAC" ]; then
                    MAC=$CURRENT_MAC
                fi
                ;;
        esac
    done < "$BT_CONFIG"
    echo "$MAC"
}

REMOTE_MAC=$(detect_remote_mac | tr '[:lower:]' '[:upper:]')

if [ -z "$REMOTE_MAC" ]; then
    echo "$(date): ERROR - Could not find paired Kobo Remote in $BT_CONFIG" >> $LOG
    echo "$(date): Pair your remote via Settings > Bluetooth Connection then restart this script" >> $LOG
    exit 1
fi

echo "$(date): Found Kobo Remote MAC: $REMOTE_MAC" >> $LOG

REMOTE_PATH=$(echo "$REMOTE_MAC" | tr ':' '_')
REMOTE="/org/bluez/hci0/dev_${REMOTE_PATH}"
DEST="com.kobo.mtk.bluedroid"

echo "$(date): Using device path: $REMOTE" >> $LOG

rm -f $LOCKFILE $DBUSLOG
/bin/dbus-monitor --system > $DBUSLOG 2>&1 &

while true; do
    if grep -q "$REMOTE_PATH" $DBUSLOG 2>/dev/null; then
        > $DBUSLOG
        if [ ! -f $LOCKFILE ]; then
            CONNECTED=$(/bin/dbus-send --system --print-reply \
              --dest=$DEST $REMOTE \
              org.freedesktop.DBus.Properties.Get \
              string:"org.bluez.Device1" string:"Connected" 2>/dev/null | grep -c "boolean true")
            if [ "$CONNECTED" != "1" ]; then
                touch $LOCKFILE
                echo "$(date): Remote seen, waiting ${WAIT_BEFORE_CONNECT}s..." >> $LOG
                sleep $WAIT_BEFORE_CONNECT
                RESULT=$(/bin/dbus-send --system --print-reply \
                  --dest=$DEST $REMOTE \
                  org.bluez.Device1.Connect 2>&1)
                echo "$(date): Result: $RESULT" >> $LOG
                sleep $WAIT_AFTER_CONNECT
                CONNECTED=$(/bin/dbus-send --system --print-reply \
                  --dest=$DEST $REMOTE \
                  org.freedesktop.DBus.Properties.Get \
                  string:"org.bluez.Device1" string:"Connected" 2>/dev/null | grep -c "boolean true")
                if [ "$CONNECTED" = "1" ]; then
                    echo "$(date): Connected!" >> $LOG
                else
                    echo "$(date): Connect failed, will retry in ${RETRY_DELAY}s when remote seen again" >> $LOG
                fi
                rm -f $LOCKFILE
            fi
        fi
    fi
    sleep $RETRY_DELAY
done
