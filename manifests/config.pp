# This class exists to coordinate all configuration related actions,
# functionality and logical units in a central place.
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
# @example importing this class into other classes to use its functionality:
#   class { 'elasticsearch6::config': }
#
# @author Richard Pijnenburg <richard.pijnenburg@elasticsearch.com>
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
class elasticsearch6::config {

  #### Configuration

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  if ( $elasticsearch6::ensure == 'present' ) {

    file {
      $elasticsearch6::configdir:
        ensure => 'directory',
        group  => $elasticsearch6::elasticsearch_group,
        owner  => $elasticsearch6::elasticsearch_user,
        mode   => '0755';
      $elasticsearch6::datadir:
        ensure => 'directory',
        group  => $elasticsearch6::elasticsearch_group,
        owner  => $elasticsearch6::elasticsearch_user;
      $elasticsearch6::logdir:
        ensure  => 'directory',
        group   => undef,
        owner   => $elasticsearch6::elasticsearch_user,
        mode    => '0755',
        recurse => true;
      $elasticsearch6::plugindir:
        ensure => 'directory',
        group  => $elasticsearch6::elasticsearch_group,
        owner  => $elasticsearch6::elasticsearch_user,
        mode   => 'o+Xr';
      "${elasticsearch6::homedir}/lib":
        ensure  => 'directory',
        group   => '0',
        owner   => 'root',
        recurse => true;
      $elasticsearch6::params::homedir:
        ensure => 'directory',
        group  => $elasticsearch6::elasticsearch_group,
        owner  => $elasticsearch6::elasticsearch_user;
      "${elasticsearch6::params::homedir}/templates_import":
        ensure => 'directory',
        group  => $elasticsearch6::elasticsearch_group,
        owner  => $elasticsearch6::elasticsearch_user,
        mode   => '0755';
      "${elasticsearch6::params::homedir}/scripts":
        ensure => 'directory',
        group  => $elasticsearch6::elasticsearch_group,
        owner  => $elasticsearch6::elasticsearch_user,
        mode   => '0755';
      '/etc/elasticsearch/elasticsearch.yml':
        ensure => 'absent';
      '/etc/elasticsearch/jvm.options':
        ensure => 'absent';
      '/etc/elasticsearch/logging.yml':
        ensure => 'absent';
      '/etc/elasticsearch/log4j2.properties':
        ensure => 'absent';
      '/etc/init.d/elasticsearch':
        ensure => 'absent';
    }

    if $elasticsearch6::params::pid_dir {
      file { $elasticsearch6::params::pid_dir:
        ensure  => 'directory',
        group   => undef,
        owner   => $elasticsearch6::elasticsearch_user,
        recurse => true,
      }

      if ($elasticsearch6::service_providers == 'systemd') {
        $group = $elasticsearch6::elasticsearch_group
        $user = $elasticsearch6::elasticsearch_user
        $pid_dir = $elasticsearch6::params::pid_dir

        file { '/usr/lib/tmpfiles.d/elasticsearch.conf':
          ensure  => 'file',
          content => template("${module_name}/usr/lib/tmpfiles.d/elasticsearch.conf.erb"),
          group   => '0',
          owner   => 'root',
        }
      }
    }

    if ($elasticsearch6::service_providers == 'systemd') {
      # Mask default unit (from package)
      exec { 'systemctl mask elasticsearch.service':
        unless => 'test `systemctl is-enabled elasticsearch.service` = masked',
      }
    }

    if $elasticsearch6::params::defaults_location {
      augeas { "${elasticsearch6::params::defaults_location}/elasticsearch":
        incl    => "${elasticsearch6::params::defaults_location}/elasticsearch",
        lens    => 'Shellvars.lns',
        changes => [
          'rm CONF_FILE',
          'rm CONF_DIR',
          'rm ES_PATH_CONF',
        ],
      }
    }

    if $::elasticsearch6::security_plugin != undef and ($::elasticsearch6::security_plugin in ['shield', 'x-pack']) {
      file { "/etc/elasticsearch/${::elasticsearch6::security_plugin}" :
        ensure => 'directory',
      }
    }

    # Define logging config file for the in-use security plugin
    if $::elasticsearch6::security_logging_content != undef or $::elasticsearch6::security_logging_source != undef {
      if $::elasticsearch6::security_plugin == undef or ! ($::elasticsearch6::security_plugin in ['shield', 'x-pack']) {
        fail("\"${::elasticsearch6::security_plugin}\" is not a valid security_plugin parameter value")
      }

      $_security_logging_file = $::elasticsearch6::security_plugin ? {
        'shield' => 'logging.yml',
        default => 'log4j2.properties'
      }

      file { "/etc/elasticsearch/${::elasticsearch6::security_plugin}/${_security_logging_file}" :
        content => $::elasticsearch6::security_logging_content,
        source  => $::elasticsearch6::security_logging_source,
      }
    }

  } elsif ( $elasticsearch6::ensure == 'absent' ) {

    file { $elasticsearch6::plugindir:
      ensure => 'absent',
      force  => true,
      backup => false,
    }

    file { "${elasticsearch6::configdir}/jvm.options":
      ensure => 'absent',
    }

  }

}
