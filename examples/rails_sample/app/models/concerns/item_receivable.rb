# frozen_string_literal: true

module ItemReceivable
  extend ActiveSupport::Concern

  class_methods do
    def max_quantity
      nil
    end
  end

  included do
    cache_class_method def self.receivable_sources
      sources = {}
      Reward.all.each do |reward|
        reward_item = reward.reward

        klass = reward_item.class
        while klass <= self
          array = sources.fetch(reward_item.id) { sources[reward_item.id] = [] }
          array << reward.enemy

          klass = klass.superclass
        end
      end

      sources.each_value do |array|
        array.uniq!
        array.freeze
      end

      sources
    end

    # This is an example. `self.class.receivable_sources[id]` may work better here.
    cache_method def receivable_sources
      self.class.receivable_sources.fetch(id) { [] }
    end
  end

  def self.receivable_item?
    true
  end
end
