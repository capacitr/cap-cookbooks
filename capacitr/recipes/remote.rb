apps = data_bag('apps')
mysql = data_bag_item("passwords", "mysql")
mysql_password = mysql["password"]

apps.each do |app|
    new_user = data_bag_item('apps', app)

    username = new_user["username"]
    dbname   = new_user["dbname"]
    dbuser   = new_user["dbuser"]
    dbpass   = new_user["dbpass"]
    port     = new_user["port"]
    domains  = new_user["domains"]

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

    template "/etc/supervisor/conf.d/#{username}.conf" do
        variables({
            :user => username,
            :port => port,
            :domains => domains
        })
        source "supervisor.remote.conf.erb"
    end

    execute "supervisorctl reread" do
        action :run
    end

    execute "mysql -u root -p#{mysql_password} -e \"create database \\\`#{dbname}\\\`\"" do
        action :run
        returns [0,1]
    end

    execute "mysql -u root -p#{mysql_password} -e 'GRANT ALL ON \`#{dbname}\`.* TO \`#{dbuser}\`@localhost IDENTIFIED BY \"#{dbpass}\";'" do
        action :run
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

    link "/etc/nginx/sites-enabled/#{username}.conf" do
        to "/etc/nginx/sites-available/#{username}.conf"
    end

    service "nginx" do
        action :reload
    end
end

#
#execute "apt-get update" do
#    action :run
#end
#
#execute "apt-get install -qfy" do
#    action :run
#end
#
#apt_packages = [
#    "python-setuptools",
#    "nginx",
#    "python-dev",
#    "libmysqlclient-dev",
#    "mysql-server",
#    "zlib1g-dev", 
#    "libxml2",
#    "libxslt1.1",
#    "libxml2-dev",
#    "libxslt1-dev",
#    "libfreetype6-dev", 
#    "liblcms1-dev",
#    "libjpeg62-dev",
#    "supervisor",
#    "memcached",
#    "libcurl3",
#    "libcurl3-gnutls",
#    "git-core",
#    "unzip",
#    "make",
#    "ruby",
#    "rubygems",
#    "openjdk-6-jre-headless",
#]
#
#
#apt_packages.each do |package|
#    execute "apt-get install -yq #{package}" do
#        action :run 
#    end
#end
#
##
##execute "wget -O /root/compiler-latest.zip http://closure-compiler.googlecode.com/files/compiler-latest.zip" do
##    action :run
##end
##
##execute "unzip /root/compiler-latest.zip -d /root/compiler-latest" do
##    action :run
##    user "root"
##    group "root"
##end
##
##execute "mv /root/compiler-latest/compiler.jar /usr/bin/closure_compiler" do
##    action :run
##    user "root"
##    group "root"
##end
##
##file "/usr/bin/closure_compiler" do
##    mode 00755
##    owner "root"
##    group "root"
##end
##
#

