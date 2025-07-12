# Copyright (C) 2025 Martino Pilia

module Jekyll
  class TimelineTagBlock < Liquid::Block
    def initialize(tag_name, categories, tokens)
      super
      require 'yaml'
      @config = YAML.load(categories)
    end

    def render(context)
      content = super
      id = @config['id']
      categories = @config['categories']

      %{<style>
        #{categories.reduce("") {|result, (key, opts)| result + %{
          ##{id} #tl-check-#{key}:checked ~ .tl-filters > .tl-filter.tl-#{key} {
              opacity: 0.3;
          }

          ##{id} #tl-check-#{key}:checked ~ .tl-events > .tl-event.tl-#{key} {
              opacity: 0;
              height: 0;
          }

          ##{id} .tl-#{key}.tl-marker {
              background-color: #{opts['color']};
          }

          ##{id} .tl-#{key} .tl-marker-icon {
              background-image: url("#{opts['icon']}");
          }

          ##{id} .tl-event.tl-#{key} .tl-event-content .tl-event-content-box {
              border-color: #{opts['color']};
          }
        }}}
        </style><div id="#{id}" class="tl-timeline">
          #{categories.reduce("") {|result, (key, opts)|
            result + %{
              <input type="checkbox" id="tl-check-#{key}" class="tl-check"/>
            }
          }}
          <div class="tl-filters">
            #{categories.reduce("") {|result, (key, opts)|
              result + %{
                <label for="tl-check-#{key}" class="tl-filter tl-#{key} tl-marker"><span class="tl-marker-icon"></span></label>
              }
            }}
          </div>
          <div class="tl-events">
            #{content}
          </div>
        </div>
      }
    end
  end

  class EventTagBlock < Liquid::Block
    def initialize(tag_name, args, tokens)
      super
      args = args.split(',')
      @event_type = args[0]
      @date = args[1]
    end

    def render(context)
      site = context.registers[:site]
      converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
      content = converter.convert(super)

      %{<div class="tl-event tl-#{@event_type}">
          <span class="tl-marker tl-#{@event_type}"><span class="tl-marker-icon"></span></span>
          <div class="tl-event-content">
            <div class="tl-event-content-box">
              <time>#{@date}</time>
              <div class="tl-event-text">
                #{content}
              </div>
            </div>
          </div>
        </div>
      }
    end
  end
end

Liquid::Template.register_tag('timeline', Jekyll::TimelineTagBlock)
Liquid::Template.register_tag('event', Jekyll::EventTagBlock)
