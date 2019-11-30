# Custom Liquid filter to create hyperlinks
# {{ 'href' | link_to: 'input' }}
module Jekyll::CustomFilter
  def link_to(input, href)
    "<a href=\"#{href}\">#{input}</a>"
  end
end

Liquid::Template.register_filter(Jekyll::CustomFilter)
