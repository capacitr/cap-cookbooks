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
    "mysql-server",
    "libmysqlclient-dev",
    "libmysqlclient16",
    "libmysqlclient16-dev",
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
    returns [0,1]
end

python_packages = [
    "Django==1.4.2",
    "pyyaml",
    "MySQL-python",
    "PIL==1.1.7",
    "South==0.7.6",
    "argparse==1.2.1",
    "cropresize==0.1.6",
    "distribute==0.6.30",
    "django-autocomplete==1.0.dev49",
    "django-thumbnail-works==0.2.3",
    "gunicorn==0.15.0",
    "wsgiref==0.1.2",
    "-e git+https://github.com/tschellenbach/Django-facebook.git#egg=django_facebook"
    ]

python_packages.each do |package|
    execute "pip install #{package}" do
        action :run
        environment ({'PATH' => '/home/%s/venv/bin:/usr/bin' % node["new_user"]})

    end
end

template "/etc/nginx/sites-available/%s.conf" % node["new_user"] do
    source "site.conf.erb"
    variables(
        :domains => node[:domains],
        :user => node[:new_user],
        :port => node[:port] 
    )
end

link "/etc/nginx/sites-enabled/%s.conf" % node["new_user"] do
    to "/etc/nginx/sites-available/%s.conf" % node["new_user"]
end

service "nginx" do
    action :reload
end

template "/etc/supervisor/conf.d/%s.conf" % node["new_user"] do
    source "supervisor.conf.erb"
    variables(
        :user => node[:new_user],
        :port => node[:port],
        :new_port => node[:new_port]
    )
end

service "supervisor" do
    action :restart
end

execute "chown -R %s:%s /home/%s/venv" % [node["new_user"], node["new_user"], node["new_user"]] do
    action :run
end

execute "mysql -u root -ppassword -e \"create database %s\"" % node["dbname"] do
    action :run
    returns [0, 1]
end

execute "mysql -u root -ppassword -e \"GRANT ALL ON capacitr_moooink2.* TO
capacitr_moooink@localhost IDENTIFIED BY '06d8e1c3';\"" do
    action :run
end


execute "python manage.py syncdb --noinput" do
    action :run
    cwd "/home/%s/site" % node["new_user"]
    environment ({'PATH' => '/home/%s/venv/bin' % node["new_user"]})
    user node["new_user"]
    group node["new_user"]
end

execute "python manage.py migrate" do
    action :run
    cwd "/home/%s/site" % node["new_user"]
    environment ({'PATH' => '/home/%s/venv/bin' % node["new_user"]})
    user node["new_user"]
    group node["new_user"]
end

execute "python manage.py loaddata fixtures/sites.yaml" do
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



