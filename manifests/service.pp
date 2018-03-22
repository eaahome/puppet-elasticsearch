# This class exists to coordinate all service management related actions,
# functionality and logical units in a central place.
#
# *Note*: "service" is the Puppet term and type for background processes
# in general and is used in a platform-independent way. E.g. "service" means
# "daemon" in relation to Unix-like systems.
#
# @param ensure [String]
#   Controls if the managed resources shall be `present` or `absent`.
#   If set to `absent`, the managed software packages will be uninstalled, and
#   any traces of the packages will be purged as well as possible, possibly
#   including existing configuration files.
#   System modifications (if any) will be reverted as well as possible (e.g.
#   removal of created users, services, changed log settings, and so on).
#   This is a destructive parameter and should be used with care.
#
# @param init_defaults [Hash]
#   Defaults file content in hash representation
#
# @param init_defaults_file [String]
#   Defaults file as puppet resource
#
# @param init_template [String]
#   Service file as a template
#
# @param service_flags [String]
#   Flags to pass to the service.
#
# @param status [String]
#   Defines the status of the service. If set to `enabled`, the service is
#   started and will be enabled at boot time. If set to `disabled`, the
#   service is stopped and will not be started at boot time. If set to `running`,
#   the service is started but will not be enabled at boot time. You may use
#   this to start a service on the first Puppet run instead of the system startup.
#   If set to `unmanaged`, the service will not be started at boot time and Puppet
#   does not care whether the service is running or not. For example, this may
#   be useful if a cluster management software is used to decide when to start
#   the service plus assuring it is running on the desired node.
#
# @author Richard Pijnenburg <richard.pijnenburg@elasticsearch.com>
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
define elasticsearch6::service(
  $ensure             = $elasticsearch6::ensure,
  $init_defaults      = undef,
  $init_defaults_file = undef,
  $init_template      = undef,
  $service_flags      = undef,
  $status             = $elasticsearch6::status,
) {

  case $elasticsearch6::real_service_provider {

    'init': {
      elasticsearch6::service::init { $name:
        ensure             => $ensure,
        status             => $status,
        init_defaults_file => $init_defaults_file,
        init_defaults      => $init_defaults,
        init_template      => $init_template,
      }
    }
    'openbsd': {
      elasticsearch6::service::openbsd { $name:
        ensure        => $ensure,
        status        => $status,
        init_template => $init_template,
        service_flags => $service_flags,
      }
    }
    'systemd': {
      elasticsearch6::service::systemd { $name:
        ensure             => $ensure,
        status             => $status,
        init_defaults_file => $init_defaults_file,
        init_defaults      => $init_defaults,
        init_template      => $init_template,
      }
    }
    'openrc': {
      elasticsearch6::service::openrc { $name:
        ensure             => $ensure,
        status             => $status,
        init_defaults_file => $init_defaults_file,
        init_defaults      => $init_defaults,
        init_template      => $init_template,
      }
    }
    default: {
      fail("Unknown service provider ${elasticsearch6::real_service_provider}")
    }

  }

}
