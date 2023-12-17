#!/bin/sh
# Rotate ssh key
[ -z "$1" ] && echo "Syntax: $0 remote_username@remote_ssh_hostname" && exit
host="$1"
if ! echo $host | grep "@"; then
	REMOTE_USER=$USER
else
	REMOTE_USER=$(echo $host | cut -d'@' -f1)
fi
echo "Remote User: $REMOTE_USER"
AUTH_KEY="/home/${REMOTE_USER}/.ssh/authorized_keys"
#
if ! ssh -o PasswordAuthentication=no $host echo "Verified OK"; then
	echo "Error: Current Key Not working on $host"
	echo "Try run: ssh-copy-id $host"
	exit
fi
#
PRIV="$HOME"/.ssh/id_rsa
PUB="$PRIV".pub
# grab the last 8 chars in key part as key.
oldkey=$(awk '{print substr($(NF - 1 ), length($(NF -1 )) - 8 )}' "$PUB")
# old_fp=$(ssh-keygen -l -f "$PUB")
# old_key_id=$(awk '{print $NF}' "$PUB")
mv "$PRIV" "$PRIV.old"
mv "$PUB" "$PRIV.old.pub"
# Generate new key pair, overwrite
yes | ssh-keygen -t rsa -N '' -f "$PRIV"
# new_key=$(awk '{print substr($(NF - 1 ), length($(NF -1 )) - 8 )}' "$PUB")
# new_key_id=$(awk '{print $NF}' "$PUB")
echo "Old Key: $old_key"
# echo "New Key ID: $new_key_id, New Key: $new_key"
# Verify old key still working
if ! ssh -o PasswordAuthentication=no -i $PRIV.old $host echo "Old Key Verified OK"; then
	echo "Error: old key revoked."
	exit
fi
# Add New Key
cat $PUB | ssh -o PasswordAuthentication=no -i $PRIV.old $host tee -a $AUTH_KEY
# Remove Old Key, key character could be /+=, so use "|" in sed pattern.
CMD="sed -i '\|$oldkey|d' $AUTH_KEY"
ssh -o PasswordAuthentication=no -i $PRIV.old $host "$CMD"
# Verify New Key
if ! ssh -o PasswordAuthentication=no $host echo "New Key verified OK"; then
	echo "Error: new key failed to add."
	exit
fi
