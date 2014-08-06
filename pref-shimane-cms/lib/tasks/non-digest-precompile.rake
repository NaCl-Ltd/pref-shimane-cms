#
# assets:precompileしたファイルのdigest値を削除するタスク
#
namespace :assets do
  task non_digested: :environment do
    assets = Dir.glob(File.join(Rails.root, 'public/assets/**/*'))
    regex = /(-{1}[a-z0-9]{32}*\.{1}){1}/
    assets.each do |file|
      next if File.directory?(file) || file !~ regex
      source = file.split('/')
      source.push(source.pop.gsub(regex, '.'))
      non_digested = File.join(source)
      FileUtils.cp(file, non_digested)
      FileUtils.rm(file)
    end
  end
end
