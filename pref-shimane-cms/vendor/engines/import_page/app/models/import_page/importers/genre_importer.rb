module ImportPage::Importers
  class GenreImporter < self::Base

    def import
      messages.clear

      return nil unless validates_entry_files

      begin
        dirname = File.basename(path)
        unless new_genre = Genre.find_by_path(File.join(genre.path, dirname, '/'))
          new_genre = Genre.new(name: dirname,
                                title: dirname,
                                parent_id: genre.id,
                                section_id: section_id)
          if new_genre.save
            logger.debug "Create genre (#{new_genre.path})"

            job = Job.create(action: 'create_genre', arg1: new_genre.id.to_s)
            if job
              logger.debug "Create job. (#{job.inspect})"
            else
              logger.error "Faild to create job. (#{job.inspect})"
            end
          else
            messages << I18n.t(:invalid_genre, scope: self.class.i18n_message_scope)
            logger.error "Failed to create genre. (#{new_genre.inspect})"
            new_genre = nil
          end
        end
      rescue => e
        messages << I18n.t(:genre_not_imported, scope: self.class.i18n_message_scope)
        logger.error e.message
        logger.error "backtrace: #{e.backtrace}"
        new_genre = nil
      end
      new_genre
    end

    private

    # ディレクトリ内に HTMLファイル(.html, .html) が無いか検証
    def validates_entry_files
      entries = Dir[File.join(path, '**')]
      unless entries.any?{|e| File.file?(e) && (%r{\.(html|htm)$}i =~ e) }
        messages << I18n.t(:html_not_found, scope: self.class.i18n_message_scope)
        return false
      end
      true
    end
  end
end
