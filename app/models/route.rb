class Route < ApplicationRecord

  %i(origin destination).each do |field|
    %i(lat lon).each_with_index do |suffix, i|
      define_method("#{field}_#{suffix}") { self.send(field).to_s.split(':')[i] }
    end
  end

end
