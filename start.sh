#!/bin/bash

function _DEFINE_VARIABLES {
        HOSTMOUNT=/host
        USERNAME=upgrade
        PASSWORD="a-cwegsAS-AWFAD12-14!!"
        OUTPUT_FILE=$HOSTMOUNT/root/sles15sp2-sp3-upgrade.txt
        # how many times wait for 5 seconds if salt job for changing channel assignments completes
        # 20 => 20 * 5s = 100s max wait
        WAIT_5S="20"
        OLD_OS_VERSION="15-SP2"
        NEW_OS_VERSION="15-SP3"
}

function _VERIFY_IN_CONTAINER {
        if [ -d $HOSTMOUNT ]; then
                :
        else
                echo "Not in container"
                exit 1
        fi
}

function _CHECK_UPGRADE_NEED {
        source $HOSTMOUNT/etc/os-release
        if [ "$VERSION" == "$NEW_OS_VERSION" ]; then
                echo "No upgrade required as we are already on $NEW_OS_VERSION"
                exit 0
        else
                echo "Upgrade from $OLD_OS_VERSION to $NEW_OS_VERSION"
        fi
}

function _GET_SUMA_CONFIG {
        SERVER=$(grep master: $HOSTMOUNT/etc/salt/minion.d/susemanager.conf|cut -f2 -d " ")
        ACTIVATIONKEY=$(grep activation_key: $HOSTMOUNT/etc/salt/minion.d/susemanager.conf|cut -f2 -d "\"")
        SYSTEM=$(cat $HOSTMOUNT/etc/salt/minion_id)
        echo "SUSE Manager is $SERVER"
        echo "SUSE Manager system is $SYSTEM"
        echo "SUSE Manager activation-key is $ACTIVATIONKEY"
}

