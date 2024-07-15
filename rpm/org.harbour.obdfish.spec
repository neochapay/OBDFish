Name: org.harbour.obdfish

%define __provides_exclude_from ^%{_datadir}/%{name}/.*$
%define __requires_exclude ^lib.*\\.*$

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    harbour-obdfish
Version:    0.94
Release:    1
Group:      Qt/Qt
License:    LICENSE
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires:  pkgconfig(auroraapp)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
BuildRequires:  kf5bluezqt-bluez5-devel
BuildRequires:  kf5bluezqt-bluez5-declarative

%description
Short description of my SailfishOS Application


%prep
%setup -q -n %{name}-%{version}

%build

%qtc_qmake5  \
    VERSION='%{version}-%{release}'

%qtc_make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

mkdir %{buildroot}%{_datadir}/%{name}/lib -p
cp /usr/lib/libKF5BluezQt.so.5 %{buildroot}%{_datadir}/%{name}/lib/

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
