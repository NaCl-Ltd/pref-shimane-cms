# -*- coding: utf-8 -*-

require 'RMagick'

module Paperclip
  class ImageResizerClassic < Processor

    attr_accessor :filesize, :quality, :pivot_geometry, :trials

    def initialize(file, options = {}, attachment = nil)
      super
      @extname = File.extname(file.path)
      @basename = File.basename(file.path, @extname)
      @filesize = options[:filesize]
      @quality = options[:quality]
      @pivot_geometry = ::Paperclip::Geometry.parse(options[:pivot_geometry])
      @trials = options[:trials].to_i
    end

    def make
      to_filesize = filesize
      to_quality  = quality
      to_width, to_height = @pivot_geometry.width, @pivot_geometry.height

      if file.size > to_filesize
        orig_image = ::Magick::Image.from_blob(file.read).first
        to_quality = orig_image.quality if orig_image.quality < to_quality

        # resize to 400x266
        if orig_image.columns > to_width || orig_image.rows > to_height
          clown = orig_image.resize_to_fit(to_width, to_height)
          clown.to_blob  # apply resize
        end
        clown.to_blob{self.quality = to_quality} if clown.filesize > to_filesize

        # resize less 400x266
        if clown.filesize > to_filesize
          comp_rate = clown.columns.to_f / clown.base_columns.to_f
          cnt = 0
          while clown.filesize > to_filesize && cnt < trials
            comp_rate = comp_rate * Math.sqrt(to_filesize.to_f / clown.filesize.to_f)
            break if (clown.rows * comp_rate) < 1.0 || (clown.columns * comp_rate) < 1.0

            clown = orig_image.resize(comp_rate)
            clown.to_blob{self.quality = to_quality}  # apply resize
            cnt += 1
          end
        end
        dst = Tempfile.new([ @basename, @extname ])
        dst.write(clown.to_blob.force_encoding("utf-8"))
        dst.close; dst.open
        dst
      else
        file
      end
    end
  end
end
