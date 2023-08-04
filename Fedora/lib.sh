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
#   library-prefix = vmFedora
#   library-version = 1
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__INTERNAL_vm_LIB_NAME="vm/Fedora"
__INTERNAL_vm_LIB_VERSION=1

: <<'=cut'
=pod

=head1 NAME

vm/basic

=head1 DESCRIPTION

RHEL repos definitions.

=head1 FUNCTIONS

=cut

echo -n "loading library $__INTERNAL_vm_LIB_NAME v$__INTERNAL_vm_LIB_VERSION... "


vmFedoraGetRepos() {
  local major minor nightly
  [[ "${1,,}" =~ ([0-9]+|rawhide) ]] || return 1
  major=${BASH_REMATCH[1]}

  case $major in
    [0-9]*)
      ( cat - | sed -r 's/^\s*//;s/\s+/ /g;s/\s*$//' | sed -r 's/(\S+)\s+(\S+)\s+(\S+)/\3 \1 \2/' )<<EOF
        fedora-$major          fedora-$major          https://download.fedoraproject.org/pub/fedora/linux/releases/$major/Everything/x86_64/os/
        fedora-$major-updates  fedora-$major-updates  https://download.fedoraproject.org/pub/fedora/linux/updates/$major/Everything/x86_64/
EOF
      ;;
    rawhide)
      ( cat - | sed -r 's/^\s*//;s/\s+/ /g;s/\s*$//' | sed -r 's/(\S+)\s+(\S+)\s+(\S+)/\3 \1 \2/' )<<EOF
        fedora-rawhide         fedora-rawhide         https://download.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/x86_64/os/
EOF
      ;;
    *)
      rlLogError "the fedora version $major is not covered"
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

vmFedoraLibraryLoaded() {
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
