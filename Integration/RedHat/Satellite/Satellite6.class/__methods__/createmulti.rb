=begin
 method: createmulti.rb
 Description: Creates a full stack of vm or baremetal via sat6
 Author: Laurent Domb <laurent@redhat.com>
 Modifications: Patrick Rutledge <prutledg@redhat.com>
 License: GPL v3 
-------------------------------------------------------------------------------
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------
=end
begin
  
require 'rest-client'
require 'json'
  
$evm.log(:info, "----------------------Begin CreateMulti-------------------------")
  
# Sat6 admin user
$emsusername = nil || $evm.object['cfmeusername']

# Get Satellite password from model else set it here
$emspassword = nil || $evm.object.decrypt('passwordems')

$emsurl = nil || $evm.object['emsurl']

# Sat6 admin user
$username = nil || $evm.object['username']

# Get Satellite password from model else set it here
$password = nil || $evm.object.decrypt('password')

url = nil || $evm.object['sat6url']

def post_json(url, username, password, json_data)
    $evm.log(:info, "POST_URL(#{url})")
    $evm.log(:info, "POST_DATA(#{json_data})")
    response = RestClient::Request.new(
        :method => :post,
        :url => url,
        :user => username,
        :password => password,
        :verify_ssl => false,
        :headers => { :accept => :json,
        :content_type => :json},
        :payload => json_data
    ).execute
    results = JSON.parse(response.to_str)
end

def get_json(url, username, password)
    $evm.log(:info, "GET_URL(#{url})")
    response = RestClient::Request.new(
        :method => :get,
        :url => url,
        :user => username,
        :password => password,
        :verify_ssl => false,
        :headers => { :accept => :json,
        :content_type => :json }
    ).execute
    results = JSON.parse(response.to_str)
end

def get_fqdn(hostname,url)
    hostname = hostname
  domains = get_json(url+"domains/1", $username, $password)
    fqdn = "#{hostname}.#{domains['name']}"
    return fqdn
end

def get_status(fqdn,url)
  retries = 0
  loop do
    begin
      status = get_json(url+"hosts/#{fqdn}/status", $username, $password)
      $evm.log(:info, "#{fqdn} #{status['status']}")
      if "#{status['status']}" != "Pending Installation"
        $evm.log(:info, "#{fqdn} checking reports ")
        report = get_json(url+"hosts/#{fqdn}/reports/last", $username, $password)
        if "#{report['host_name']}" == "#{fqdn}"
        break
        end
      end
    rescue
      break if retries==20
      $evm.log(:info, "#{fqdn} No reports yet")
      retries+=1
    ensure
      sleep 30
    end
  end
end



#$evm.root.attributes.sort.each { |k, v| $evm.log(:info,"Root:<$evm.root> Attributes - #{k}: #{v}")}

#Satellite
organization_id = $evm.root['dialog_organization_ems_ref']
location_id = $evm.root['dialog_location_ems_ref']

#WORDPRESS
wp1_name = $evm.root['dialog_wordpress1_name_ems_ref']
wp1_memory = $evm.root['dialog_wp1_memory_ems_ref']
wp1_disksize = $evm.root['dialog_wp1_disksize_ems_ref']
wp1_provider = $evm.root['dialog_provider_wp1_ems_ref']
wp1_hostgroup = $evm.root['dialog_hostgroup_wp1_ems_ref']
wp1_cpus = $evm.root['dialog_wp1_cpus_ems_ref']
wp1_cores = $evm.root['dialog_wp1_corespersocket_ems_ref']
wp1_provtype = $evm.root['dialog_wp1_provtype_ems_ref']
#
wp2_name = $evm.root['dialog_wordpress2_name_ems_ref']
wp2_memory = $evm.root['dialog_wp2_memory_ems_ref']
wp2_disksize = $evm.root['dialog_wp2_disksize_ems_ref']
wp2_provider = $evm.root['dialog_provider_wp2_ems_ref']
wp2_hostgroup = $evm.root['dialog_hostgroup_wp2_ems_ref']
wp2_cpus = $evm.root['dialog_wp2_cpus_ems_ref']
wp2_cores = $evm.root['dialog_wp2_corespersocket_ems_ref']
wp2_provtype = $evm.root['dialog_wp2_provtype_ems_ref']

#MYSQL config
mysql_name = $evm.root['dialog_mysql_name_ems_ref']
mysql_memory = $evm.root['dialog_mysql_memory_ems_ref']
mysql_disksize = $evm.root['dialog_mysql_disksize_ems_ref']
mysql_provider = $evm.root['dialog_provider_mysql_ems_ref']
mysql_hostgroup = $evm.root['dialog_hostgroup_mysql_ems_ref']
mysql_cpus = $evm.root['dialog_mysql_cpus_ems_ref']
mysql_cores = $evm.root['dialog_mysql_corespersocket_ems_ref']
mysql_provtype = $evm.root['dialog_mysql_provtype_ems_ref']

#HAPROXY
haproxy_name = $evm.root['dialog_haproxy_name_ems_ref']
haproxy_memory = $evm.root['dialog_haproxy_memory_ems_ref']
haproxy_disksize = $evm.root['dialog_haproxy_disksize_ems_ref']
haproxy_provider = $evm.root['dialog_provider_haproxy_ems_ref']
haproxy_hostgroup = $evm.root['dialog_hostgroup_haproxy_ems_ref']
haproxy_cpus = $evm.root['dialog_haproxy_cpus_ems_ref']
haproxy_cores = $evm.root['dialog_haproxy_corespersocket_ems_ref']
haproxy_provtype = $evm.root['dialog_haproxy_provtype_ems_ref']

