# sitemap-gen.rb
#
# Author: Martin Lévesque (levesque dot martin at gmail dot com)
# Date: june 12th 2010
# Version: v 0.5
# See also: http://sourceforge.net/projects/rsitemapgen/
#
# Modified: December 22nd 2010
#   Author: Bob Ferris
#   Version: v 0.6
#   See also: http://smiy.svn.sourceforge.net/viewvc/smiy/remote-sitemap/
#             http://sourceforge.net/projects/smiy/
#             http://smiy.wordpress.com/
#   Usage: see README
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

require 'net/http'
require 'uri'
require 'set'
require 'date'

class SitemapGenerator
	def initialize(main_url, view = nil, nb_urls_per_sitemap = 50000, prefix_sitemap_filenames = "sitemap_", 
			idle_time = 2, without_wget = false, verbose = false)

		@view = view
		@nb_urls_per_sitemap = nb_urls_per_sitemap
		@prefix_sitemap_filenames = prefix_sitemap_filenames
		@idle_time = idle_time
		@without_wget = without_wget
		@verbose = verbose

		if main_url[main_url.length-1, 1] == "/"
			main_url = main_url[0..(main_url.length - 1)]
		end

		# please add here further main URLs e.g., PURL servers
		@main_urls = [main_url,"http://purl.org"]
		@main_url = main_url

		# Make sur there is http://www...
		if @main_url.index("http://").nil?
			url_www = URI.parse(@main_url)
			new_url = "http://#{url_www.host}#{url_www.path}"
			
			@main_urls << new_url
		end

		# SSL support
		if ! without_wget
			tmp_main = @main_urls.clone

			tmp_main.each do |url|
				@main_urls << url.gsub("http://", "https://")
			end
		end

		@links = Set.new []
		@visited = Set.new []
		@good_links = Set.new []
	end

	# collects the links at url
	def get_links(url)
		links = Set.new []

		begin
			content_a = get_content(url)
			# puts 'here'
			if content_a.to_a()[0] != "url"
		    # puts 'there with ' + content_a.to_a()[0]
		    url = content_a.to_a()[0]
		    content = content_a.to_a()[1]
		    
        # don't forget to add the document URI itself
		    # this is important, if this URI isn't mentioned in the content somewhere
		    if (! url.index(@main_url).nil?) && content.index(" href=\"")
		      parsed_url = URI.parse(url)
		      html_u = parsed_url.scheme + "://" + parsed_url.host + parsed_url.path
		      puts 'add html document uri ' + html_u
		      links.add(html_u)
		    end
		    
			  while content.index(" href=\"")
			    i_href = content.index(" href=\"")
			    
			    l_href = content.index("\"", i_href + 7)
			    
			    if i_href && l_href
			      link = content[(i_href+7)..(l_href-1)]
			      content = content.gsub(content[i_href..l_href], "")
			      link = fix_link(link, url)
			      
			      if contains_main_url(link)
			        # puts 'add link ' + link
			        u = URI.parse(link)
			        document_u = u.scheme + "://" + u.host + u.path
			        if ! document_u.index(@main_url).nil?
			          # puts 'add document uri ' + document_u
			        end
			        links.add(document_u)
			      end
			    end
			  end
		  end 
		rescue => e
			if @view
				@view.report_exception(e)
			end
		end

		return links
	end

	# find the next links not visited yet.
	def next_not_visited(links, visited)
		links.each do |l|
			if ! visited.include?(l)
				return l
			end
		end

		return nil
	end

	# generates the sitemap of selected urls.
	def generate_sitemap(urls, sitemap_id)
		sitemap = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"

		urls.each do |url|

			url = url.gsub("&", "&amp;")
		
			sitemap += "<url><loc>#{url}</loc><lastmod>#{Time.now.strftime("%Y-%m-%d")}</lastmod><changefreq>daily</changefreq><priority>1.0</priority></url>\n"
		end

		sitemap += "</urlset>"

		File.open("#{@prefix_sitemap_filenames}#{sitemap_id}.xml", 'w') {|f| f.write(sitemap) }
	end

	# generates all sitemaps given the urls and the number of urls per sitemap.
	def generate_sitemaps(urls)

		nb_urls_current_sitemap = 0
		urls_current_sitemap = []
		nb_sitemaps_written = 0

		urls.each do |url|
		  # puts "gen with url " + url
      if ! url.index(@main_url).nil?
        urls_current_sitemap << url
        nb_urls_current_sitemap += 1
        
        if nb_urls_current_sitemap >= @nb_urls_per_sitemap
          nb_sitemaps_written += 1
          generate_sitemap(urls_current_sitemap, nb_sitemaps_written)
          urls_current_sitemap = []
          nb_urls_current_sitemap = 0
        end
      end
		end

		if nb_urls_current_sitemap > 0
			nb_sitemaps_written += 1
			generate_sitemap(urls_current_sitemap, nb_sitemaps_written)
		end
	end

	# main method.
	def run()
		@links = get_links(@main_url + "/")

		@good_links.add("#{@main_url}/")

		while next_not_visited(@links, @visited)
			l = next_not_visited(@links, @visited)

			new_links = get_links(l)
			# puts 'link: ' + l

			if new_links.length > 0
				@good_links.add(l)
				
				# puts 'in new links with ' + l
				
				if @view
					@view.new_link("#{l}")
				end
			end

			@visited.add(l)
			@links = @links.merge(new_links)
			sleep @idle_time.to_f
		end

		generate_sitemaps(@good_links)
	end

	private
	def contains_main_url(link)
		@main_urls.each do |main_url|
			if ! link.index(main_url).nil?
				return true
			end
		end

		return false
	end

	def get_content(u)
		if @without_wget
		  body = "dummy"
		  dummy = "url"
			url = URI.parse(u)
      # puts 'Try to fetch URL: ' + u
			req = Net::HTTP::Get.new(url.path)
			res = Net::HTTP.start(url.host, url.port) {|http|
			http.request(req)
			}
	   #  print res['Location'] + "\n"
      if res.response['Location']!=nil then
        # puts 'Got location: ' + res.response['Location']
        # puts '   with status code ' + res.code
        if res.code == "302"
          # puts 'temporarily redirection'
          redirectUrl=res.response['Location']
          result = get_content(redirectUrl)
        end
        if res.code == "303"
          # puts 'see other'  
          redirectUrl=res.response['Location']
          result = get_content(redirectUrl)
        end
      else
        # puts '   with status code ' + res.code
        if ! u.index(@main_url).nil?
          # puts 'found good one ' + u
          result = [u,res.body.downcase]
        else
          result = [dummy,body]
		    end
      end

			return result
		end

		`wget -O /tmp/out.html #{u}`
		res = `cat /tmp/out.html`
		result = [u,res]
    return result
	end

	def fix_link(link, current_url)

		# Case when href="some_dir/..." or /...
		if link.length > 0 && link[0, 7] != "http://" && link[0, 9] != "https://"
			uri = URI.parse(current_url)
			uri.merge!(link)
			return uri.to_s
		end

		return link
	end
end
