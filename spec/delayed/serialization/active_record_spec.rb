# frozen_string_literal: true

require "helper"

describe ActiveRecord do
  it "loads classes with non-default primary key" do
    expect do
      YAML.load_dj(Story.create.to_yaml)
    end.not_to raise_error
  end

  it "loads classes even if not in default scope" do
    expect do
      YAML.load_dj(Story.create(scoped: false).to_yaml)
    end.not_to raise_error
  end
end
