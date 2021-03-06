# Scrappy SFTP is a multi-user SFTP server with emailed transfer logs.

FROM        ubuntu:14.04
MAINTAINER  nebajoth <nebajoth@gmail.com>

# SFTP on port 22.
EXPOSE      22

# Volumes hold privates SFTP directories of each user and user/group/host credentials.
VOLUME      ["/sftp-root/webroot", "/creds"]

# Install dependencies.
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y --no-install-recommends openssh-server supervisor python3 ssmtp rsync inotify-tools openssl && \
    mkdir -p /var/run/sshd

# Reconfigure sshd to use in-process SFTP server and chroot the sftp group.
RUN sed -e 's|\(Subsystem sftp \).*|\1internal-sftp -l INFO|' -i /etc/ssh/sshd_config && \
    echo '\nMatch group www-data' >>/etc/ssh/sshd_config && \
    echo '    X11Forwarding no' >>/etc/ssh/sshd_config && \
    echo '    AllowTcpForwarding no' >>/etc/ssh/sshd_config && \
    echo '    ChrootDirectory /sftp-root' >>/etc/ssh/sshd_config && \
    echo '    AuthorizedKeysFile /etc/ssh/ssh_host_authorized_keys' >>/etc/ssh/sshd_config && \
    echo '    ForceCommand internal-sftp -l INFO' >>/etc/ssh/sshd_config && \
    # Make all files group writeable so they can be modified by either sftpadmin or the unprivileged users.
    echo '\n# UMask for chrooted SFTP users\nsession optional pam_umask.so umask=002' >>/etc/pam.d/sshd

# Entry point and command.
ENTRYPOINT  ["/usr/local/bin/sftpenv"]
CMD         ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/scrappysftp.conf"]

# Add configuration for supervisord
COPY        supervisord.conf /etc/supervisor/conf.d/scrappysftp.conf

# Add transfer log mailer daemon and utility scripts.
COPY        bin/* /usr/local/bin/
RUN         chmod +x /usr/local/bin/*
