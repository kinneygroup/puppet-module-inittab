# == Class: inittab
#
# Manage inittab
#
class inittab (
  $default_runlevel = 'USE_DEFAULTS',
  $ensure_ttys1     = undef,
) {

  if $ensure_ttys1 {
    validate_re($ensure_ttys1,'^(present)|(absent)$',"inittab::ensure_ttys1 is ${ensure_ttys1} and if defined must be \'present\' or \'absent\'.")
  }

  case $::osfamily {
    'RedHat': {
      case $::operatingsystemrelease {
        /^5/: {
          $default_default_runlevel = 3
          $template                 = 'inittab/el5.erb'
        }
        /^6/: {
          $default_default_runlevel = 3
          $template                 = 'inittab/el6.erb'

          if $ensure_ttys1 {
            file { 'ttys1_conf':
              ensure => $ensure_ttys1,
              path   => '/etc/init/ttyS1.conf',
              source => 'puppet:///modules/inittab/ttyS1.conf',
              owner  => 'root',
              group  => 'root',
              mode   => '0644',
            }
          }

          if $ensure_ttys1 == 'present' {
            service { 'ttyS1':
              ensure     => running,
              hasstatus  => false,
              hasrestart => false,
              start      => '/sbin/initctl start ttyS1',
              stop       => '/sbin/initctl stop ttyS1',
              status     => '/sbin/initctl status ttyS1 | grep ^"ttyS1 start/running" 1>/dev/null 2>&1',
              require    => File['ttys1_conf'],
            }
          }
        }
        default: {
          fail("operatingsystemrelease is <${::operatingsystemrelease}> and inittab supports RedHat versions 5 and 6.")
        }
      }
    }
    'Debian': {
      if $::operatingsystem == 'Ubuntu' {

        $default_default_runlevel = 3
        $template                 = 'inittab/ubuntu.erb'

      } else {
        case $::operatingsystemmajrelease {
          '6': {
            $default_default_runlevel = 2
            $template                 = 'inittab/debian6.erb'
          }
          default: {
            fail("operatingsystemmajrelease is <${::operatingsystemmajrelease}> and inittab supports Debian version 6.")
          }
        }
      }
    }
    'Solaris': {
      case $::kernelrelease {
        '5.10': {
          $default_default_runlevel = 3
          $template                 = 'inittab/sol10.erb'
        }
        '5.11': {
          $default_default_runlevel = 3
          $template                 = 'inittab/sol11.erb'
        }
        default: {
          fail("kernelrelease is <${::kernelrelease}> and inittab supports Solaris versions 5.10 and 5.11.")
        }
      }
    }
    'Suse':{
      case $::operatingsystemrelease {
        /^10/: {
          $default_default_runlevel = 3
          $template                 = 'inittab/suse10.erb'
        }
        /^11/: {
          $default_default_runlevel = 3
          $template                 = 'inittab/suse11.erb'
        }
        default: {
          fail("operatingsystemrelease is <${::operatingsystemrelease}> and inittab supports Suse versions 10 and 11.")
        }
      }
    }
    default: {
      fail("osfamily is <${::osfamily}> and inittab module supports Debian, RedHat, Ubuntu, Suse, and Solaris.")
    }
  }

  if $default_runlevel == 'USE_DEFAULTS' {
    $default_runlevel_real = $default_default_runlevel
  } else {
    $default_runlevel_real = $default_runlevel
  }

  # validate default_runlevel_real
  validate_re($default_runlevel_real, '^[0-6sS]$', "default_runlevel <${default_runlevel_real}> does not match regex")

  if $::operatingsystem == 'Ubuntu' {
    file { 'rc-sysinit.override':
      ensure  => file,
      path    => '/etc/init/rc-sysinit.override',
      content => template($template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  } else {
    file { 'inittab':
      ensure  => file,
      path    => '/etc/inittab',
      content => template($template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }
}
