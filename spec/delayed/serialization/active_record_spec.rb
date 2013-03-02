require 'helper'

describe ActiveRecord do
  it "loads classes with non-default primary key" do
    expect {
      YAML.load(Story.create.to_yaml)
    }.not_to raise_error
  end

  it "loads classes even if not in default scope" do
    expect {
      YAML.load(Story.create(:scoped => false).to_yaml)
    }.not_to raise_error
  end
end
