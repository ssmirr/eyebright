namespace :eyebright do
  namespace :info_cache do
    desc 'completely flush the info cache from memory'
    task :flush => :environment do
      MDC.flush
    end
  end
end
