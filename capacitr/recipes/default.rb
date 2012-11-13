user node["new_user"] do
    home "/home/%s" % node["new_user"]
    shell "/bin/zsh"
    action :create
end

directory "/home/%s" % node["new_user"] do
    owner node["new_user"] 
    group node["new_user"]
end

directory "/home/%s/static" % node["new_user"] do
    owner node["new_user"] 
    group node["new_user"]
end

link "/home/%s/site" % node["new_user"] do
    to "/vagrant"
    owner node["new_user"]
    group node["new_user"]
end

directory "/home/%s/uploads" % node["new_user"] do
    owner node["new_user"] 
    group node["new_user"]
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
    "libfreetype6-dev", 
    "liblcms1-dev",
    "libjpeg62-dev",
    "supervisor",
    "zsh",
    "git-core"
]


apt_packages.each do |package|
    execute "apt-get install -yq #{package}" do
        action :run 
    end
end
execute "easy_install virtualenv" do
    action :run
end

execute "virtualenv /home/%s/venv" % node["new_user"] do
    action :run
    user node[:new_user]
    group node[:new_user]
    returns [0,1]
end

node[:python_packages].each do |package|
    execute "pip install #{package}" do
        action :run
        cwd "/home/%s/site" % node[:new_user]
        user node[:new_user]
        group node[:new_user]
        environment ({'PATH' => '/home/%s/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' % node["new_user"]})
    end
end

template "/etc/nginx/sites-available/%s.conf" % node["new_user"] do
    source "site.conf.erb"
end

link "/etc/nginx/sites-enabled/%s.conf" % node["new_user"] do
    to "/etc/nginx/sites-available/%s.conf" % node["new_user"]
end

service "nginx" do
    action :restart
end

template "/etc/supervisor/conf.d/%s.conf" % node["new_user"] do
    source "supervisor.conf.erb"
end

service "supervisor" do
    action :restart
end

execute "mysql -u root -ppassword -e \"create database %s\"" % node["dbname"] do
    action :run
    returns [0, 1]
end

execute "mysql -u root -ppassword -e 'GRANT ALL ON \`%s\`.* TO \`%s\`@localhost IDENTIFIED BY \"%s\";'" % [node[:dbname], node[:dbuser], node[:dbpass]] do
    action :run
end

execute "python manage.py syncdb --noinput --database=%s" % node[:dbhost] do
    action :run
    cwd "/home/%s/site" % node["new_user"]
    environment ({'PATH' => '/home/%s/venv/bin:/usr/bin' % node["new_user"]})
    user node["new_user"]
    group node["new_user"]
end

execute "python manage.py migrate --database=%s" % node[:dbhost] do
    action :run
    cwd "/home/%s/site" % node["new_user"]
    environment ({'PATH' => '/home/%s/venv/bin' % node["new_user"]})
    user node["new_user"]
    group node["new_user"]
    returns [0,1]
end

execute "python manage.py loaddata fixtures/sites.yaml --database=%s" % node[:dbhost] do
    action :run
    cwd "/home/%s/site" % node["new_user"]
    environment ({'PATH' => '/home/%s/venv/bin' % node["new_user"]})
    user node["new_user"]
    group node["new_user"]
end

execute "python manage.py loaddata fixtures/admin.yaml --database=%s" % node[:dbhost] do
    action :run
    cwd "/home/%s/site" % node["new_user"]
    environment ({'PATH' => '/home/%s/venv/bin' % node["new_user"]})
    user node["new_user"]
    group node["new_user"]
end

execute "python manage.py collectstatic --noinput" do
    action :run
    cwd "/home/%s/site" % node["new_user"]
    environment ({'PATH' => '/home/%s/venv/bin' % node["new_user"]})
    user node["new_user"]
    group node["new_user"]
end


