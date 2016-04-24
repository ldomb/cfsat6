=begin
 method: create_sat6_vm.rb
 Description: Creates an image host in satellite6
 Author: Laurent Domb <laurent@redhat.com>
 Modifications: Patrick Rutledge <prutledg@redhat.com>
 License: GPL v3

 Note: Currently works for VMware and RHEV.
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

$evm.log(:info, "----------------------Begin Create_Sat6_VM_WP-------------------------")

require 'rest-client'
require 'json'

# Sat6 admin user
$username = nil || $evm.object['username']

# Get Satellite password from model else set it here
$password = nil || $evm.object.decrypt('password')

$url = nil || $evm.object['sat6url']

def post_json(url, json_data)
  $evm.log(:info,"POST_URL(#{url})")
  $evm.log(:info,"POST_DATA(#{json_data})")
  response = RestClient::Request.new(
    :method => :post,
    :url => url,
    :user => $username,
    :password => $password,
    :headers => { :accept => :json,
    :content_type => :json},
    :timeout => 90000000,
    :payload => json_data
  ).execute
  $evm.log(:info,"POST_JSON_OUT(#{response.to_str})")
  return JSON.parse(response.to_str)
end

def get_json(url)
  $evm.log(:info,"GET_URL(#{url})")
  response = RestClient::Request.new(
    :method => :get,
    :url => url,
    :user => $username,
    :password => $password,
    :headers => { :accept => :json,
    :content_type => :json }
  ).execute
  $evm.log(:info,"GET_JSON_OUT(#{response.to_str})")
  return JSON.parse(response.to_str)
end

#$evm.root.attributes.sort.each { |k, v| $evm.log(:info,"Root:<$evm.root> Attributes - #{k}: #{v}")}

compute_resource_id = $evm.root['dialog_provider_ems_ref']
hostname = $evm.root['dialog_name_ems_ref']
hostgroup_id = $evm.root['dialog_hostgroup_ems_ref']
organization_id = $evm.root['dialog_organization_ems_ref']
location_id =  $evm.root['dialog_location_ems_ref']
memory =  $evm.root['dialog_memory_ems_ref']
cpus =  $evm.root['dialog_cpus_ems_ref']
corespersocket =  $evm.root['dialog_corespersocket_ems_ref']
#cluster = $evm.root['dialog_cluster_ems_ref']
#datacenter = $evm.root['dialog_datacenter_ems_ref']
network =  $evm.root['dialog_vmnetwork_ems_ref']
disksize =  $evm.root['dialog_disksize_ems_ref']
datastore = $evm.root['dialog_datastore_ems_ref']
db_host =  $evm.root['dialog_db_host_ems_ref']

computeresources = get_json($url+"compute_resources/#{compute_resource_id}")
provider = computeresources['provider'].to_s
$evm.log(:info,"PROVIDER(#{provider})")

ds_hash = {}
datastores = get_json($url+"compute_resources/#{compute_resource_id}/available_storage_domains")
datastores["results"].each do | inner_hash |
  ds_hash[inner_hash['id']] = inner_hash['name']
end
k,datastore = ds_hash.first

# Oh the pain make it stop puppet
def getlkid(puppetmod, smcp)
  pclasses = get_json($url+"puppetclasses?per_page=99")
  pclasses['results'].each do | pclass |
    pclass.each do | psub |
      if psub.kind_of?(Array)
        psub.each do | psubsub |
          if psubsub['name'] == puppetmod
            psubid = psubsub['id']
            smartclasses = get_json($url+"puppetclasses/#{psubid}")
            smartclasses['smart_class_parameters'].each do | sclass |
              sc = sclass['parameter'].to_s
              if sc == smcp
                return sclass['id']
                break
              end
             end
           break
          end
        end
      end
    end
  end
end

provtype = $evm.root['dialog_provtype_ems_ref']

if provtype == "template"
  method = "image"
else
  method = "build"
end

