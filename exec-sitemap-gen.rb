# exec-sitemap-gen.rb : Console application that use sitemap-gen.rb library to generate sitemaps
# given an url.
#
# Author: Martin Lévesque (levesque dot martin at gmail dot com)
#
# Date: june 12th 2010
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; see the file COPYING.LIB.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require 'sitemap-gen'
require 'optparse'

class SitemapGeneratorConsole
	def initialize
		@cnt = 0
	end

	def new_link(link)
		@cnt += 1
		puts "[+] #{link} [#{@cnt} links yet]"
	end

	def report_exception(exception)
	end
end

def usage()
	puts "Usage: ruby exec-sitemap-gen.rb -u <URL> [-n nb_per_sitemap] [-p prefix_sitemap_filenames] [-i idle_time (timeout between requests)] [--without_wget true|false] [--verbose true|false]"
	exit
end

options = {}
 
begin
	optparse = OptionParser.new do|opts|
		options[:main_url] = nil

		opts.on( '-u', '--url URL', 'Main url to scan' ) do|url|
			options[:main_url] = url
		end

		options[:nb_urls_per_sitemap] = 50000

		opts.on( '-n', '--nb NB_URLS', 'Nb urls per sitemap' ) do|n|
			options[:nb_urls_per_sitemap] = n.to_i
		end

		options[:prefix] = "sitemap_"

		opts.on( '-p', '--prefix Prefix', 'Prefix of the sitemap filenames' ) do|prefix|
			options[:prefix] = prefix
		end

		options[:idle_time] = 1

		opts.on( '-i', '--idle_time Timeout', 'Time between requests (in seconds)' ) do|idle_time|
			options[:idle_time] = idle_time
		end

		options[:without_wget] = false

		opts.on( '--without_wget', '--without_wget true|false', 'Use internal mode for URI derefencing or wget' ) do|without_wget|
			options[:without_wget] = without_wget == "true" ? true : false
		end

		options[:verbose] = false

		opts.on( '--verbose', '--verbose true|false', 'Verbose' ) do|verbose|
			options[:verbose] = verbose == "true" ? true : false
		end
	end

	optparse.parse!
rescue
	usage()
end

if ! options[:main_url]
	usage()
end

sitemap_gen_console = SitemapGeneratorConsole.new

sitemap_gen = SitemapGenerator.new(options[:main_url], sitemap_gen_console, 
			options[:nb_urls_per_sitemap], options[:prefix], options[:idle_time], options[:without_wget],
			options[:verbose])

sitemap_gen.run

