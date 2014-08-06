#
# rake assets:precompile 時に ckeditor用全assetsファイルのdigest値を
# 付加せずに作成するタスク
#
# @see https://github.com/tsechingho/ckeditor-rails/blob/master/lib/ckeditor-rails/tasks.rake
#
require 'fileutils'

desc "Create nondigest versions of all ckeditor digest assets"
task "assets:precompile" do
  fingerprint = /\-[0-9a-f]{32}\./
  for file in Dir["public/assets/ckeditor/**/*"]
    next unless file =~ fingerprint
    nondigest = file.sub fingerprint, '.'

    basename = File.basename(nondigest)
    if basename == 'ckeditor.js' or basename == 'ckeditor.js.gz'
      FileUtils.rm file, verbose: true if File.exist?(file)
      FileUtils.rm nondigest, verbose: true if File.exist?(nondigest)
    else
      if !File.exist?(nondigest) or File.mtime(file) > File.mtime(nondigest)
        FileUtils.cp file, nondigest, verbose: true
      end
    end
  end

  ck_org  = Rails.root.join('vendor', 'assets', 'javascripts', 'ckeditor', 'ckeditor.js')
  ck_dest = Rails.root.join('public', 'assets', 'ckeditor', 'ckeditor.js')
  FileUtils.cp ck_org, ck_dest, verbose: true
end
