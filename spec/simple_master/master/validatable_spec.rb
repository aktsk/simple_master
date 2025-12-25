# frozen_string_literal: true

require "spec_helper"

RSpec.describe SimpleMaster::Master::Validatable do
  it "validates all master records" do
    errors = ApplicationMaster.validate_all_records
    expect(errors).to be_empty
  end
end
