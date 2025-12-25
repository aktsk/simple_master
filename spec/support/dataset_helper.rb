# frozen_string_literal: true

module DatasetHelper
  def build_dataset(loader: JsonLoader.new, diff: nil)
    dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
    dataset.diff = diff if diff
    # dataset.load
    dataset
  end

  def with_dataset(loader: JsonLoader.new, diff: nil)
    dataset = build_dataset(loader: loader, diff: diff)
    SimpleMaster.use_dataset(dataset) do
      yield dataset
    end
  end

  def reset_active_record_tables
    PlayerItem.delete_all
    Player.delete_all
  end
end

RSpec.configure do |config|
  config.include DatasetHelper
end
