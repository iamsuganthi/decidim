# frozen_string_literal: true

require "spec_helper"

describe "Verification modes" do
  describe ".authorization_handlers", with_authorization_handlers: ["Decidim::DummyAuthorizationHandler"] do
    it "returns an array of authorization handlers" do
      expect(Decidim.authorization_handlers).to eq(["Decidim::DummyAuthorizationHandler"])
    end
  end

  describe ".authorization_workflows", with_authorization_workflows: ["dummy_authorization_workflow"] do
    it "returns an array of workflow manifests" do
      auth_workflows = Decidim.authorization_workflows

      expect(auth_workflows.map(&:name)).to eq(["dummy_authorization_workflow"])
    end
  end

  describe ".authorization_methods", with_authorization_handlers: ["Decidim::DummyAuthorizationHandler"],
                                     with_authorization_workflows: ["dummy_authorization_workflow"] do
    it "returns an array of decorated authorization methods" do
      auth_methods = Decidim.authorization_methods

      expect(auth_methods.map(&:name)).to eq(%w(Decidim::DummyAuthorizationHandler dummy_authorization_workflow))
      expect(auth_methods.map(&:type)).to eq(%w(direct multistep))
    end
  end
end
