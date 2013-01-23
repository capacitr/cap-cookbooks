app = data_bag_item('apps', node[:app])
mysql = data_bag_item('passwords', 'mysql')

username = app["username"]
dbname = app["dbname"]
dbuser = app["dbuser"]
dbpass = app["dbpass"]
domains = app["domains"]
port = app["port"]
fixtures = app["fixtures"]

user username do
    home "/home/#{username}"
    shell "/bin/bash"
    action :create
end

directory "/home/#{username}" do
    owner username
    group username
end

directory "/home/#{username}/uploads" do
    owner username
    group username
end

execute "chown -R #{username}:#{username} /home/#{username}" do
    action :run
end

execute "apt-get update" do
    action :run
end

execute "echo mysql-server mysql-server/root_password password password |
debconf-set-selections" do
    action :run
end

execute "echo mysql-server mysql-server/root_password_again password password |
debconf-set-selections" do
    action :run
end

execute "apt-get install -qfy" do
    action :run
end

apt_packages = [
    "python-setuptools",
    "nginx",
    "python-dev",
    "libmysqlclient-dev",
    "mysql-server",
    "zlib1g-dev", 
    "libxml2",
    "libxslt1.1",
    "libxml2-dev",
    "libxslt1-dev",
    "libfreetype6-dev", 
    "liblcms1-dev",
    "libjpeg62-dev",
    "supervisor",
    "memcached",
    "libcurl3",
    "libcurl3-gnutls",
    "git-core",
    "unzip",
    "make",
    "ruby",
    "rubygems",
    "openjdk-6-jre-headless",
]


apt_packages.each do |package|
    execute "apt-get install -yq #{package}" do
        action :run 
    end
end


execute "wget -O /root/compiler-latest.zip http://closure-compiler.googlecode.com/files/compiler-latest.zip" do
    action :run
end

execute "unzip /root/compiler-latest.zip -d /root/compiler-latest" do
    action :run
    user "root"
    group "root"
    returns [0,1]
end

execute "mv /root/compiler-latest/compiler.jar /usr/bin/closure_compiler" do
    action :run
    user "root"
    group "root"
end

file "/usr/bin/closure_compiler" do
    mode 00755
    owner "root"
    group "root"
end


execute "easy_install virtualenv" do
    action :run
end

gem_package "fpm" do
    action :install
    ignore_failure true
end

execute "virtualenv --distribute /home/#{username}/venv" do
    action :run
    user username
    group username
    returns [0,1]
end

execute "pip install --index-url=https://simple.crate.io -r requirements.txt" do
    action :run
    cwd "/home/#{username}/site"
    user "root"
    group "root" 
    environment ({'PATH' => "/home/#{username}/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"})
    returns [0,1]
end

link "/home/#{username}/site" do
    to "/vagrant"
end

execute "chown -R #{username}:#{username} /home/#{username}/venv" do
    action :run
    user "root"
    group "root"
end

execute "python manage.py syncdb --noinput" do
    action :run
    cwd "/home/#{username}/site"
    environment ({'PATH' => "/home/#{username}/venv/bin:/usr/bin"})
    user username
    group username
end

execute "python manage.py migrate" do
    action :run
    cwd "/home/#{username}/site"
    environment ({'PATH' => "/home/#{username}/venv/bin"})
    user username
    group username
    returns [0,1]
end

fixtures.each do |fixture|
    execute "python manage.py loaddata #{fixture}" do
        action :run
        cwd "/home/#{username}/site"
        environment ({'PATH' => "/home/#{username}/venv/bin"})
        user username
        group username
    end
end

execute "python manage.py collectstatic --noinput" do
    action :run
    cwd "/home/#{username}/site"
    environment ({'PATH' => "/home/#{username}/venv/bin"})
    user username
    group username
end

execute "touch /home/#{username}/static/favicon.ico" do
    action :run
    user username
    group username
end

template "/etc/supervisor/conf.d/#{username}.conf" do
    variables({
        :user => username,
        :port => port,
        :domains => domains
    })
    source "supervisor.remote.conf.erb"
end

template "/etc/nginx/sites-available/#{username}" do
    source "site.conf.erb"
    action :create
    variables({
        :user => username,
        :port => port,
        :domains => domains 
    })
end

link "/etc/nginx/sites-enabled/#{username}" do
    to "/etc/nginx/sites-available/#{username}"
end

service "nginx" do
    action :reload
end


execute "supervisorctl restart" do
    action :run
end

