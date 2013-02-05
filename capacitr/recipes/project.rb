require 'json'

app = data_bag_item('apps', node[:app])
mysql = data_bag_item('passwords', 'mysql')

username = app["username"]
dbname = app["dbname"]
dbuser = app["dbuser"]
dbpass = app["dbpass"]
domains = app["domains"]
port = app["port"]

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

directory "/home/#{username}/static" do
    owner username
    group username
end

execute "touch /home/#{username}/static/favicon.ico" do
    action :run
    user username
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
    "node",
    "npm",
]


apt_packages.each do |package|
    execute "apt-get install -yq #{package}" do
        action :run 
    end
end


execute "easy_install virtualenv" do
    action :run
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

execute "chown -R #{username}:#{username} /home/#{username}/venv" do
    action :run
    user "root"
    group "root"
end

execute "mysql -u root -ppassword -e \"create database \\\`#{dbname}\\\`\"" do
    action :run
    returns [0,1]
end

execute "mysql -u root -ppassword -e 'GRANT ALL ON \`#{dbname}\`.* TO \`#{dbuser}\`@localhost IDENTIFIED BY \"#{dbpass}\";'" do
    action :run
end

execute "git clone git://github.com/creationix/nvm.git ~/.nvm" do
    action :run
    cwd "/home/#{username}/site"
    user username
    group username
end

execute "echo \"\n. ~/.nvm/nvm.sh\" >> .bashrc" do
    action :run
    cwd "/home/#{username}/site"
    user username
    group username
end

execute "nvm use v0.6.4" do
    action :run
    cwd "/home/#{username}/site"
    user username
    group username
end

execute "npm install" do
    action :run
    cwd "/home/#{username}/site"
end


template "/etc/nginx/sites-available/#{username}" do
    source "site.local.conf.erb"
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
    action :restart
end


