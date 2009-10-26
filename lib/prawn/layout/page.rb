# encoding: utf-8

# layout/page.rb : Provides helpers for page layout
#
# Copyright January 2009, Gregory Brown. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  class Document
    # A LazyBoundingBox is simply a BoundingBox with an action tied to it to be
    # executed later.  The lazy_bounding_box method takes the same arguments as
    # bounding_box, but returns a LazyBoundingBox object instead of executing
    # the code block directly.
    #
    # You can then call LazyBoundingBox#draw at any time (or multiple times if
    # you wish), and the contents of the block will then be run. This can be
    # useful for assembling repeating page elements or reusable components.
    #
    #  file = "lazy_bounding_boxes.pdf"
    #  Prawn::Document.generate(file, :skip_page_creation => true) do
    #    point = [bounds.right-50, bounds.bottom + 25]
    #    page_counter = lazy_bounding_box(point, :width => 50) do
    #      text "Page: #{page_count}"
    #    end
    #
    #    10.times do
    #     start_new_page
    #      text "Some text"
    #      page_counter.draw
    #    end
    #  end
    #
    def lazy_bounding_box(*args,&block)
      translate!(args[0])
      box = LazyBoundingBox.new(self,*args)
      box.action(&block)
      return box
    end

    # A bounding box with the same dimensions of its parents, minus a margin
    # on all sides
    #
    def padded_box(margin, &block)
      bounding_box [bounds.left + margin, bounds.top - margin],
        :width  => bounds.width - (margin * 2),
        :height => bounds.height - (margin * 2), &block
    end

    # A header is a LazyBoundingBox drawn relative to the margins that can be
    # repeated on every page of the document.
    #
    # Unless <tt>:width</tt> or <tt>:height</tt> are specified, the margin_box
    # width and height are used.
    #
    #   header margin_box.top_left do
    #    text "Here's My Fancy Header", :size => 25, :align => :center
    #    stroke_horizontal_rule
    #  end
    #
    def header(top_left,options={},&block)
      @header = repeating_page_element(top_left,options,&block)
    end

    # A footer is a LazyBoundingBox drawn relative to the margins that can be
    # repeated on every page of the document.
    #
    # Unless <tt>:width</tt> or <tt>:height</tt> are specified, the margin_box
    # width and height are used.
    #
    #   footer [margin_box.left, margin_box.bottom + 25] do
    #     stroke_horizontal_rule
    #     text "And here's a sexy footer", :size => 16
    #   end
    #
    def footer(top_left,options={},&block)
      @footer = repeating_page_element(top_left,options,&block)
    end

    private

    def repeating_page_element(top_left,options={},&block)
      r = LazyBoundingBox.new(self, translate(top_left),
        :width  => options[:width]  || margin_box.width,
        :height => options[:height] || margin_box.height )
      r.action(&block)
      return r
    end

    class LazyBoundingBox < BoundingBox

      # Defines the block to be executed by LazyBoundingBox#draw.
      # Usually, this will be used via a higher level interface.
      # See the documentation for Document#lazy_bounding_box, Document#header,
      # and Document#footer
      #
      def action(&block)
        @action = block
      end

      # Sets Document#bounds to use the LazyBoundingBox for its bounds,
      # runs the block specified by LazyBoundingBox#action,
      # and then restores the original bounds of the document.
      #
      def draw
        @parent.mask(:y) do
          parent_box = @parent.bounds
          @parent.bounds = self
          @parent.y = absolute_top
          @action.call
          @parent.bounds = parent_box
        end
      end
    end
  end
end
