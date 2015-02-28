###
# Compass
###

now = Time.now.utc.to_date
age = now.year - 1989 - ((now.month > 3 || (now.month == 3 && now.day >= 21)) ? 0 : 1)
page "/" do
	@age = age
end

# Change Compass configuration
compass_config do |config|
  config.output_style = :compact
end

activate :blog do |blog|
	# set options on blog
	blog.prefix = "read"
  # blog.sources = "/read/{title}"
	blog.permalink = "{title}"
	blog.layout = "article"
	blog.paginate = true
	blog.per_page = 15
  blog.tag_template = "tags.html"
  blog.taglink = "/categories/{tag}"
end

activate :syntax, line_numbers: true

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true
set :frontmatter_extensions, %w(.html .slim)

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

set :url_root, 'http://fullstackstanley.com'

activate :search_engine_sitemap

activate :ogp do |ogp|
  #
  # register namespace with default options
  #
  ogp.namespaces = {
    og: data.ogp.og
    # from data/ogp/og.yml
  }
  ogp.base_url = 'http://fullstackstanley.com/'
  ogp.blog = true
end

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  activate :asset_hash

  # Use relative URLs
  activate :relative_assets


  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end
