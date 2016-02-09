#!/bin/bash

if [ $# -ne 1 ];then
   echo "usage $0: <gc-project-id>" >&2
   exit 1
fi

mkdir -p /build
cd /build
ARCHIVE_NAME=`ls Fedora-Cloud-Atomic*.xz 2>/dev/null`
if [ "$ARCHIVE_NAME" != "" ]; then
  BASE_NAME=`echo $ARCHIVE_NAME | sed 's/\.xz$//'`
else
  BASE_NAME="Fedora-Cloud-Atomic-23-20160127.2.x86_64.raw"
fi

PROJECT_NAME=$1
STAMP=`date +"%s"`
BUCKET_NAME=fedora-atomic-gce-$STAMP
TEMP_DIR=/tmp

set -e
set -x
if [ -z "$ARCHIVE_NAME" ]; then
  wget -O - https://download.fedoraproject.org/pub/alt/atomic/stable/Cloud-Images/x86_64/Images/$BASE_NAME.xz | \
     xzcat --decompress > $TEMP_DIR/disk.raw 
else
  xzcat --decompress $ARCHIVE_NAME > $TEMP_DIR/disk.raw
fi
cd $TEMP_DIR 
tar -Szcf $BASE_NAME.tar.gz disk.raw
rm disk.raw


if gcloud compute images list; then
  echo "Using existing credentials"
else
  # Need to login ourselves
  gcloud auth login
fi
gcloud config set project $PROJECT_NAME
gsutil mb gs://$BUCKET_NAME
gsutil cp $BASE_NAME.tar.gz gs://$BUCKET_NAME
gcloud compute images create fedora-cloud-atomic --source-uri gs://$BUCKET_NAME/$BASE_NAME.tar.gz
gsutil rm -r gs://$BUCKET_NAME
