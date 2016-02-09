#!/bin/bash

if [ $# -ne 1 ];then
   echo "usage $0: <gc-project-id>" >&2
   exit 1
fi

cd /build
ARCHIVE_NAME=`ls Fedora-Cloud-Atomic*.xz`
BASE_NAME=`echo $ARCHIVE_NAME | sed 's/\.xz$//'`

PROJECT_NAME=$1
STAMP=`date +"%s"`
BUCKET_NAME=fedora-atomic-gce-$STAMP
TEMP_DIR=/tmp

set -e
set -x
xzcat --decompress $ARCHIVE_NAME > $TEMP_DIR/disk.raw
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
