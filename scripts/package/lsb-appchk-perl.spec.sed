# %{ver}, %{rel} are provided by the Makefile
%define ver @VERSION@
%define rel @RELEASE@
%define basedir /opt/lsb

Summary: LSB Perl Application Checker
Name: lsb-appchk-perl
Version: %{ver}
Release: %{rel}
License: GPL
Group: Development/Tools
Source: %{name}-%{version}.tar.gz
Source1: perldeps.pl
Source2: COPYING.perldeps.pl
Source3: lsb-perl-modules.list
Patch0: perldeps-patch-for-lsb.patch
Patch1: perldeps-bug-2006.patch
URL: http://www.linuxbase.org/test
BuildRoot: %{_tmppath}/%{name}-root
AutoReqProv: no
BuildArch: noarch

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
patch -p0 -b -z .bug-2006 < %{PATCH1}
# (sb) set the default version we'll test against (from the Makefile)
sed -i 's|my $lsb_version = "4.0"|my $lsb_version = "%{lsbversion}"|g' source/lsbappchk.pl

#==================================================
%install

rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}%{basedir}/bin
mkdir -p ${RPM_BUILD_ROOT}%{basedir}/share/appchk
cp -p source/lsbappchk.pl ${RPM_BUILD_ROOT}%{basedir}/bin
cp -p perldeps.pl ${RPM_BUILD_ROOT}%{basedir}/share/appchk
cp -p %{SOURCE3} ${RPM_BUILD_ROOT}%{basedir}/share/appchk

# VERSION file for the journal
cat > VERSION.lsbappchk.pl << EOF
%{name} %{version}-%{rel} (noarch)
EOF
cp VERSION.lsbappchk.pl ${RPM_BUILD_ROOT}%{basedir}/share/appchk

# License files
install -d ${RPM_BUILD_ROOT}%{basedir}/doc/%{name}
cp %{SOURCE2} ${RPM_BUILD_ROOT}%{basedir}/doc/%{name}
cp source/COPYING ${RPM_BUILD_ROOT}%{basedir}/doc/%{name}

# man page
install -d ${RPM_BUILD_ROOT}%{basedir}/man/man1
cp doc/lsbappchk.pl.1 ${RPM_BUILD_ROOT}%{basedir}/man/man1

#==================================================
%clean
if [ ! -z "${RPM_BUILD_ROOT}"  -a "${RPM_BUILD_ROOT}" != "/" ]; then 
    rm -rf ${RPM_BUILD_ROOT}
fi

#==================================================
%files
%defattr(-,root,root)

/opt/lsb/bin/lsbappchk.pl
%dir /opt/lsb/share/appchk
/opt/lsb/share/appchk/*
%dir /opt/lsb/doc/%{name}
/opt/lsb/doc/%{name}/*
/opt/lsb/man/man1/lsbappchk.pl.1

#==================================================
%changelog
* Fri Dec 19 2008 Stew Benedict <stewb@linux-foundation.org>
- add manpage

* Wed Jul 02 2008 Stew Benedict <stewb@linux-foundation.org>
- lose /opt/lsb/lib to co-exist with new multiversion sdk

* Tue Jun 03 2008 Stew Benedict <stewb@linux-foundation.org>
- add multiversion support (bug 2097)

* Mon Apr 14 2008 Stew Benedict <stewb@linux-foundation.org>
- patch perldeps.pl for bug 2006 (false positives from here docs, P1)

* Fri Feb 15 2008 Stew Benedict <stewb@linux-foundation.org>
- We generate lsb-perl-modules.list from the specdb now
 
* Mon Dec 03 2007 Stew Benedict <stewb@linux-foundation.org>
- Add license files for perldeps.pl and lsbappchk.pl

* Sat Dec  1 2007 Mats Wichmann <mats@linux-foundation.org>
- renamed package to lsb-appchk-perl from lsbappchk-perl (convention)

* Wed Jun 20 2007 Stew Benedict <stewb@linux-foundation.org>
- initial packaging

