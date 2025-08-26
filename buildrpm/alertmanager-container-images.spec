
%global debug_package   %{nil}
%{!?registry: %global registry container-registry.oracle.com/olcne}

%global _name	alertmanager
%global _buildhost build-ol%{?oraclelinux}-%{?_arch}.oracle.com

Name:       %{_name}-container-image
Version:    0.28.1
Release:    1%{?dist}
Summary:	The Alertmanager handles alerts sent by client applications such as the Prometheus server.
License:    Apache 2.0
Url:        https://github.com/prometheus/alertmanager
Source:     %{name}-%{version}.tar.bz2
Vendor:     Oracle America

%description
The Alertmanager handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver integrations such as email, PagerDuty, or OpsGenie. It also takes care of silencing and inhibition of alerts.

%prep
%setup -q -n %{name}-%{version}

%build
%global docker_tag %{registry}/%{_name}:v%{version}

%__rm -f .dockerignore
yum clean all && \
 yumdownloader --destdir=${PWD}/rpms %{_name}-%{version}-%{release}.%{_build_arch}

docker build --pull \
    --build-arg https_proxy=${https_proxy} \
    -t %{docker_tag} -f ./olm/builds/Dockerfile .
docker save -o %{_name}.tar %{docker_tag}

%install
%__install -D -m 644 %{_name}.tar %{buildroot}/usr/local/share/olcne/%{_name}.tar

%files
%license LICENSE NOTICE THIRD_PARTY_LICENSES.txt olm/SECURITY.md
/usr/local/share/olcne/%{_name}.tar

%changelog
* Tue Aug 26 2025 Olcne-Builder Jenkins <olcne-builder_us@oracle.com> - 0.28.1-1
- Added Oracle Specific Build Files.
