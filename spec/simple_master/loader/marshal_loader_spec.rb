# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe SimpleMaster::Loader::MarshalLoader do
  it "loads marshaled records for all tables" do
    Dir.mktmpdir do |dir|
      # dump current dataset to marshal files
      $current_dataset.tables.each do |klass, table|
        path = File.join(dir, "#{klass.table_name}.marshal")
        File.binwrite(path, Marshal.dump(table.all))
      end

      loader = described_class.new(path: dir)
      dataset = SimpleMaster::Storage::Dataset.new(loader: loader)
      dataset.load

      SimpleMaster.use_dataset(dataset) do
        expect(Weapon.find(1).name).to eq("Bronze Pistol")
        expect(Level.find(2).lv).to eq(2)
        expect(Enemy.find(2).name).to eq("Ogre Chief")
      end
    end
  end

  it "treats missing marshal files as empty record sets instead of raising" do
    Dir.mktmpdir do |dir|
      loader = described_class.new(path: dir)
      dataset = SimpleMaster::Storage::Dataset.new(loader: loader)

      expect { dataset.load }.not_to raise_error

      SimpleMaster.use_dataset(dataset) do
        expect(Weapon.all).to eq([])
        expect(Level.all).to eq([])
        expect(Enemy.all).to eq([])
      end
    end
  end
end
