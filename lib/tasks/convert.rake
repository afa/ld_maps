namespace :convert do
  desc "TODO"
  task msk: :environment do
    Dir['saved/500/msk/*.map'].each do |fname|
      `gdalwarp -r bilinear #{fname} #{File.dirname(fname)}/#{File.basename(fname, '.map')}.tiff`
    end
  end

end
