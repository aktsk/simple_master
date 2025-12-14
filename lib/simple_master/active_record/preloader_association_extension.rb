# frozen_string_literal: true

module SimpleMaster
  module ActiveRecord
    module PreloaderAssociationExtension
      def run?
        super || klass < SimpleMaster::Master
      end
    end
  end
end
