=begin
 method: List_Templates.rb
 Description: Lists all images know to satellite6 
 Author: Laurent Domb <laurent@redhat.com>
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

require 'rest-client'
require 'json'
begin
  def log(level, msg, update_message=false)
    $evm.log(level,"#{msg}")
  end

  def dump_root()
    $evm.log(:info, "Begin $evm.root.attributes")
    $evm.root.attributes.sort.each { |k, v| log(:info, "\t Attribute: #{k} = #{v}")}
    $evm.log(:info, "End $evm.root.attributes")
    $evm.log(:info, "")
  end

# Sat6 admin user
$username = nil || $evm.object['username']

# Get Satellite password from model else set it here
$password = nil || $evm.object.decrypt('password')

url = nil || $evm.object['sat6url']
katello_url = nil || $evm.object['katellourl']
  
  ###############
  # Start Method
  ###############
  log(:info, "CloudForms Automate Method Started", true)
  dump_root()

  compute_resource_id = $evm.root['dialog_provider_ems_ref']
  

  def get_json(compute_resources)
    response = RestClient::Request.new(
        :method => :get,
        :url => compute_resources,
        :user => $username,
        :password => $password,
        :headers => { :accept => :json,
        :content_type => :json }
    ).execute
    results = JSON.parse(response.to_str)
  end

  computeresources = get_json(url+"compute_resources/#{compute_resource_id}")

  log(:info, "COMPUTE: #{computeresources}", true)
  
  provider = computeresources['provider']
  
  ## Build the templates has
  dialog_hash = {}
  
  if provider == "Vmware"
    
  computeresources["images"].each do | inner_hash |
    template = inner_hash["name"]
    dialog_hash["#{template}"] = "#{template}"
  end

  
elsif provider == "Ovirt"
  images = get_json(url+"compute_resources/#{compute_resource_id}/available_images")
  images.each do |images|
  dialog_hash[images['uuid']] = images['name']
  end
  else
  log(:info, "No templates defined", true)
  end

  if dialog_hash.blank?
    log(:info, "No Templates found")
    dialog_hash[nil] = "< No Templates found >"
  else
    $evm.object['default_value'],v = dialog_hash.first
    dialog_hash[nil] = '< choose a template >'
  end

  $evm.object["values"]     = dialog_hash
  log(:info, "$evm.object['values']: #{$evm.object['values'].inspect}")

  ###############
  # Exit Method
  ###############
  log(:info, "CloudForms Automate Method Ended", true)
  exit MIQ_OK

  # Set Ruby rescue behavior
rescue => err
  log(:error, "#{err.class} #{err}")
  log(:error, "#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