jsh={
  "host" => {
    "compute_resource_id" => compute_resource_id,
    "name" => hostname,
    "hostgroup_id" => hostgroup_id,
    "organization_id" => organization_id,
    "location_id" => location_id,
    "managed" => "true",
    "provision_method" => method,
    "build" => "1",
    "enabled" => "1",
    "ip" => nil,
    "subnet_id" => "1",
    "interfaces_attributes"=>{
      "new_interfaces"=>{
        "_destroy"=>"false",
        "type"=>"Nic::Managed",
        "mac"=>"",
        "identifier"=>"",
        "name"=>"",
        "domain_id"=>"",
        "subnet_id"=>"",
        "ip"=>"",
        "managed"=>"1",
        "virtual"=>"0",
        "tag"=>"",
        "attached_to"=>""
      }
    }
  }
}

network_hash = {}

if provider == "Vmware"
  $evm.log(:info,"Provider is VMware")
  networks = get_json($url+"compute_resources/#{compute_resource_id}/available_networks")
  networks["results"].each do | inner_hash |
    network_hash[inner_hash['id']] = inner_hash['name']
  end
  network,v = network_hash.first
  jsh["host"]["compute_attributes"] = {
    "cpus" => cpus,
    "corespersocket" => corespersocket,
    "memory_mb" => memory,
    "cluster" => "Cluster01",
    "path"=>"/Datacenters/DC01/vm",
    "guest_id" => "rhel6_64Guest",
    "hardware_version"=>"Default",
    "interfaces_attributes" => {
      "new_interfaces" => {
        "type" => "VirtualE1000",
        "network" => network,
        "_delete" => ""
      },
      "0" => {
        "type" => "VirtualE1000",
        "network" => network,
        "_delete" => ""
      }
    },
    "volumes_attributes" => {
      "new_volumes" => {
        "datastore" => datastore,
        "name" => "Hard disk",
        "size_gb" => disksize,
        "thin" => "true",
        "eager_zero"=>"false",
        "_delete" => ""
      },
      "0" => {
        "datastore" => datastore,
        "name" => "Hard disk",
        "size_gb" => disksize,
        "thin" => "true",
        "eager_zero"=>"false",
        "_delete" => ""
      }
    },
    "scsi_controller_type" => "VirtualLsiLogicController",
    "start" => "1"
  }
  if provtype == "template"
    jsh["host"]["compute_attributes"]["image_id"] = "Templates/rhel7.1"
  end
elsif provider == "Ovirt"
  cluster_hash = {}
  $evm.log(:info,"Provider is RHEV")
  clusters = get_json($url+"compute_resources/#{compute_resource_id}/available_clusters")
  clusters["results"].each do | inner_hash |
    clusterid = inner_hash["id"]
    $evm.log(:info, "Found cluster (#{inner_hash['name']})")
    cluster_hash[:id] = "#{clusterid}"
    networks = get_json($url+"compute_resources/#{compute_resource_id}/available_clusters/#{cluster_hash[:id]}/available_networks")
    networks["results"].each do | net |
      network_hash[net['id']] = net['name']
    end
  end
  network,v = network_hash.first
  totcpu = cpus.to_i * corespersocket.to_i
  memsize = memory.to_i * 1024 * 1024
  number1 = rand.to_s[2..14]
  jsh["host"]["compute_attributes"] = {
    "start" => "1",
    "cores" => totcpu,
    "memory" => memsize,
    "interfaces_attributes" => {
      "new_interfaces" => {
        "name" => "",
        "network" => network,
        "_delete" => ""
      },
      "new_#{number1}" => {
        "name" => "eth0",
        "network" => network,
        "_delete" => ""
      }
    },
    "volumes_attributes" => {
      "new_volumes" => {
        "size_gb" => "",
        "_delete" => "",
        "preallocate"=>"0",
        "id" => ""
      }
    }
  }
  if provtype == "template"
    jsh["host"]["compute_attributes"]["image_id"] = "7f4f25e2-0a43-4d2f-a715-c2c6c8edbe86"
  end
else
  $evm.log(:info,"Failure: Provider Unknown! (#{provider})")
  exit MIQ_ABORT
end

nh = post_json($url+"hosts", jsh.to_json)

fqdn = nh["name"]
$evm.root['hostname']=fqdn

scid = getlkid("wordpress","db_host")

scu = {
  "match" => "fqdn=#{fqdn}",
  "value" => db_host,
  "use_puppet_default" => false
}

post_json($url+"smart_class_parameters/#{scid}/override_values", scu.to_json)


exit MIQ_OK
