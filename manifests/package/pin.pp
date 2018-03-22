# This is not intended to be used directly by external resources like node
# definitions or other modules.
#
# @summary Controls package pinning for the Elasticsearch package.
#
# @example This class may be imported by other classes to use its functionality
#   class { 'elasticsearch6::package::pin': }
#
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
class elasticsearch6::package::pin {

  Exec {
    path => [ '/bin', '/usr/bin', '/usr/local/bin' ],
    cwd  => '/',
  }

  case $::osfamily {
    'Debian': {
      include ::apt

      if ($elasticsearch6::ensure == 'absent') {
        apt::pin { $elasticsearch6::package_name:
          ensure => $elasticsearch6::ensure,
        }
      } elsif ($elasticsearch6::version != false) {
        apt::pin { $elasticsearch6::package_name:
          ensure   => $elasticsearch6::ensure,
          packages => $elasticsearch6::package_name,
          version  => $elasticsearch6::version,
          priority => 1000,
        }
      }

    }
    'RedHat', 'Linux': {

      if ($elasticsearch6::ensure == 'absent') {
        $_versionlock = '/etc/yum/pluginconf.d/versionlock.list'
        $_lock_line = '0:elasticsearch-'
        exec { 'elasticsearch_purge_versionlock.list':
          command => "sed -i '/${_lock_line}/d' ${_versionlock}",
          onlyif  => [
            "test -f ${_versionlock}",
            "grep -F '${_lock_line}' ${_versionlock}",
          ],
        }
      } elsif ($elasticsearch6::version != false) {
        yum::versionlock {
          "0:elasticsearch-${elasticsearch6::pkg_version}.noarch":
            ensure => $elasticsearch6::ensure,
        }
      }

    }
    default: {
      warning("Unable to pin package for OSfamily \"${::osfamily}\".")
    }
  }
}
