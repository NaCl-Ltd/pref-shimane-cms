require 'spec_helper'

describe Susanoo::Admin::PageTemplatesController do
  shared_context "rubi_filter" do
    context "content_type = 'text/html', cookie[:ruby] = 'on' の場合" do
      before do
        cookies[:ruby] = 'on'
      end

      it "ルビがふられたテキストが出力されること" do
        subject
        expect(response.body).to eq BrowsingSupport::RubiAdder.add(raw_text)
      end
    end

    context "content_type = 'text/html', cookie[:ruby] = nil の場合" do
      it "そのままのテキストが出力されること" do
        subject
        expect(response.body).to eq raw_text
      end
    end

    context "content_type = 'text/plain', cookie[:ruby] = 'on' の場合" do
      let(:content_type) { 'text/plain' }

      before do
        cookies[:ruby] = 'on'
      end

      it "そのままのテキストが出力されること" do
        subject
        expect(response.body).to eq raw_text
      end
    end
  end

  describe "フィルタ" do
    describe "rubi_filter" do
      let(:content_type) { nil }
      let(:raw_text) { "太郎はこの本を二郎を見た女性に渡した。" }
      let(:login_user) { create(:user, password: 'password') }
      let!(:page_template) { create(:page_template) }

      controller(Susanoo::Admin::PageTemplatesController) do
        attr_accessor :example

        %i(preview).each do |act|
          define_method(act) do
            render text: example.raw_text, content_type: example.content_type
          end
        end
      end

      before do
        controller.example = self
        routes.draw do
          get "preview" => "anonymous#preview"
        end

        login(login_user)
      end

      describe "GET preview" do
        include_context "rubi_filter"

        let!(:page_content) { create(:page_content_editing) }

        subject { get :preview, id: page_template.id }
      end
    end
  end
end
