# Copyright (C) 2025 Martino Pilia

module Jekyll
  class TilesTagBlock < Liquid::Block
    def render(context)
      content = super
      %{<div class="tile-container">
            #{content}
        </div>
      }
    end
  end

  class TileTagBlock < Liquid::Block
    def initialize(tag_name, args, tokens)
      super
      args = args.split(',')
      @title = args[0]
      @link = args[1]
      @styleclass = args[2]
    end

    def render(context)
      site = context.registers[:site]
      converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
      content = converter.convert(super)

      if @link
        container_start = %{a href="#{@link}"}
        container_end = "a"
      else
        container_start = "div"
        container_end = "div"
      end

      classes = "tile"
      if @styleclass
        classes += " #{@styleclass}"
      end

      %{<!-- -->
        <#{container_start} class="#{classes}">
            <h3>#{@title}</h3>
            <p>#{content}</p>
        </#{container_end}>
      }
    end
  end
end

Liquid::Template.register_tag('tiles', Jekyll::TilesTagBlock)
Liquid::Template.register_tag('tile', Jekyll::TileTagBlock)

