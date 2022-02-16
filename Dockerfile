FROM registry01.suse:5000/rke-prod/registry.suse.com/suse/sle15:15.3.17.8.25
# Adjust the maintainer to your name and email address
MAINTAINER Martin Weiss <martin.weiss@suse.com>

# Specify the ports for external access (SMT only requires http and https from external)
# The other services - especially mysql are not exposed as these are required internal, only
#EXPOSE 80 443

# Start script for the container, here the magic happens
ENTRYPOINT "/start.sh"

# Add trust to SUSE Manager and other CAs
COPY anchors/* /etc/pki/trust/anchors
RUN /usr/sbin/update-ca-certificates

RUN rm /usr/lib/zypp/plugins/services/container-suseconnect-zypp; \
        zypper ar --no-gpgcheck  https://susemanager.weiss.ddnss.de:443/ks/dist/sles15sp3 SLE-Product-SLES15-SP3-Pool; \
        zypper ar --no-gpgcheck  https://susemanager.weiss.ddnss.de:443/ks/dist/child/staging-sles15sp3-prod-sle-product-sles15-sp3-updates-x86_64/sles15sp3 SLE-Product-SLES15-SP3-Updates; \
        zypper ar --no-gpgcheck  https://susemanager.weiss.ddnss.de:443/ks/dist/child/staging-sles15sp3-prod-sle-module-basesystem15-sp3-pool-x86_64/sles15sp3 SLE-Module-Basesystem15-SP3-Pool; \
        zypper ar --no-gpgcheck  https://susemanager.weiss.ddnss.de:443/ks/dist/child/staging-sles15sp3-prod-sle-module-basesystem15-sp3-updates-x86_64/sles15sp3 SLE-Module-Basesystem15-SP3-Updates; \
        zypper ar --no-gpgcheck  https://susemanager.weiss.ddnss.de:443/ks/dist/child/staging-sles15sp3-prod-sle-module-server-applications15-sp3-pool-x86_64/sles15sp3 SLE-Module-Server-Applications15-SP3-Pool; \
        zypper ar --no-gpgcheck  https://susemanager.weiss.ddnss.de:443/ks/dist/child/staging-sles15sp3-prod-sle-module-server-applications15-sp3-updates-x86_64/sles15sp3 SLE-Module-Server-Applications15-SP3-Updates; \
        zypper ar --no-gpgcheck  https://susemanager.weiss.ddnss.de:443/ks/dist/child/staging-sles15sp3-prod-sle-manager-tools15-pool-x86_64-sp3/sles15sp3 SLE-Manager-Tools15-Pool; \
        zypper ar --no-gpgcheck  https://susemanager.weiss.ddnss.de:443/ks/dist/child/staging-sles15sp3-prod-sle-manager-tools15-updates-x86_64-sp3/sles15sp3 SLE-Manager-Tools15-Updates; \
        zypper ref; \
        zypper -n up; \
        rm /usr/lib/zypp/plugins/services/container-suseconnect-zypp; \
        zypper -n in spacecmd;

# Copy the start script for the container into the image
COPY gpg-pubkey-65176565-59787af5.asc /
#COPY start.sh /

# Optional: cleanup for repositories and clear zypper cache. Further cleanup possible in case required.
#RUN zypper sd {0..99}; zypper cc

