# frozen_string_literal: true

class ApplicationMaster < SimpleMaster::Master
  self.abstract_class = true

  def self.validate_all_records
    Thread.current[:errors] = {}

    classes = descendants.reject(&:abstract_class).select(&:base_class?)
    classes.each do |klass|
      klass.all.each(&:valid?)
    end

    Thread.current[:errors]
  ensure
    Thread.current[:errors] = {}
  end
end
