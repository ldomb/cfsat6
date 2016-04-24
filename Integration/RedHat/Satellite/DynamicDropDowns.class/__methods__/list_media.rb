=begin
 method: List_Media.rb
 Description: Lists all media know to satellite6 
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


# Sat6 admin user
$username = nil || $evm.object['username']

# Get Satellite password from model else set it here
$password = nil || $evm.object.decrypt('password')

url = nil || $evm.object['sat6url']
katello_url = nil || $evm.object['katellourl']

operatingsystem_id =  $evm.root['dialog_operatingsystem_ems_ref']

def get_json(media)
    response = RestClient::Request.new(
        :method => :get,
        :url => media,
        :user => $username,
        :password => $password,
        :headers => { :accept => :json,
        :content_type => :json }
    ).execute
    results = JSON.parse(response.to_str)
end

def get_json(operatingsystems)
    response = RestClient::Request.new(
        :method => :get,
        :url => operatingsystems,
        :user => $username,
        :password => $password,
        :headers => { :accept => :json,
        :content_type => :json }
    ).execute
    results = JSON.parse(response.to_str)
end

operatingsystems = get_json(url+"operatingsystems/#{operatingsystem_id}")
operatingsystemslist = {}

osname = operatingsystems["fullname"]
medias = get_json(url+"media")
#ihash(media)
medialist = {}
medias['results'].each do | osmedia |
  id = osmedia['id']
  os = get_json(url+"media/#{id}")
  os["operatingsystems"].each do | osmedianame |
  fullname = osmedianame["fullname"]
  if "#{fullname}" == "#{osname}"
  medialist[osmedia['name']] = fullname
  end
  end
end


#$evm.object['default_value'] = medialist.first
medialist[nil] = '< choose your media >'

$evm.object['values'] = medialist.to_a
$evm.log(:info, "Dialog Values: #{$evm.object['values'].inspect}")