function _PREPARE_SPACECMD {
        echo "Preparing spacecmd configuration"
        mkdir -p ~/.spacecmd
        cat << EOF > ~/.spacecmd/config
[spacecmd]
username=$USERNAME
password=$PASSWORD
server=$SERVER
EOF
        cp $HOSTMOUNT/etc/pki/trust/anchors/* /etc/pki/trust/anchors/
        update-ca-certificates
}

function _COPY_GPG_KEY {
        # required for packagehub channels
        cp /*.asc $HOSTMOUNT/root
}

function _GET_CURRENT_CHANNELS {
        echo "Retrieve currently assigned channels"
        CURRENT_ACTIVATIONKEY=$ACTIVATIONKEY
        CURRENT_BASECHANNEL=$(spacecmd -q -- system_listbasechannel $SYSTEM)
        CURRENT_CHILDCHANNELS=$(spacecmd -q -- system_listchildchannels $SYSTEM)
        STAGE=""
        if echo $CURRENT_BASECHANNEL |grep -- -prd- 2>&1 >/dev/null; then
                STAGE="-prd-"
        fi
        if echo $CURRENT_BASECHANNEL |grep -- -tst 2>&1 >/dev/null; then
                STAGE="-tst-"
        fi
        if echo $CURRENT_BASECHANNEL |grep -- -dev- 2>&1 >/dev/null; then
                STAGE="-dev-"
        fi
        if echo $CURRENT_BASECHANNEL |grep -- -sbx- 2>&1 >/dev/null; then
                STAGE="-sbx-"
        fi
        if [ "$STAGE" == "" ]; then
                echo "No stage detected"
                exit 1
        fi
}

function _ADJUST_CHILDCHANNELS_FOR_15SP3 {
        for CHANNEL in $CURRENT_CHILDCHANNELS; do
		if echo $CHANNEL|grep -E '(cap|suse-enterprise-storage|caasp)' >/dev/null 2>&1; then
                        echo
                else
                        echo $CHANNEL|sed 's/sp2/sp3/g'|sed 's/SP2/SP3/g'
                fi
        done
        # adding additional channel for cloud-init-vmware-guestinfo in SLES 15 SP3 if not already included
        TO_ADD="sles15sp3"$STAGE"suse-packagehub-15-sp3-backports-pool-x86_64"
        if echo $CURRENT_CHILDCHANNELS |grep $(echo $TO_ADD|sed 's/sp3/sp2/g'|sed 's/SP3/SP2/g') >/dev/null 2>&1 || echo $CURRENT_CHILDCHANNELS |grep $(echo $TO_ADD)  >/dev/null 2>&1 ; then
                # already in
                :
        else
                echo "$TO_ADD"
        fi
}

function _CREATE_LIST_NEW_CHANNELS_15SP3 {
        NEW_BASECHANNEL=$(echo $CURRENT_BASECHANNEL|sed 's/sp2/sp3/g'|sed 's/SP2/SP3/g')
        NEW_CHILDCHANNELS=$(_ADJUST_CHILDCHANNELS_FOR_15SP3)
        NEW_ACTIVATIONKEY=$ACTIVATIONKEY
}

function _OUTPUT {
        echo "Creating $OUTPUT_FILE in case it does not exist"
        if [ -f $OUTPUT_FILE ]; then
                echo "$OUTPUT_FILE already exists"
        else
                echo "To activate new channels:"| tee -a $OUTPUT_FILE
                echo| tee -a $OUTPUT_FILE
                echo "spacecmd -q -y -- system_schedulechangechannels $SYSTEM -b $NEW_BASECHANNEL" $(for CHANNEL in $NEW_CHILDCHANNELS; do echo " -c $CHANNEL "; done) | tee -a $OUTPUT_FILE
                echo| tee -a $OUTPUT_FILE
                echo "To activate old channels:"| tee -a $OUTPUT_FILE
                echo| tee -a $OUTPUT_FILE
                echo "spacecmd -q -y -- system_schedulechangechannels $SYSTEM -b $CURRENT_BASECHANNEL" $(for CHANNEL in $CURRENT_CHILDCHANNELS; do echo " -c $CHANNEL "; done)| tee -a $OUTPUT_FILE
                echo| tee -a $OUTPUT_FILE
        fi
#       echo "spacecmd -q -y -- system_schedulechangechannels $SYSTEM -b $NEW_BASECHANNEL" $(for CHANNEL in $NEW_CHILDCHANNELS; do echo " -c $CHANNEL "; done)
}

function _IMPORT_GPG_KEYS {
        for KEY in $(ls /*.asc); do
                echo importing key $KEY
                chroot $HOSTMOUNT /bin/bash -c "rpm --import /root/$KEY"
        done
}

function _CONNECT_NEW_CHANNELS {
        echo "Changing assigned channels on $SYSTEM to SLES15-SP3"
        JOB_ID=$(spacecmd -q -y -- system_schedulechangechannels $SYSTEM -b $NEW_BASECHANNEL $(for CHANNEL in $NEW_CHILDCHANNELS; do echo " -c $CHANNEL "; done)|grep "Scheduled action id:"|cut -f2 -d ":"|sed 's/ //g')
        echo "JOB_ID is $JOB_ID"
        # wait until zypper ca shows new channels
        COUNT=0
        while ! spacecmd -q -- schedule_listcompleted|grep $JOB_ID >/dev/null 2>&1; do
                let COUNT++
                echo "Job not yet completed, wait for $COUNT * 5 seconds"
                sleep 5
                if [ "$COUNT" == "$WAIT_5S" ]; then
                        echo "Job to change the channels not completed after 10 * 5 seconds"
                        exit 1
                fi
        done
        echo "Channel assignments are completed."
}

function _EXECUTE_UPGRADE {
        echo "Execute the zypper dup"
        chroot $HOSTMOUNT /bin/bash -c "zypper ref && zypper dup --no-confirm --allow-downgrade --allow-name-change --allow-vendor-change --auto-agree-with-licenses"
}

function _REBOOT_IF_NEEDED {
        echo "Reboot if required"
	# switch reboot to shutdown +1 to get rid of unknown container status
        #chroot $HOSTMOUNT /bin/bash -c "if ! zypper needs-rebooting; then echo 'Reboot required'; reboot; else echo 'No reboot required'; fi"
        chroot $HOSTMOUNT /bin/bash -c "if ! zypper needs-rebooting; then echo 'Reboot required'; shutdown -r +1; else echo 'No reboot required'; fi"
}

function _MAIN {
        _DEFINE_VARIABLES
        _VERIFY_IN_CONTAINER
        _CHECK_UPGRADE_NEED
        _GET_SUMA_CONFIG
        _PREPARE_SPACECMD
        _COPY_GPG_KEY
        _GET_CURRENT_CHANNELS
        _CREATE_LIST_NEW_CHANNELS_15SP3
        _OUTPUT
        _IMPORT_GPG_KEYS
        _CONNECT_NEW_CHANNELS
        _EXECUTE_UPGRADE
        _REBOOT_IF_NEEDED
}

_MAIN

