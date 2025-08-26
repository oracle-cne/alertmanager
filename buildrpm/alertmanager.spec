{{{$version := printf "%s.%s.%s" .major .minor .patch }}}
%if 0%{?with_debug}
# https://bugzilla.redhat.com/show_bug.cgi?id=995136#c12
%global _dwz_low_mem_die_limit 0
%else
%global debug_package   %{nil}
%endif

%global _name	alertmanager
%global package_name	    github.com/prometheus/%{_name}
%global _buildhost          build-ol%{?oraclelinux}-%{?_arch}.oracle.com
%global golang_version      1.20.12
%global build_date          %(date +%Y%m%d-%H:%M:%%S)

Name:           %{_name}
Version:        {{{$version}}}
Release:        1%{?dist}
Summary:	    The Alertmanager handles alerts sent by client applications such as the Prometheus server.
License:        Apache 2.0
Group:          System/Management
Url:            https://github.com/prometheus/alertmanager
Source:         %{name}-%{version}.tar.bz2
Vendor:         Oracle America
BuildRequires:  golang >= %{golang_version}

%description
The Alertmanager handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver integrations such as email, PagerDuty, or OpsGenie. It also takes care of silencing and inhibition of alerts.

%prep
%setup -q -n %{name}-%{version}

%build
export GOPATH=$(go env GOPATH)
GOPATH_SRC=$GOPATH/src/%{package_name}
%__mkdir_p $GOPATH_SRC
%__rm -r $GOPATH_SRC
%__ln_s $PWD $GOPATH_SRC
%__mkdir_p %{_builddir}/%{name}-%{version}/output/bin/

pushd $GOPATH_SRC
cd ${GOPATH_SRC}
GIT_REVISION={{{.commit_long_hash}}}
BUILD_USER=${BUILD_USER:-"${USER}@%{_buildhost}"}
BUILD_DATE=${BUILD_DATE:-%{build_date}}
ldflags="
        -X github.com/prometheus/common/version.Version=%{version}
        -X github.com/prometheus/common/version.Revision=${GIT_REVISION}
        -X github.com/prometheus/common/version.Branch=HEAD
        -X github.com/prometheus/common/version.BuildUser=${BUILD_USER}
        -X github.com/prometheus/common/version.BuildDate=${BUILD_DATE}"
go build -v -o %{_builddir}/%{name}-%{version}/output/bin/ \
    -ldflags "${ldflags}" \
    ${GOPATH_SRC}/cmd/alertmanager \
    ${GOPATH_SRC}/cmd/amtool
%{_builddir}/%{name}-%{version}/output/bin/%{name} --version
%{_builddir}/%{name}-%{version}/output/bin/amtool --version

%install
install -m 755 -d %{buildroot}%{_sysconfdir}/%{name}
install -p -m 644 -t %{buildroot}%{_sysconfdir}/%{name} %{_builddir}/%{name}-%{version}/examples/ha/alertmanager.yml
install -d -m 755 %{buildroot}%{_bindir}
install -p -m 755 -t %{buildroot}%{_bindir}/ %{_builddir}/%{name}-%{version}/output/bin/alertmanager
install -p -m 755 -t %{buildroot}%{_bindir}/ %{_builddir}/%{name}-%{version}/output/bin/amtool

%files
%{_sysconfdir}/%{name}/alertmanager.yml
%{_bindir}/alertmanager
%{_bindir}/amtool
%license LICENSE NOTICE THIRD_PARTY_LICENSES.txt olm/SECURITY.md
%doc README.md

%clean
rm -fr %{buildroot}
rm -fr %{_builddir}/%{name}-%{version}

%changelog
* {{{.changelog_timestamp}}} - {{{$version}}}-1
- Added Oracle Specific Build Files.
