# Anything after a hash is considered as a comment.
# This file is tested to work on Debian Jessie x64 on AWS.
# Several verbose flags have been turned on to assist in debugging.
# If the file fails with non-zero code, refer to the stdout.
# Because the file is tested to work manually, a failure is usually because of a "Catch 22". Putting more constraint is a solution.
# Keeping the configurations as minimized and simplified as they can be is a solution to go with.

######################################################################################################

    # this should be done before everything else i.e., everything waits for this.
    exec { 'apt-get update':
            command => '/usr/bin/apt-get update && /usr/bin/puppet module install stankevich-python && echo "export DEFAULT_KOBO_USER=admin" >> /root/.bashrc && echo "export DEFAULT_KOBO_PASS=pass" >> /root/.bashrc'
    }

    # this should wait for 'apt-get update', but, many things depend on this. This should be the second one to execute.
    $packages = ['default-jdk', 'python2.7-dev', 'libxml2', 'libxml2-dev', 'libxslt1-dev', 'libffi-dev', 'libpq-dev']

    package { $packages:
    ensure => 'installed',
    provider => 'apt',
    require => Exec['apt-get update'],
    before => Exec['node_install']#[Exec['pip_installs'], Exec['node_install']]
    #before => [Exec['docker_setup'], Exec['docker_compose'], Exec['ntpdate'], Package['docker-ce'], Exec['start_on_boot'], Service['nginx'], File[$doc_root]]
    }

    exec {'git_clone':
        cwd => '/root/',
        command => '/usr/bin/apt-get install -y git wget unzip && /usr/bin/wget https://github.com/humanprojectinc/dkobo/archive/master.zip && unzip master.zip',
        require => Exec['apt-get update']
    }

    exec { 'node_install':
            command => '/usr/bin/apt-get install -y curl && /usr/bin/curl -sL https://deb.nodesource.com/setup_6.x | bash - && /usr/bin/apt-get install -y nodejs',
            require => Exec['apt-get update']
    }

    exec { 'pip_initial':
	    command => '/usr/local/bin/pip install --upgrade pip && /usr/local/bin/pip install virtualenv && /usr/local/bin/pip install virtualenvwrapper',
	    require => Exec['apt-get update']
    }

    class { 'python' :
    version    => 'system',
    pip        => 'latest',
    dev        => 'latest',
    virtualenv => 'latest',
    before     => Exec['pip_initial'],
    require    => Exec['apt-get update']
  }

  # We can choose any user and group, however, that path should be an accessible one for that user.
    python::virtualenv { 'pykobo_venv' :
    ensure       => present,
    version      => 'system',
    requirements => '/root/dkobo-master/requirements.txt',
    systempkgs   => true,
    distribute   => false,
    venv_dir     => '/root/pykobo',
    owner        => 'root',
    group        => 'root',
    require      => Exec['git_clone']
  }

 # This should happen after the system update, installation of nodejs, and from the extracted directory
    exec { 'npm_install':
    cwd          => '/root/dkobo-master/',
    command      => '/usr/bin/npm install',
    require      => [Exec['apt-get update'], Exec['git_clone'], Exec['node_install']]
    }

 # This should happen after the system update, after git thing, installation of nodejs, after 'npm_install', and from the extracted directory
 # This is a sudo action, however, we are anyway running as root.
    exec { 'sudo_npm_install':
    cwd          => '/root/dkobo-master/',
    command      => '/usr/bin/npm install -g bower grunt coffee-script',
    require      => [Exec['apt-get update'], Exec['git_clone'], Exec['node_install'], Exec['npm_install']]
    }

 # This should happen after the system update, after git thing, installation of nodejs, after 'npm_install', after 'sudo_npm_install', and from the extracted directory
    exec { 'bower_install_grunt_build':
    cwd          => '/root/dkobo-master/',
    command      => '/usr/bin/bower install --allow-root && /usr/bin/grunt build',
    require      => [Exec['apt-get update'], Exec['git_clone'], Exec['node_install'], Exec['npm_install'], Exec['sudo_npm_install']]
    }

  # Is this even required?. I guess I misunderstood this. 
#    exec { 'surveys.json':
#    command      => '/bin/rm /root/surveys.json > /dev/null 2>&1;/usr/bin/touch /root/surveys.json',
#    }

  # This should happen after the system update, after git thing, installation of nodejs, after 'npm_install', after 'sudo_npm_install', after bower thing, and from the extracted directory
    exec { 'manage.py_syncdb':
    cwd          => '/root/dkobo-master/',
    command      => '/root/pykobo/bin/python manage.py syncdb --noinput',
    require      => [Exec['apt-get update'], Exec['git_clone'], Exec['node_install'], Exec['npm_install'], Exec['sudo_npm_install'], Exec['bower_install_grunt_build']]
    }

  # This should happen after the system update, after git thing, installation of nodejs, after 'npm_install', after 'sudo_npm_install', after bower thing, after manage.py thing, and from the extracted directory
    exec { 'manage.py_migrate':
    cwd          => '/root/dkobo-master/',
    command      => '/root/pykobo/bin/python manage.py migrate',
    require      => [Exec['apt-get update'], Exec['git_clone'], Exec['node_install'], Exec['npm_install'], Exec['sudo_npm_install'], Exec['bower_install_grunt_build'], Exec['manage.py_syncdb']]
    }

  # This should happen after the system update, after git thing, installation of nodejs, after 'npm_install', after 'sudo_npm_install', after bower thing, after 2 manage.py things, and from the extracted directory#after surveys thing
    exec { 'manage.py_loaddata':
    cwd          => '/root/dkobo-master/',
    command      => '/root/pykobo/bin/python manage.py loaddata /surveys.json',
    require      => [Exec['apt-get update'], Exec['git_clone'], Exec['node_install'], Exec['npm_install'], Exec['sudo_npm_install'], Exec['bower_install_grunt_build'], Exec['manage.py_syncdb']]#, Exec['surveys.json']]
    }

  # This should happen after the system update, after git thing, installation of nodejs, after 'npm_install', after 'sudo_npm_install', after bower thing, after 3 manage.py things,  and from the extracted directory#after surveys thing,
  # The required port is not open from the iptables yet.
    exec { 'manage.py_gruntserver':
    cwd          => '/root/dkobo-master/',
    command      => '/root/pykobo/bin/python gruntserver 0.0.0.0:8000 &',
    require      => [Exec['apt-get update'], Exec['git_clone'], Exec['node_install'], Exec['npm_install'], Exec['sudo_npm_install'], Exec['bower_install_grunt_build'], Exec['manage.py_syncdb'], Exec['manage.py_loaddata']]#, Exec['surveys.json']]
    }
