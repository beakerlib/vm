#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   lib.sh of VM
#   Description: What the test does
#   Author: Dalibor Pospisil <dapospis@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   library-prefix = vm
#   library-version = 3
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__INTERNAL_vm_LIB_NAME="vm/common"
__INTERNAL_vm_LIB_VERSION=3

: <<'=cut'
=pod

=head1 NAME

vm/basic

=head1 DESCRIPTION

Basic functions for handling VMs.

=head1 FUNCTIONS

=cut

echo -n "loading library $__INTERNAL_vm_LIB_NAME v$__INTERNAL_vm_LIB_VERSION... "


declare -F rlLogInfo >/dev/null 2>&1 || rlLogInfo() {
  echo "::[  LOG  ]:: $1" >&2
}


vmSetup() {
  rlRun "rlServiceStart libvirtd"
  rlRun "rlServiceStart virtlogd"
}


vmCleanup() {
  rlRun "rlServiceRestore virtlogd"
  rlRun "rlServiceRestore libvirtd"
}

vmGetRepos() {
  while read -r line; do
    [[ "$line" =~ (vm[a-zA-Z]+GetRepos) ]] && {
      ${BASH_REMATCH[1]} "$@"
    }
  done < <(declare -F)
}


vmGetCurrentRepos() {
  local section url enabled name priority
  while read -r line; do
    [[ "$line" =~ ^\[([^]]+)\] ]] && {
      unset url name enabled
      section="${BASH_REMATCH[1]}"
    }
    [[ -n "$section" ]] && {
      [[ "$line" =~ ^baseurl=(.*)$ ]] && url=${BASH_REMATCH[1]}
      [[ "$line" =~ ^name=(.*)$ ]] && name=${BASH_REMATCH[1]}
      [[ "$line" =~ ^enabled=(.*)$ ]] && enabled=${BASH_REMATCH[1]}
      [[ -n "$url" && -n "$name" && -n "$enabled" ]] && {
        echo -e "$url   ${section}  ${name}  -  ${enabled}"
        unset section
      }
    }
  done < <(cat /etc/yum.repos.d/*.repo)
}


vmGenerateRepoFileSection() {
  local number=$(cat $BEAKERLIB_DIR/vmGenerateRepo_number 2>/dev/null)
  local url section reponame priority enabled

  while read -r url section reponame priority enabled; do
    let number++
    [[ -z "$enabled" ]] && enabled=1
    [[ "$priority" == "-" ]] && priority=''
    echo "[${number}_${section}]
name=${number}: ${reponame}
baseurl=$url
gpgcheck=0
sslverify=0
enabled=$enabled
skip_if_unavailable=1${priority:+$'\n'"priority=$priority"}
"
  done
  echo $number > $BEAKERLIB_DIR/vmGenerateRepo_number
}


vmRepos="https://download.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/x86_64/os/  fedora-rawhide"


vmPrepareKs() {
  local name="$1"
  local ks="$name.ks"
  cat > $ks <<EOKS
firewall --disabled
url                          --url="$(echo "$vmRepos" | head -n 1 | cut -d ' ' -f 1)"
$(echo "$vmRepos" | \
  while read -r url section reponame priority enabled; do
    [[ -z "$enabled" || "$enabled" == "1" || "${enabled,,}" == "true" ]] && echo "repo --name=\"$rel-$reponame\"      --baseurl=$url --cost=100"
  done
)
rootpw --iscrypted \$1\$yYAFxwuK\$EWLgSC/LSPvOrGR8hqjr9/
text
keyboard --vckeymap=us --xlayouts='us','us'
lang en_US.UTF-8
selinux --enforcing
skipx
reboot
timezone --utc Europe/Prague
network  --bootproto=dhcp --onboot=on
bootloader --location=mbr
firstboot --disable
zerombr
clearpart --all --initlabel

autopart --type=lvm

%post
cat >/etc/yum.repos.d/repos.repo <<EOF
$( echo "$vmRepos" | vmGenerateRepoFileSection )
EOF
chmod -R 500 /root/.ssh
restorecon -Rv /root/.ssh

%end

%packages
@base
@Base
openssh-server
curl
sed
%end
EOKS
}


vmDestroy() {
  virsh destroy "$1"
}


vmRemove() {
  virsh undefine "$1" --remove-all-storage
}


vmSnapshotCreate() {
  virsh snapshot-create-as "$1" "$2"
}


vmSnapshotRevert() {
  virsh snapshot-revert "$1" "$2"
}


vmInstall() {
  local name=$1 ks="$2" virt_install_opts cpus
  [[ -z "$ks" ]] && ks="$name.ks"
  cpus=$(grep '^processor' /proc/cpuinfo | wc -l)
  let cpus--
  [[ $cpus%2 -ne 0 ]] && let cpus--
  [[ $cpus -le 0 ]] && cpus=1
  vmDestroy "$name"
  virsh net-start default
  virt_install_opts="--name '$name'"
  virt_install_opts+=" --vcpus $cpus"
  virt_install_opts+=" --memory 2048"
  virt_install_opts+=" --disk size=30 --check disk_size=off"
  virt_install_opts+=" --location $(echo "$vmRepos" | head -n 1 | cut -d ' ' -f 1)"
  virt_install_opts+=" --extra-args 'inst.ks=file:/$ks quiet=0 console=ttyS0,115200'"
  virt_install_opts+=" --wait 90"
  virt_install_opts+=" --initrd-inject '$ks'"
  virt_install_opts+=" --network network=default"
  virt_install_opts+=" --graphics none"
  virt_install_opts+=" --serial pty"
  virt_install_opts+=" --noreboot"
  virt_install_opts+=" --debug"
  rlRun "cat $name.ks" 0-255


  rlLogInfo "running virt-install ${virt_install_opts}"
  eval unbuffer virt-install ${virt_install_opts}
}


vmStart() {
  local name="$1"
  virsh start $name
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Verification
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   This is a verification callback which will be called by
#   rlImport after sourcing the library to make sure everything is
#   all right. It makes sense to perform a basic sanity test and
#   check that all required packages are installed. The function
#   should return 0 only when the library is ready to serve.

vmLibraryLoaded() {

  echo -n "initiating library $__INTERNAL_vm_LIB_NAME v$__INTERNAL_vm_LIB_VERSION... "
  if ! egrep -qi '(vmx|svm|PowerNV)' /proc/cpuinfo; then
    rlLogError "Your CPU doesn't support VMX/SVM/PowerNV"
  fi

  if ! command -v expect >/dev/null 2>&1; then
    rlLogError "expect command is required!"
    res=1
  fi

  rlRun "rlImport vm/Fedora" 0-255
  rlRun "rlImport vm/CentOS" 0-255
  rlRun "rlImport vm/RHEL" 0-255

  echo "done."
  return $res
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Authors
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

: <<'=cut'
=pod

=head1 AUTHORS

=over

=item *

Dalibor Pospisil <dapospis@redhat.com>

=back

=cut

echo "done."
