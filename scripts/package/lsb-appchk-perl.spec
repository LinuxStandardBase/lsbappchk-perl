%define basedir /opt/lsb
# %{version}, %{rel} are provided by the Makefile
Summary: LSB Perl Application Checker
Name: lsb-appchk-perl
Version: %{version}
Release: %{rel}
License: GPL
Group: Development/Tools
Source: %{name}-%{version}.tar.gz
Source1: perldeps.pl
Source2: COPYING.perldeps.pl
Patch0: perldeps-patch-for-lsb.patch
URL: http://www.linuxbase.org/test
#Prefix: %{_prefix}
BuildRoot: %{_tmppath}/%{name}-root
AutoReqProv: no
BuildArch: noarch
Requires: lsb-tet3-lite

%description
This is the official package version of the LSB Perl Application Test. 
Dependency checking uses perldeps.pl from the rpm-build package, written
by Chip Turner <cturner@redhat.com>.

#==================================================
%prep
%setup -q

#==================================================
%build
cp %{SOURCE1} .
patch -p0 -b -z .lsb-usage < %{PATCH0}

#==================================================
%install

rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}%{basedir}/bin
mkdir -p ${RPM_BUILD_ROOT}%{basedir}/lib/appchk
mkdir -p ${RPM_BUILD_ROOT}%{basedir}/share/appchk
cp -p source/lsbappchk.pl ${RPM_BUILD_ROOT}%{basedir}/bin
cp -p perldeps.pl ${RPM_BUILD_ROOT}%{basedir}/lib/appchk
cp -p lists/lsb-perl-modules.list ${RPM_BUILD_ROOT}%{basedir}/share/appchk

# VERSION file for the journal
cat > VERSION.lsbappchk.pl << EOF
%{name} %{version}-%{rel} (noarch)
EOF
cp VERSION.lsbappchk.pl ${RPM_BUILD_ROOT}%{basedir}/share/appchk

# License files
install -d ${RPM_BUILD_ROOT}%{basedir}/doc/%{name}
cp %{SOURCE2} ${RPM_BUILD_ROOT}%{basedir}/doc/%{name}
cp source/COPYING ${RPM_BUILD_ROOT}%{basedir}/doc/%{name}

#==================================================
%clean
if [ -z "${RPM_BUILD_ROOT}"  -a "${RPM_BUILD_ROOT}" != "/" ]; then 
    rm -rf ${RPM_BUILD_ROOT}
fi

#==================================================
%files
%defattr(-,root,root)

/opt/lsb/bin/lsbappchk.pl
%dir /opt/lsb/lib/appchk
/opt/lsb/lib/appchk/*
%dir /opt/lsb/share/appchk
/opt/lsb/share/appchk/*
%dir /opt/lsb/doc/%{name}
/opt/lsb/doc/%{name}/*

#==================================================
%changelog
* Mon Dec 03 2007 Stew Benedict <stewb@linux-foundation.org>
- Add license files for perldeps.pl and lsbappchk.pl

* Sat Dec  1 2007 Mats Wichmann <mats@linux-foundation.org>
- renamed package to lsb-appchk-perl from lsbappchk-perl (convention)

* Wed Jun 20 2007 Stew Benedict <stewb@linux-foundation.org>
- initial packaging

