require 'rmagick'
include Magick

module Jekyll
  class GenerateThumbnails < Generator
    safe true
    priority :low

    # Fixed values
    Thumbnails_dir = "thumbnails"

    # Default configuration values
    Thumbnail_gallery = { 'width' => 300, 'height' => 300 }

    attr_accessor :thumbnail_gallery

    def generate(site)
        get_parameters! site
        site.collections.first.last.docs.each do |post|
            puts("Processing images for '#{post.data["title"]}'")
            asset_dir = post.data['image_folder'];
            if not File.exists? asset_dir
                raise "Asset directory '#{asset_dir}' not found."
            end

            thumbnails_dir = "#{asset_dir}/#{Thumbnails_dir}"
            Dir.mkdir thumbnails_dir if not File.exists? thumbnails_dir

            new_files = []
            new_files.concat generate_gallery_thumbnails(site, post, asset_dir)

            # reader = StaticFileReader.new(site, thumbnails_dir)
            # site.static_files.concat(reader.read(new_files))
        end
    end

    def get_parameters!(site)
        @thumbnail_gallery = site.config['thumbnail_gallery'] || Thumbnail_gallery
    end

    def generate_gallery_thumbnails(site, post, asset_dir)
        gallery = post.data['images']
        return [] if not gallery

        new_thumbnails = gallery.map do |item|
            image_file = "#{asset_dir}/#{item['filename']}"
            thumbnail_file = "#{asset_dir}/#{Thumbnails_dir}/#{item['filename']}"
            preexisting = File.exists? thumbnail_file
            next nil if preexisting
            image = Image.read(image_file)[0]

            puts(image_file)
            next nil if not thumbnail_needed?(image_file, thumbnail_file, @thumbnail_gallery)

            save_thumbnail image, thumbnail_file, @thumbnail_gallery
            image.destroy!
            next nil if preexisting
            item['filename']
        end

        return new_thumbnails == nil ? [] : new_thumbnails.compact
    end

    def save_thumbnail(image, file, size)
        image.resize_to_fit! size['width'], size['height']
        image.write file
    end

    def thumbnail_needed?(image_file, thumbnail_file, size)
        # No thumbnail yet?
        return true if not File.exists? thumbnail_file
        # Image has changed?
        return true if File.mtime(thumbnail_file) < File.mtime(image_file)

        # Need to resize?
        metadata = (Image.ping thumbnail_file)[0]
        existing_size = {
            'width' => metadata.columns,
            'height' => metadata.rows
        }

        return false if (
            size['width'] == existing_size['width'] and
            size['height'] >= existing_size['height']
        )
        return false if
            size['height'] == existing_size['height'] and
            size['width'] >= existing_size['width']

        true
    end
  end
end
