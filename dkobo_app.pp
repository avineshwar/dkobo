# Anything after a hash is considered as a comment.
# This file is tested to work on Debian Jessie x64 on AWS.
# Because the file is tested to work manually, a failure is usually because of a "Catch 22". Putting more constraint is a solution.
# Keeping the configurations as minimized and simplified as they can be is a solution to go with.

exec { 'git_download' :
	command      => '/usr/bin/wget https://github.com/humanprojectinc/dkobo/archive/master.zip && /usr/bin/unzip master.zip && /bin/mkdir /home/avineshwar/pykobo'# && /bin/chown avineshwar:avineshwar /home/avineshwar/pykobo'	
}

exec { 'set_env' :
	command      => '/bin/echo "export DEFAULT_KOBO_USER=admin" >> /home/avineshwar/.bashrc && /bin/echo "export DEFAULT_KOBO_PASS=pass" >> /home/avineshwar/.bashrc'
}

class { 'python' :
	version      => 'system', # because it is being installed by the preparation manifest.
	pip          => 'latest',
	dev          => 'latest',
	virtualenv   => 'latest'
}

# We can choose any user and group, however, that path should be an accessible one for that user.
python::virtualenv { 'pykobo' :
	ensure       => present,
	version      => 'system',
	requirements => '/home/avineshwar/dkobo-master/requirements.txt',
	systempkgs   => true,
	distribute   => false,
	venv_dir     => '/home/avineshwar/pykobo',
	owner        => 'avineshwar',
	group        => 'avineshwar',
	require      => [Exec['git_download'], Class['python']],
	before       => [Exec['npm'], Exec['bower']]
}

exec { 'npm' :
	cwd          => '/home/avineshwar/dkobo-master',
	command      => '/usr/bin/npm install --verbose && /usr/bin/npm install -g bower grunt coffee-script --verbose',
	require      => Exec['git_download']
}

exec { 'bower' :
	cwd          => '/home/avineshwar/dkobo-master',
	command       => '/usr/bin/bower install --allow-root -V',
	#command      => '/bin/su -l root -c "cd /home/avineshwar/dkobo-master/ && bower install --install-root -V"',
	require      => Exec['npm']
}

# needs root
exec { 'grunt' :
	cwd          => '/home/avineshwar/dkobo-master/',
	command      => '/usr/bin/grunt build -v',
	require      => Exec['bower']
}

exec { 'manage.py_1' :
	cwd          => '/home/avineshwar/dkobo-master',
	command      => '/home/avineshwar/pykobo/bin/python manage.py syncdb --noinput',
	require      => Exec['grunt']
}

exec { 'manage.py_2' :
        cwd          => '/home/avineshwar/dkobo-master',
        command      => '/home/avineshwar/pykobo/bin/python manage.py migrate',
        require      => Exec['manage.py_1']
}

exec { 'manage.py_3' :
        cwd          => '/home/avineshwar/dkobo-master',
        command      => '/home/avineshwar/pykobo/bin/python manage.py loaddata /surveys.json',
        require      => Exec['manage.py_2']
}

exec { 'manage.py_4' :
        cwd          => '/home/avineshwar/dkobo-master',
        command      => '/home/avineshwar/pykobo/bin/python manage.py gruntserver 0.0.0.0:8000', # need to check with "&"
        timeout      => 0,
	require      => [Exec['set_env'],Exec['manage.py_3']]
}