sat_catalog = "Satellite Based"

svccatalogs = get_json($emsurl+"service_catalogs?expand=resources&filter%5B%5D=", $emsusername, $emspassword)

svccatid=""

svccatalogs['resources'].each do | catalog |
  $evm.log(:info, "Found catalog #{catalog['name']} #{catalog['id']}")
  if catalog['name'] == sat_catalog && catalog['id'] != ""
    svccatid = catalog['id']
    break
  end
end

if svccatid == ""
  $evm.log(:info, "ERROR: No such catalog (#{sat_catalog})")
  exit MIQ_ABORT
end

svccatalog = get_json($emsurl+"service_catalogs/#{svccatid}/service_templates?attributes=id%2Cname&expand=resources&filter%5B%5D=", $emsusername, $emspassword)

svccatalog['resources'].each do | resource |
  $evm.log(:info, "Found resource #{resource['name']} #{resource['id']}")
  id = resource['id']
  name = resource['name']
  if name == "Satellite6-HAProxy"
    $haproxyid = id
  elsif name == "Satellite6-WP"
    $wpid = id
  elsif name == "Satellite6-Mysql"
    $mysqlid = id
  end
end

post_json($emsurl+"service_catalogs/#{svccatid}/service_templates", $emsusername, $emspassword, JSON.generate({
                                       "action"             => "order",
                                       "service_name"       => "wp1",
                                       "href"               => $emsurl+"services_templates/#{$wpid}",
                                       "name_ems_ref"       => wp1_name,
                                       "memory_ems_ref"     => wp1_memory,
                                       "disksize_ems_ref"   => wp1_disksize,
                                       "provider_ems_ref"   => wp1_provider,
                                       "location_ems_ref"   => location_id,
                                       "organization_ems_ref" => organization_id,
                                       "hostgroup_ems_ref"  => wp1_hostgroup,
                                       "cpus_ems_ref" => wp1_cpus,
                                       "corespersocket_ems_ref" => wp1_cores,
                                       "provtype_ems_ref" => wp1_provtype,
                                       "db_host_ems_ref"    => mysql_name
}))

post_json($emsurl+"service_catalogs/#{svccatid}/service_templates", $emsusername, $emspassword, JSON.generate({
                                       "action"             => "order",
                                       "service_name"       => "wp2",
                                       "href"               => $emsurl+"services_templates/#{$wpid}",
                                       "name_ems_ref"       => wp2_name,
                                       "memory_ems_ref"     => wp2_memory,
                                       "disksize_ems_ref"   => wp2_disksize,
                                       "provider_ems_ref"   => wp2_provider,
                                       "location_ems_ref"   => location_id,
                                       "organization_ems_ref" => organization_id,
                                       "hostgroup_ems_ref"  => wp2_hostgroup,
                                       "cpus_ems_ref"       => wp2_cpus,
                                       "corespersocket_ems_ref" => wp2_cores,
                                       "provtype_ems_ref" => wp2_provtype,
                                       "db_host_ems_ref"    => mysql_name
                                       }))

post_json($emsurl+"service_catalogs/#{svccatid}/service_templates", $emsusername, $emspassword, JSON.generate({
                                       "action"             => "order",
                                       "service_name"       => "haproxy",
                                       "href"               => $emsurl+"services_templates/#{$haproxyid}",
                                       "name_ems_ref"       => haproxy_name,
                                       "memory_ems_ref"     => haproxy_memory,
                                       "disksize_ems_ref"   => haproxy_disksize,
                                       "provider_ems_ref"   => haproxy_provider,
                                       "location_ems_ref"   => location_id,
                                       "organization_ems_ref" => organization_id,
                                       "hostgroup_ems_ref"  => haproxy_hostgroup,
                                       "cpus_ems_ref"       => haproxy_cpus,
                                       "corespersocket_ems_ref" => haproxy_cores,
                                       "provtype_ems_ref" => haproxy_provtype,
                                       "hostname_wordpress0_ems_ref" => wp1_name,
                                       "hostname_wordpress1_ems_ref" => wp2_name
                                       }))

post_json($emsurl+"service_catalogs/#{svccatid}/service_templates", $emsusername, $emspassword, JSON.generate({
                                       "action"             => "order",
                                       "service_name"       => "mysql",
                                       "href"               => $emsurl+"services_templates/#{$mysqlid}",
                                       "name_ems_ref"       => mysql_name,
                                       "memory_ems_ref"     => mysql_memory,
                                       "provider_ems_ref"   => mysql_provider,
                                       "location_ems_ref"   => location_id,
                                       "organization_ems_ref" => organization_id, 
                                       "hostgroup_ems_ref"  => mysql_hostgroup,
                                       "disksize_ems_ref"   => mysql_disksize,
                                       "cpus_ems_ref"       => mysql_cpus,
                                       "corespersocket_ems_ref" => mysql_cores,
                                       "provtype_ems_ref" => mysql_provtype,
                                       }))

exit MIQ_OK


rescue => err
		$evm.log("info", "[#{err}]\n#{err.backtrace.join("\n")}")
		exit MIQ_STOP
end

