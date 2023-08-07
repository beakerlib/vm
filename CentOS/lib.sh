#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Dalibor Pospisil <dapospis@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2023 Red Hat, Inc.
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
#   library-prefix = vmCentOS
#   library-version = 2
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__INTERNAL_vm_LIB_NAME="vm/CentOS"
__INTERNAL_vm_LIB_VERSION=2

: <<'=cut'
=pod

=head1 NAME

vm/basic

=head1 DESCRIPTION

RHEL repos definitions.

=head1 FUNCTIONS

=cut

echo -n "loading library $__INTERNAL_vm_LIB_NAME v$__INTERNAL_vm_LIB_VERSION... "


vmCentOSGetRepos() {
  local major minor nightly
  [[ "${1,,}" =~ centos-([0-9]+)(\.[0-9]+)? ]] || return 1
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  [[ "$1" =~ [0-9]+\.n ]] && nightly=n

  case $major in
    8)
      ( cat - | sed -r 's/^\s*//;s/\s+/ /g;s/\s*$//' | sed -r 's/(\S+)\s+(\S+)\s+(\S+)/\3; \1; \2/' )<<EOF
        CentOS-$major-BaseOS     CentOS-$major-BaseOS     http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/
        CentOS-$major-AppStream  CentOS-$major-AppStream  http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/
EOF
      ;;
    9)
      ( cat - | sed -r 's/^\s*//;s/\s+/ /g;s/\s*$//' | sed -r 's/(\S+)\s+(\S+)\s+(\S+)/\3; \1; \2/' )<<EOF
        CentOS-$major-BaseOS     CentOS-$major-BaseOS     https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/
        CentOS-$major-AppStream  CentOS-$major-AppStream  https://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/
        CentOS-$major-CRB        CentOS-$major-CRB        https://mirror.stream.centos.org/9-stream/CRB/x86_64/os/
EOF
      ;;
    *)
      rlLogError "the centos version $major$minor is not covered"
      ;;
  esac
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

vmCentOSLibraryLoaded() {
  return 0
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
