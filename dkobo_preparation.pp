exec { 'up_ug' :
	command => '/usr/bin/apt-get update && /usr/bin/apt-get -Vy upgrade && /usr/bin/puppet module install stankevich-python'
}

$packages = ['ntp', 'vim', 'wget', 'python-pip', 'python2.7-dev', 'libxml2', 'libxml2-dev', 'libxslt1-dev', 'curl', 'git', 'libffi-dev', 'libpq-dev', 'unzip']

package { $packages :
	ensure => 'installed',
	provider => 'apt',
	require => Exec['up_ug'],
	before => [Exec['machine_prep'], Exec['nodejs_1']]
}

exec { 'nodejs_1' :
	command => '/usr/bin/curl -sL https://deb.nodesource.com/setup_6.x | /bin/bash -'
}

package { 'nodejs' :
	ensure => 'installed',
	provider => 'apt',
	require => Exec['nodejs_1']
}

# Since this is a repeatable task which won't be skipped, we will be keeping such items commented out and only execut manifest files in a specific order to avoid repeats.
exec { 'machine_prep' :
	command => '/bin/rm --force /etc/timezone > /dev/null 2>&1 && /bin/echo "America/New_York" > /etc/timezone && /bin/systemctl restart cron.service'
}
