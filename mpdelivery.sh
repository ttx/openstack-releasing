#!/bin/bash
#
# Script to publish development milestones in one shot
#
# Copyright 2011-2013 Thierry Carrez <thierry@openstack.org>
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -e

if [ $# -lt 4 ]; then
    echo "Usage: $0 devversion milestone pubversion projectname"
    echo
    echo "Example: $0 2013.2 havana-1 2013.2.b1 keystone"
    exit 2
fi

DEVVERSION=$1
MILESTONE=$2
PUBVERSION=$3
PROJECT=$4

TOOLSDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function title {
  echo
  echo "$(tput bold)$(tput setaf 1)[ $1 ]$(tput sgr0)"
}

title "Cloning repository for $PROJECT"
MYTMPDIR=`mktemp -d`
cd $MYTMPDIR
git clone https://github.com/openstack/$PROJECT -b milestone-proposed
cd $PROJECT
git review -s

title "Tagging $PUBVERSION (${PROJECT^} $MILESTONE milestone)"
git tag -m "${PROJECT^} $MILESTONE milestone ($PUBVERSION)" -s "$PUBVERSION"
git push gerrit $PUBVERSION

title "Waiting for https://jenkins.openstack.org/job/$PROJECT-tarball/"
$TOOLSDIR/wait_for_tarball.py $PROJECT --tag=$PUBVERSION

title "Checking tarball is similar to last milestone-proposed.tar.gz"
$TOOLSDIR/similar_tarballs.sh $PROJECT milestone-proposed $PUBVERSION
read -sn 1 -p "Press any key to continue..."

title "Uploading tarball to Launchpad"
$TOOLSDIR/upload_release.py $PROJECT $DEVVERSION --milestone=$MILESTONE

title "Cleaning up"
cd ../..
rm -rf $MYTMPDIR