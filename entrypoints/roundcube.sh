#!/bin/bash
# Author: Zhang Huangbin <zhb@iredmail.org>

#
# This file is managed by iRedMail Team <support@iredmail.org> with Ansible,
# please do __NOT__ modify it manually.
#

. /docker/entrypoints/functions.sh

ROUNDCUBE_DOCUMENT_ROOT="/opt/www/roundcubemail-1.4.7"
ROUNDCUBE_DOCUMENT_ROOT_SYMLINK="/opt/www/roundcubemail"
ROUNDCUBE_CONF="/opt/www/roundcubemail/config/config.inc.php"

ROUNDCUBE_CUSTOM_CONF_DIR="/opt/iredmail/custom/roundcube"
ROUNDCUBE_CUSTOM_CONF="/opt/iredmail/custom/roundcube/custom.inc.php"
ROUNDCUBE_CUSTOM_PLUGINS_DIR="/opt/iredmail/custom/roundcube/plugins"
ROUNDCUBE_CUSTOM_SKINS_DIR="/opt/iredmail/custom/roundcube/skins"
ROUNDCUBE_CUSTOM_IMAGES_DIR="/opt/iredmail/custom/roundcube/images"

DB_NAME="roundcubemail"
DB_USER="roundcube"

require_non_empty_var ROUNDCUBE_DB_PASSWORD ${ROUNDCUBE_DB_PASSWORD}
require_non_empty_var ROUNDCUBE_DES_KEY ${ROUNDCUBE_DES_KEY}

for dir in \
    ${ROUNDCUBE_CUSTOM_CONF_DIR} \
    ${ROUNDCUBE_CUSTOM_PLUGINS_DIR} \
    ${ROUNDCUBE_CUSTOM_SKINS_DIR} \
    ${ROUNDCUBE_CUSTOM_IMAGES_DIR}; do
    [[ -d ${dir} ]] || mkdir -p ${dir}
    chmod 0755 ${dir}
done

create_rc_custom_conf custom.inc.php
create_rc_custom_conf config_managesieve.inc.php
create_rc_custom_conf config_markasjunk.inc.php
create_rc_custom_conf config_password.inc.php

# Always set correct user/group and permission.
touch_files ${SYS_USER_NGINX} ${SYS_GROUP_NGINX} 0440 \
    ${ROUNDCUBE_CONF} \
    ${ROUNDCUBE_CUSTOM_CONF} \
    ${ROUNDCUBE_CUSTOM_CONF_DIR}/config_*.inc.php \
    /opt/www/roundcubemail/plugins/managesieve/config.inc.php \
    /opt/www/roundcubemail/plugins/password/config.inc.php \
    /opt/www/roundcubemail/plugins/markasjunk/config.inc.php \


# Update message size limit.
${CMD_SED} "s#\(.*max_message_size.*\)=.*#\1 = '${MESSAGE_SIZE_LIMIT_IN_MB}M';#g" ${ROUNDCUBE_CONF}

# Create log directory and file.
create_log_dir /var/log/roundcube
create_log_file /var/log/roundcube/roundcube.log

# Enable modular Nginx config file for `/mail/` url.
gen_symlink_of_nginx_tmpl default-ssl roundcube 90-roundcube

# Create symlinks for custom skins/plugins.
create_rc_symlink_subdir ${ROUNDCUBE_CUSTOM_PLUGINS_DIR} ${ROUNDCUBE_DOCUMENT_ROOT_SYMLINK}/plugins
create_rc_symlink_subdir ${ROUNDCUBE_CUSTOM_SKINS_DIR} ${ROUNDCUBE_DOCUMENT_ROOT_SYMLINK}/skins
ln -sf ${ROUNDCUBE_CUSTOM_IMAGES_DIR} ${ROUNDCUBE_DOCUMENT_ROOT_SYMLINK}/images
