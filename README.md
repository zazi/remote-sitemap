Remote Sitemap Generator
========================

About
-----

This version of the Remote Sitemap Generator is based on the [Remote Sitemap Generator v 0.5](http://sourceforge.net/projects/rsitemapgen/) from [Martin Levesque](http://sourceforge.net/users/martinlev).

General Usage
-------------

	ruby exec-sitemap-gen.rb -u <URL> 
		[-n nb_per_sitemap] 
		[-p prefix_sitemap_filenames] 
		[-i idle_time (timeout between requests)] 
		[--without_wget true|false] 
		[--verbose true|false]
		
Parameter Description
---------------------

	-u/--url URL 				Main URL to scan e.g., http://smiy.sourceforge.net
	-n/--nb NB_URLS				Number of  URLs per sitemap e.g., 100, default = 50000
	-p/--prefix Prefix			Prefix of the sitemap filenames e.g., my_sitemap_, default = sitemap_
	-i/--idle_time Timeout			Time between requests (in seconds) e.g., 1, default = 2
	--without_wget true|false		Use internal mode for URI derefencing or the wget command e.g., true, default = false
	--verbose true|false			Verbose on or off e.g., true, default = false

Remote Sitemap Generator version information
--------------------------------------------

* <b>v 0.5</b>:
	* Author: Martin Levesque
	* Date: June 12th 2010
	* See also: http://sourceforge.net/projects/rsitemapgen/
	* Usage example: `ruby exec-sitemap-gen.rb -u http://smiy.sourceforge.net`
		
* <b>v 0.6</b>:
	* Author: Martin Levesque, Bo Ferri
	* Date: December 22nd 2010
	* See also: https://github.com/zazi/remote-sitemap/
	* Additional features: 
		* added purl.org (a PURL server) to the main URLs array
		* handle redirections internally to get the real location URL
		* stores only sitemap descriptions that are part of the main URL namespace (given by the value of the parameter -u/--url)
		* stripes down the fragment IDs of URIRefs to boost a bit the crawling process (all URIs are added without fragment ID)
	* Usage example: 
		* `ruby exec-sitemap-gen.rb -u http://smiy.sourceforge.net --without_wget true --verbose true`
		* please it is important here to use the internal URI derefencing mechanism here to get the real location URL
	* Note: you can add further main URLs in the main URLs array (@main_urls) in sitemap-gen.rb
	* TODO: 
		* parametrize the inclusion of further main URLs
		* calculate a priority value (currently this is statically set to 1.0)
